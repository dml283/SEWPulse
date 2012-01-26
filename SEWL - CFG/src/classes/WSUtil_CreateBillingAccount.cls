/*
    Type:       Web Service Utility
    Purpose:    Controls the creation of billing account

    Used By:    
    ---------------------------------------------------------------
    History:

    13-Sep-2011 J.Pe (Davanti Consulting)    Created

*/
public class WSUtil_CreateBillingAccount extends WSUtil{
    public static List<String> createBillingAccount(Billing_Account__c bAcct, boolean isWelcomeHomeKit, Integer noOfBillAcctToCreate) {
        //Construct Request - Header
        TibcoCreateBillingAccount_MessageType.Header_element header = new TibcoCreateBillingAccount_MessageType.Header_element();
        header.UserID = Userinfo.getUserName();
        header.UserType = Userinfo.getUserType();
        header.MessageTimeStamp = datetime.now();
        // Initialise Web Service
        TibcoCreateBillingAccount_Service.SOAPEventSource stub = new TibcoCreateBillingAccount_Service.SOAPEventSource();
        stub.timeout_x = 60000;
        if(noOfBillAcctToCreate <=1){
            TibcoCreateBillingAccount_MessageType.createAccountresponse_element response = stub.createAccount(transformAccountDetails(bAcct,isWelcomeHomeKit), header);            
            if (Boolean.valueOf(response.header.MessageResponseStatus.MessageSuccessInd)) {  //webservice success
                return new String[]{response.AccountNumber};
            }else{
                throw processMultiWSException(response.Header.MessageResponseStatus.ErrorStatus);
            }
        }else{
            TibcoCreateBillingAccount_MessageType.createMultipleAccountResponse_element response = stub.createMultipleAccount(transformAccountDetails(bAcct,isWelcomeHomeKit,noOfBillAcctToCreate), header);            
            if (Boolean.valueOf(response.header.MessageResponseStatus.MessageSuccessInd)) {  //webservice success
                return response.AccountNumber;
            }else{
                throw processMultiWSException(response.Header.MessageResponseStatus.ErrorStatus);
            }
        }
        return null;
    }
    private static TibcoCreateBillingAccount_MessageType.AccountDetails_element transformAccountDetails(Billing_Account__c bAcct, boolean isWelcomeHomeKit){
        TibcoCreateBillingAccount_MessageType.AccountDetails_element acctDetails = new TibcoCreateBillingAccount_MessageType.AccountDetails_element();
        acctDetails.Title = bAcct.Title__c;
        acctDetails.Initials = bAcct.Initials__c;
        acctDetails.Name = bAcct.Account_Name__c;
        acctDetails.Type_x = bAcct.Residential_or_Non_Residential__c;
        //acctDetails.Mode = (('Ad_Hoc'.equals(bAcct.RecordType.DeveloperName))?('False'):('True'));
        acctDetails.Mode = ('Ad_Hoc'.equals(bAcct.RecordType.DeveloperName));
        acctDetails.ICEReference = bAcct.ICE_Customer_Ref__c;
        acctDetails.CareOf = bAcct.Care_Of__c;
        acctDetails.Attention = bAcct.Attention__c;
        acctDetails.StreetAddress = bAcct.Street_Address__c;
        acctDetails.City = bAcct.City__c;
        acctDetails.State = bAcct.State__c;
        acctDetails.Postcode = bAcct.Postal_Code__c;
        acctDetails.DPID = bAcct.DPID__c;
        acctDetails.Country = bAcct.Country__c;
        acctDetails.AddressType = bAcct.Billing_Address_Same_As__c;
        acctDetails.WHKit = isWelcomeHomeKit;
        acctDetails.ClericalInspectionCode = bAcct.Clerical__c;
        return acctDetails;
    }
    
    private static TibcoCreateBillingAccount_MessageType.AccountDetails_element transformAccountDetails(Billing_Account__c bAcct, boolean isWelcomeHomeKit, Integer noOfBillAcctToCreate){
        TibcoCreateBillingAccount_MessageType.AccountDetails_element acctDetails = transformAccountDetails(bAcct, isWelcomeHomeKit);
        acctDetails.B_O_Number = ''+noOfBillAcctToCreate;
        return acctDetails;
    }
    
    private static MultipleWebServiceBusinessException processMultiWSException(List<TibcoCreateBillingAccount_MessageType.ErrorStatus_element> errorStatuses){
        MultipleWebServiceBusinessException multiWSEx = new MultipleWebServiceBusinessException('Errors returned from Create Account Web Service');
        for(TibcoCreateBillingAccount_MessageType.ErrorStatus_element errorStatus: errorStatuses ){
            SingleWebServiceBusinessException ex = new SingleWebServiceBusinessException(errorStatus.ErrorDescription);
            ex.errorCode = errorStatus.ErrorCode;
            ex.errorSeverity = errorStatus.ErrorSeverity;
            multiWSEx.multiEx.add(ex);
        }
        return multiWSEx;
    }    
}