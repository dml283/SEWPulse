/*
    Type:       Controller Extension
    Purpose:    Controls the Payment History VF page

    Used By:    PaymentHistory
    ---------------------------------------------------------------
    History:

    16-Aug-2011 L.Tan (Coretec Solutions)    Created
*/
public with sharing class PaymentHistoryExCon {

    public Billing_Account__c billingAcc {get; set;}
    public List<WSUtil_Billing.PaymentDetails> payments {get;set;} 
    public Integer paymentNum{
    	get{
    		paymentNum = 0;
    		if(!payments.isEmpty())
    			paymentNum = payments.size();
    		return paymentNum;	
    	}
    	set;
    }
    
    public PaymentHistoryExCon(ApexPages.StandardController stdController) {
        
        billingAcc = (Billing_Account__c)stdController.getRecord();
        
        try {
            // Get Payment History
            WSUtil_Billing ws = new WSUtil_Billing();
            ws.getPaymentHistory(billingAcc.HiAF_Account_Number__c);        
            payments = ws.payments; 

        }catch(System.CalloutException ex){     // SOAP Error
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
    }
    
    /* Test Method */
    public static testmethod void test_PaymentHistoryExCon(){
        Account acc = new Account(name='test parent');
        insert acc;
        
        Billing_Account__c ba = new Billing_Account__c(name='test', customer__c=acc.Id, HiAF_Account_Number__c='1234');
        insert ba;
        
        test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(ba);
        PaymentHistoryExCon excon = new PaymentHistoryExCon(sc);
        System.assertEquals(excon.billingAcc.HiAF_Account_Number__c, '1234');
        if (excon.payments!=null) {
            System.assert(excon.payments.size() > 0);
            System.assert(excon.paymentNum > 0);
        }
        
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
        PaymentHistoryExCon excon1 = new PaymentHistoryExCon(sc);
        System.assertEquals(true, ApexPages.hasMessages());
        
        TibcoPaymentHistory_MessageTypes.Billing_element be = new  TibcoPaymentHistory_MessageTypes.Billing_element();
        TibcoPaymentHistory_MessageTypes.ProcessInputData_element pid = new TibcoPaymentHistory_MessageTypes.ProcessInputData_element();
        
        test.stopTest();        
    }   
}