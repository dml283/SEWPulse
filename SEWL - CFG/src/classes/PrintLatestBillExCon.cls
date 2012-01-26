/*
    Type:       Controller Extension
    Purpose:    Controls the Print Latest Bill VF page 
                (extends BillHistoryExCon to re-use print functionality)

    Used By:    PrintLatestBill
    ---------------------------------------------------------------
    History:

    22-Nov-2011 M.Watson (Salesforce)       Created

*/

public with sharing class PrintLatestBillExCon extends BillHistoryExCon {

    public PrintLatestBillExCon(ApexPages.StandardController stdController) {
        billingAcc = (Billing_Account__c)stdController.getRecord();
        
        if(billingAcc.Last_Bill_Number__c == '' || billingAcc.Last_Bill_Number__c == null) {
                ApexPages.addmessage(
                new ApexPages.message(ApexPages.severity.ERROR,'Last Bill Number is blank')
                );              
        }       
    }
    
    /* Print Latest Bill */
    public PageReference printSingleBill() {
        Boolean printBillResult = false;
        
        /* Error if there is no Last Bill Number */
        if(billingAcc.Last_Bill_Number__c == '' || billingAcc.Last_Bill_Number__c == null) {
                ApexPages.addmessage(
                new ApexPages.message(ApexPages.severity.ERROR,'Last Bill Number is blank')
                );
                return null;                    
        }
        /* Else call the 'Print Bill' web service */
        else {
            try {
                // Print Bill
                WSUtil_Billing ws = new WSUtil_Billing();                        
                printBillResult = ws.printBill(billingAcc.HiAF_Account_Number__c, billingAcc.Last_Bill_Number__c, selectedPrintOption);
                system.debug('junk');
                system.debug(printBillResult);
    
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
                new ApexPages.message(ApexPages.severity.INFO,'Bill successfully printed')
                );
                // Create Activity (Task) - calling parent controller method
                createTask(billingAcc.Last_Bill_Number__c);             
            }
        }           
        return null;
    }    

    /* Test Method */
    public static testmethod void test_PrintLatestBillExCon(){
        Account acc = new Account(name='test parent');
        insert acc;
        
        Billing_Account__c ba = new Billing_Account__c(name='test', customer__c=acc.Id, HiAF_Account_Number__c='1234');
        insert ba;

        ApexPages.StandardController sc = new ApexPages.StandardController(ba);
     
        test.startTest();
        PrintLatestBillExCon excon = new PrintLatestBillExCon(sc);
        excon.billingAcc.Last_Bill_Number__c = '';
        excon.currentBillNumber = '1234';
        System.assertEquals(excon.billingAcc.HiAF_Account_Number__c, '1234');
        
        /* Attempt to print latest bill with blank Last Bill Number */
        excon.printSingleBill();
        System.assertEquals(true, ApexPages.hasMessages()); 
        
        /* Set Last Bill Number and print latest bill */
        excon.billingAcc.Last_Bill_Number__c = '1234';
        excon.printSingleBill();
        System.assertEquals(true, ApexPages.hasMessages()); 
        
        // get custom settings, update if already there
        SystemSettings__c cs;
        try {
	        cs = [select id, setupOwnerId, Disable_Web_Services__c from SystemSettings__c limit 1];
        } catch (QueryException e) {
        	cs = new SystemSettings__c();
        	insert cs;
        }

        cs.Disable_Web_Services__c = true;
        update cs;                      

        PrintLatestBillExCon excon1 = new PrintLatestBillExCon(sc);
        System.assertEquals(true, ApexPages.hasMessages());
        
        TibcoBillPrint_MessageType.ErrorStatus_element ese = new TibcoBillPrint_MessageType.ErrorStatus_element();
        
        test.stopTest();        
    }

 
}