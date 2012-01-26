/*
    Type:       Controller Extension
    Purpose:    Controls the Bill History VF page

    Used By:    BillHistory
    ---------------------------------------------------------------
    History:

    16-Aug-2011 L.Tan (Coretec Solutions)   Created
    16-Nov-2011 M.Watson (Salesforce)       Added print functionality

*/
public with sharing virtual class BillHistoryExCon {

    public Billing_Account__c billingAcc {get; set;}
    public List<WSUtil_Billing.BillDetails> bills {get;set;} 
    public Integer billNum{get;set;}
    public List<WSUtil_Billing.BillLineDetails> billLines {get; set;}
    public String currentBillNumber {get;set;}              
    map<String, List<WSUtil_Billing.BillLineDetails>> bLMap = new map<String, List<WSUtil_Billing.BillLineDetails>>();
    public String selectedPrintOption {get;set;}
    public static final Integer MAX_SELECTABLE = 9;
                        
    public BillHistoryExCon(){
   
    }
    
    public BillHistoryExCon(ApexPages.StandardController stdController) {

        billingAcc = (Billing_Account__c)stdController.getRecord();
                                
        try {
            // Get Bill History
            if (billingAcc != null && billingAcc.HiAF_Account_Number__c != null &&
            								billingAcc.HiAF_Account_Number__c != '') {	
	            WSUtil_Billing ws = new WSUtil_Billing();                        
	            ws.getBillHistory(billingAcc.HiAF_Account_Number__c);
	            bills = ws.bills;
	            bLMap = ws.bLinesMap; 
	            billNum = bills.size(); 
            }
        }catch(System.CalloutException ex){     // SOAP Error
            ApexPages.addmessage(
                new ApexPages.message(ApexPages.severity.ERROR,'Problem with web service - please contact system administrator. Error message:'+ex.getMessage())
            );
                
        } catch (WSUtil.MultipleWebServiceBusinessException e) {    // Error return from webservice - Business level
            for (WSUtil.SingleWebServiceBusinessException err: e.multiEx) {
                ApexPages.addmessage(
                    new ApexPages.message(ApexPages.severity.ERROR,err.getMessageByUserType())
                );
            }
        }
    }
        
    public void refreshBillLines() {
        // get bill lines from map
        billLines = bLMap.get(currentBillNumber);
    }

    /* Print Selected Bills */
    public PageReference printBill() {
        Boolean printBillResult = false;
        String billNumbers = '';
        Integer numberSelected = 0;
        
        /* Loop through each bill, count selected bills & record their Bill Number */
        for(WSUtil_Billing.BillDetails bill : bills) {
            if(bill.selected) {
                numberSelected++;
                if(billNumbers == '') {
                    billNumbers = bill.BillNumber;
                }
                else billNumbers = billNumbers + ',' + bill.BillNumber; 
            }
        }
        /* Error if no bill has been selected */
        if(numberSelected == 0) {
                ApexPages.addmessage(
                new ApexPages.message(ApexPages.severity.ERROR,'Please select at least one bill to print')
                );
                return null;                    
        }
        /* Error if too many bills are selected (beyond interface max limit) */
        else if(numberSelected > MAX_SELECTABLE) {
                ApexPages.addmessage(
                new ApexPages.message(ApexPages.severity.ERROR,'You can only print 9 bills at one time')
                );          
                return null;        
        }
        /* Else call the 'Print Bill' web service */
        else {
            try {
                // Print Bill
                WSUtil_Billing ws = new WSUtil_Billing();                        
                printBillResult = ws.printBill(billingAcc.HiAF_Account_Number__c, billNumbers, selectedPrintOption);
    
            }
            catch(System.CalloutException ex){     // SOAP Error
                ApexPages.addmessage(
                    new ApexPages.message(ApexPages.severity.ERROR,'Problem with web service - please contact system administrator. Error message:'+ex.getMessage())
                );
                    
            } catch (WSUtil.MultipleWebServiceBusinessException e) {    // Error return from webservice - Business level
                for (WSUtil.SingleWebServiceBusinessException err: e.multiEx) {
                    ApexPages.addmessage(
                        new ApexPages.message(ApexPages.severity.ERROR,err.getMessage())
                    );
                }
            }
            if(printBillResult) {
                ApexPages.addmessage(
                new ApexPages.message(ApexPages.severity.INFO,'Bill(s) successfully printed')
                );
                createTask(billNumbers);                
            }
        }           
        return null;
    }

    public Boolean createTask(String billNumbers) {
        Task taskRec = new Task();
        Id taskId;
        Id recordTypeId = [SELECT name FROM RecordType WHERE name = 'Read Only Tasks' LIMIT 1].Id;
        
        taskRec.Subject = 'Print Bill';
        taskRec.ActivityDate = date.today();
        taskRec.Complete_Date__c = date.today();
        taskRec.Type = 'Other';
        taskRec.RecordTypeId = recordTypeId;
        taskRec.Description = 'Printed bill(s) ' + billNumbers + ' with print option ' + selectedPrintOption;
        taskRec.WhatId = billingAcc.Id; 
        taskRec.Status = 'Completed';
        taskRec.Group__c = 'Billing & Accounts';
        taskRec.Category_Level_1__c = 'Billing';
        taskRec.Category_Level_2__c = 'Billing';
        taskRec.Category_Level_3__c = 'Print Bill';
        taskRec.Mode__c = 'Action';

        if(!'Standard'.equals(UserInfo.getUserType())){
            taskRec.ownerId = PortalSettings__c.getInstance().Portal_Task_Default_User__c;
        }
        
        try {
            upsert taskRec;
            taskId = taskRec.Id;
            return true;            
        }
        catch (DmlException e) {
            ApexPages.addMessage(
            new ApexPages.message(ApexPages.severity.ERROR, 'Task creation failed')
            );
            return false;
        }
    }




    /* Test Method */
    public static testmethod void test_BillHistoryExCon(){
        Account acc = new Account(name='test parent');
        insert acc;
        
        Billing_Account__c ba = new Billing_Account__c(name='test', customer__c=acc.Id, HiAF_Account_Number__c='1234');
        insert ba;
        
        test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(ba);
        BillHistoryExCon excon = new BillHistoryExCon(sc);
        excon.currentBillNumber = '1234';
        excon.refreshBillLines();
        System.assertEquals(excon.billingAcc.HiAF_Account_Number__c, '1234');
        System.assert(excon.bills.size() > 0);
        System.assert(excon.billNum > 0);
        
        /* Print with no bills selected (error) */
        excon.printBill();
        System.assertEquals(true, ApexPages.hasMessages()); 
        /* Print with 2 bills selected (ok) */
        excon.bills[0].selected = true;
        excon.bills[1].selected = true;
        excon.printBill();
        System.assertEquals(true, ApexPages.hasMessages()); 
        /* Print with all 10 bills selected (error) */
        for(WSUtil_Billing.BillDetails bill : excon.bills) {
            bill.selected = true;
        }
        excon.printBill();
        System.assertEquals(true, ApexPages.hasMessages()); 
        
        // get custom settings, update if already there
        SystemSettings__c cs ;
        try {
	        cs = [select id, setupOwnerId, Disable_Web_Services__c from SystemSettings__c limit 1];
        } catch (QueryException e) {
        	cs = new SystemSettings__c();
        	insert cs;
        }
        cs.Disable_Web_Services__c = true;
        update cs;                      
        BillHistoryExCon excon1 = new BillHistoryExCon(sc);
        System.assertEquals(true, ApexPages.hasMessages());
        
        test.stopTest();         
        
        TibcoBillHistory_MessageTypes.Billing_element be = new TibcoBillHistory_MessageTypes.Billing_element();
        TibcoBillHistory_MessageTypes.ProcessInputData_element  pid = new TibcoBillHistory_MessageTypes.ProcessInputData_element();
        
    }   
}