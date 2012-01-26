/*
    Type:       Web Service Utility
    Purpose:    Functionalities for Billing Account Payment

    Used By:    CreditCardPayment and DirectDebit controller
    ---------------------------------------------------------------
    History:

    05-Dec-2011 Ji Zhang (Coretec Solutions)    Created

*/
public with sharing class WSUtil_Payment extends WSUtil{
    
    public class PaymentDetails {
        public String TaskID {get;set;}
        public String TransactionType {get;set;}
        public String BillingAccountNumber {get;set;}
        public String PaymentAmount {get;set;}
        public String TransactionRef {get;set;}
        
        public String CardNumber {get;set;}
        public String CardExpiryMonth {get;set;}
        public String CardExpiryYear {get;set;}
        public String CVN {get;set;}
        public String CardHolderName {get;set;}
    }
    
    public class RegisterDeregesterCustomer {
        
        //Register_DeregisterCustomer_element
        public String TaskID {get;set;}
        public String Action {get;set;}
        public String BillingAccountNumber {get;set;}
        public boolean InclBalanceFlag {get;set;}
        public Date DDStartDate {get;set;}
        public boolean DDBudgetFlag {get;set;}
        
        //Customer_element Customer;
        public String FirstName {get;set;}
        public String LastName {get;set;}
        
        //CreditCardDetails_element
        public String CardNumber {get;set;}
        public String CardExpiryMonth {get;set;}
        public String CardExpiryYear {get;set;}
        public String CVN {get;set;}
        public String CardHolderName {get;set;}
        
        //DirectDebit_element
        public String AccountNumber {get;set;}
        public String AccountTitle {get;set;}
        public String AccountBSB {get;set;}
        public String BankName {get;set;}
        public String BankState {get;set;}
        public String BankSuburb {get;set;} 
        
        
    }
    
    // 
    public String getStatus(){
       
        TIBCOPaymentGateway_Service.PaymentGatewayEndpoint stub = new  TIBCOPaymentGateway_Service.PaymentGatewayEndpoint();
        // populate header info
        TIBCOPaymentGateway_MessageTypes.Header_element header = new TIBCOPaymentGateway_MessageTypes.Header_element();

        if (SystemSettings__c.getInstance().BRE_Debug_User__c == null)
            header.UserID = Userinfo.getUserName();
        else
            header.UserID = SystemSettings__c.getInstance().BRE_Debug_User__c;
            
        header.UserType = UserInfo.getUserType();
        header.MessageTimeStamp = datetime.now();
        
        stub.timeout_x = 60000;
        
        TIBCOPaymentGateway_MessageTypes.getStatusResponse_PaymentGateway_element response = stub.getStatus(header);
        
        if (Boolean.valueOf(response.header.MessageResponseStatus.MessageSuccessInd)) { //webservice success
            if (response != null) {
                return response.PaymentGatewayStatus;
            } 
        }else{
            throw processMultiWSException(response.header.MessageResponseStatus.ErrorStatus);
        }
        return null;
        //System.debug(response);
    }
    
    //payment process for Credit Card Payment
    public Boolean submitPayment(PaymentDetails p){
        
        TIBCOPaymentGateway_Service.PaymentGatewayEndpoint stub = new TIBCOPaymentGateway_Service.PaymentGatewayEndpoint();
        TIBCOPaymentGateway_MessageTypes.Header_element header = new TIBCOPaymentGateway_MessageTypes.Header_element();
        if (SystemSettings__c.getInstance().BRE_Debug_User__c == null)
            header.UserID = Userinfo.getUserName();
        else
            header.UserID = SystemSettings__c.getInstance().BRE_Debug_User__c;
            
        header.UserType = UserInfo.getUserType();
        header.MessageTimeStamp = datetime.now();
        
        stub.timeout_x = 60000;
       
        TIBCOPaymentGateway_MessageTypes.PaymentDetails_element pd = new TIBCOPaymentGateway_MessageTypes.PaymentDetails_element();
        
        pd.TaskID = p.TaskId;
        pd.TransactionType = p.TransactionType;
        pd.TransactionRef = p.TransactionRef;
        pd.billingAccountNumber = p.BillingAccountNumber;
        pd.PaymentAmount = p.PaymentAmount;
        
        TIBCOPaymentGateway_MessageTypes.CreditCardDetails_element ccd = new TIBCOPaymentGateway_MessageTypes.CreditCardDetails_element();
        
        ccd.CardNumber = p.CardNumber;
        ccd.CardExpiryMonth = p.CardExpiryMonth;
        ccd.CardExpiryYear = p.CardExpiryYear;
        ccd.CardHolderName = p.CardHolderName;
        ccd.CVN = p.CVN;
        
        pd.CreditCardDetails = ccd;
        
        TIBCOPaymentGateway_MessageTypes.Header_element response = stub.submitPayment(header, pd);
        
        if (Boolean.valueOf(response.MessageResponseStatus.MessageSuccessInd)) { //webservice success
            if (response != null) {
                return true;
            } 
        }else{
            throw processMultiWSException(response.MessageResponseStatus.ErrorStatus);
        }
        return false;
    }
 /*

    TIBCOPaymentGateway_MessageTypes.Header_element resp = stub.submitPayment(hdr, pd);
    System.debug(resp);*/
    
    public Boolean registerDeregisterCustomer (List<RegisterDeregesterCustomer> rdList, String paymentType){
        
        System.debug('##REGISTER##');
        System.debug(rdList);
        
        TIBCOPaymentGateway_Service.PaymentGatewayEndpoint stub = new TIBCOPaymentGateway_Service.PaymentGatewayEndpoint();
        // populate header info
        TIBCOPaymentGateway_MessageTypes.Header_element header = new TIBCOPaymentGateway_MessageTypes.Header_element();

        if (SystemSettings__c.getInstance().BRE_Debug_User__c == null)
            header.UserID = Userinfo.getUserName();
        else
            header.UserID = SystemSettings__c.getInstance().BRE_Debug_User__c; 
            
        header.UserType = UserInfo.getUserType();
        header.MessageTimeStamp = datetime.now();
        
        stub.timeout_x = 60000;
         
        List<TIBCOPaymentGateway_MessageTypes.Register_DeregisterCustomer_element> rdRecordList = new List<TIBCOPaymentGateway_MessageTypes.Register_DeregisterCustomer_element>();
        
        for(RegisterDeregesterCustomer rd : rdList){
        
            TIBCOPaymentGateway_MessageTypes.Register_DeregisterCustomer_element rdRecord = new TIBCOPaymentGateway_MessageTypes.Register_DeregisterCustomer_element();
            rdRecord.TaskID = rd.TaskID;
            rdRecord.Action = rd.Action;
            rdRecord.BillingAccountNumber = rd.BillingAccountNumber;
            rdRecord.DDBudget = rd.DDBudgetFlag;
            rdRecord.DDStartDate = rd.DDStartDate;
            rdRecord.IncBal = rd.InclBalanceFlag;
            
            TIBCOPaymentGateway_MessageTypes.Customer_element customer = new TIBCOPaymentGateway_MessageTypes.Customer_element();
            customer.FirstName = rd.FirstName;
            customer.LastName = rd.LastName;
            
            TIBCOPaymentGateway_MessageTypes.DirectDebit_element dd; 
            TIBCOPaymentGateway_MessageTypes.CreditCardDetails_element ccd;
            if (rd.Action == 'Register') {
                if(paymentType.equalsIgnoreCase('Bank Account')){
                    dd = new TIBCOPaymentGateway_MessageTypes.DirectDebit_element();
                    dd.AccountNumber = rd.AccountNumber;
                    dd.AccountTitle = rd.AccountTitle;
                    dd.AccountBSB = rd.AccountBSB;
                    dd.BankName = rd.BankName;
                    dd.BankState = rd.BankState;
                    dd.BankSuburb = rd.BankSuburb;
                    rdRecord.DirectDebit = dd;
                }else{
                    ccd = new TIBCOPaymentGateway_MessageTypes.CreditCardDetails_element();
                    ccd.CardNumber = rd.CardNumber;
                    ccd.CardExpiryMonth = rd.CardExpiryMonth;
                    ccd.CardExpiryYear = rd.CardExpiryYear;
                    ccd.CardHolderName = rd.CardHolderName;
                    ccd.CVN = rd.CVN;
                    rdRecord.CreditCardDetails = ccd;
                }
            }
            
            rdRecord.Customer = customer;
            
            rdRecordList.add(rdRecord);
        }
        
        TIBCOPaymentGateway_MessageTypes.Header_element response = stub.registerDeregisterCustomer(header, rdRecordList);
        
        if (Boolean.valueOf(response.MessageResponseStatus.MessageSuccessInd)) { //webservice success
            if (response != null) {
                return true;
            }  
        }else{
            throw processMultiWSException(response.MessageResponseStatus.ErrorStatus);
        }
        return false;
    }
    
    private static MultipleWebServiceBusinessException processMultiWSException(List<TIBCOPaymentGateway_MessageTypes.ErrorStatus_element> errorStatuses){
        MultipleWebServiceBusinessException multiWSEx = new MultipleWebServiceBusinessException('Errors returned from Create Account Web Service');
        for(TIBCOPaymentGateway_MessageTypes.ErrorStatus_element errorStatus: errorStatuses ){
            SingleWebServiceBusinessException ex = new SingleWebServiceBusinessException(errorStatus.ErrorDescription);
            ex.errorCode = errorStatus.ErrorCode;
            ex.errorSeverity = errorStatus.ErrorSeverity;
            multiWSEx.multiEx.add(ex);
        }
        return multiWSEx;
    } 
}