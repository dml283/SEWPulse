public with sharing class NoticeOfSaleActions_Extension {
/*
    Type:       VF Extension
    Purpose:    Calls the NOS process

    Used By:    NoticeOfSale VF
    ---------------------------------------------------------------
    History:


*/

    public static final String CLOSED_CASE_STATUS = 'Closed';

    private Case NOSCase;

    public NoticeOfSaleActions_Extension(ApexPages.StandardController controller) {
        this.NOSCase = (Case)controller.getRecord();
    }

    public PageReference performNoticeOfSale(){
        if (preBREValidation()){
            return null;
        } else {
            resetInfoAndAlerts();

            try{
                WSUtil_NoticeOfSale.NoticeOfSaleResponse response = new WSUtil_NoticeOfSale.NoticeOfSaleResponse();
                WSUtil_NoticeOfSale ws = new WSUtil_NoticeOfSale();
                response = ws.performNoticeOfSale(NOSCase);

                if(response.messages.size()>0){
                    for(WSUtil.SingleWebServiceBusinessException msg : response.messages){
                        if ('3'.equals(msg.ErrorSeverity) || '4'.equals(msg.ErrorSeverity) || '5'.equals(msg.ErrorSeverity)){
                            NOSCase.Alerts_Int_Long__c += msg.getMessage()+'\n';
                        } else if ('1'.equals(msg.ErrorSeverity) || '2'.equals(msg.ErrorSeverity)){
                            NOSCase.Information_Int_Long__c += msg.getMessage()+'\n';
                        }
                    }
                }
                if(response.noAlerts){
                    NOSCase.Status = 'Waiting for HiAffinity';
                    NOSCase.Information_Int_Long__c = 'The results of the Notice of Sale is in progress and you will be notified via email.\n'+NOSCase.Information_Int_Long__c;

                } else {
                    NOSCase.Status = 'In Progress';
                }
            } catch (system.Calloutexception ex) { // SOAP Error
                ApexPages.Message soapError = new ApexPages.message(ApexPages.severity.ERROR, 'There was a problem performing the Notice of Sale - please contact system administrator. Error message:'+ex.getMessage());
                ApexPages.addMessage(soapError);
                return null;
            } catch (WSUtil.MultipleWebServiceBusinessException e) {
                for (WSUtil.SingleWebServiceBusinessException err: e.multiEx) {
                    ApexPages.Message wsError = new ApexPages.Message(ApexPages.severity.ERROR, err.getMessage());
                    ApexPages.addMessage(wsError);
                }
                return null;
            }
        }
        update NOSCase;
        return new PageReference('/' + NOSCase.Id);
    }

    private Boolean preBREValidation(){
        if (NOSCase.IsClosed || NOSCase.Complete__c){
            ApexPages.Message closedOrCompleteError = new ApexPages.Message(ApexPages.Severity.ERROR, 'You cannot Perform a Notice of Sale for a Closed or Completed Case');
            ApexPages.addMessage(closedOrCompleteError);
        }

        if (NOSCase.Status == 'Waiting for HiAffinity'){
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'This Notice of Sale is pending an action from HiAffinity');
            ApexPages.addMessage(msg);
        }
        /*
        if (NOSCase.Settlement_Date__c <= system.today()){
            ApexPages.Message settlementError = new ApexPages.Message(ApexPages.Severity.ERROR, 'You can only perform a Notice of Sale when the Settlement date is in the future');
            ApexPages.addMessage(settlementError);
        }
        */
        if (NOSCase.Type_of_Sale__c == 'Sale of Business'){
            ApexPages.Message typeOfSaleError = new ApexPages.Message(ApexPages.Severity.ERROR, 'You cannot perform a Notice of Sale for a Sale of Business');
            ApexPages.addMessage(typeOfSaleError);
        }
        return ApexPages.hasMessages();

    }

    private void resetInfoAndAlerts(){
        NOSCase.Information_Int_Long__c = '';
        NOSCase.Alerts_Int_Long__c = '';
        NOSCase.NOS_Exception__c = '';
    }

    public PageReference back(){
        return new PageReference('/' + NOSCase.Id);
    }

    private static Case getCaseDetails(Id caseId){
        return [SELECT Id, CaseNumber, IsClosed, Complete__c, Settlement_Date__c, Type_of_Sale__c,
                    Information_Int_Long__c, Alerts_Int_Long__c, NOS_Exception__c, Vendor_Billing_Account__r.HiAF_Account_Number__c,
                    Purchaser_Billing_Account__r.HiAF_Account_Number__c, Tenant_Billing_Account__r.HiAF_Account_Number__c,
                    Cheque_Included__c, Cheque_Amount__c, Cheque_Number__c, Bank__c, Dialysis_Customer__c, Caveat_Customer__c,
                    Legal_Customer__c, BNSM_ADC_Manual_Update__c, RecordType.DeveloperName, Status
                FROM Case WHERE Id = :caseId];
    }

    private static testMethod void testNoticeOfSaleExtension(){
        //Setup Test Data
        Account testCustomerPurchaser = SObjectCreator.createAccountResidentialCustomer();
        insert testCustomerPurchaser;

        Billing_Account__c testPurchaserBillingAccount = SObjectCreator.createBillingAccountBillingAccount();
        testPurchaserBillingAccount.Customer__c = testCustomerPurchaser.Id;
        testPurchaserBillingAccount.Role__c = 'Owner Occupier';
        insert testPurchaserBillingAccount;


        Account testCustomerVendor = SObjectCreator.createAccountResidentialCustomer();
        insert testCustomerVendor;

        Property__c testProperty = SObjectCreator.createProperty();
        insert testProperty;

        Billing_Account__c testVendorBillingAccount = SObjectCreator.createBillingAccountBillingAccount();
        testVendorBillingAccount.Customer__c = testCustomerVendor.Id;
        testVendorBillingAccount.Role__c = 'Landlord';
        testVendorBillingAccount.Property__c = testProperty.Id;
        insert testVendorBillingAccount;

        Account testCustomerTenant = SObjectCreator.createAccountResidentialCustomer();
        insert testCustomerTenant;

        Billing_Account__c testTenantBillingAccount = SObjectCreator.createBillingAccountBillingAccount();
        testTenantBillingAccount.Customer__c = testCustomerTenant.Id;
        testTenantBillingAccount.Role__c = 'Tenant';
        testTenantBillingAccount.Property__c = testProperty.Id;
        insert testTenantBillingAccount;

        Case testNOSCase = SObjectCreator.createCaseNoticeOfSale();
        testNOSCase.Property__c = testProperty.Id;
        testNOSCase.Billing_Account__c = testVendorBillingAccount.Id;
        testNOSCase.Purchaser_Billing_Account__c = testPurchaserBillingAccount.Id;
        testNOSCase.Vendor_Billing_Account__c = testVendorBillingAccount.Id;
        testNOSCase.Tenant_Billing_Account__c = testTenantBillingAccount.Id;
        testNOSCase.Type_of_Sale__c = 'New Purchaser, Tenant Leaves';
        testNOSCase.Settlement_Date__c = system.today()+1;

        testNOSCase.Status = 'New';
        insert testNOSCase;

        testNOSCase = getCaseDetails(testNOSCase.Id);

        PageReference pageRef = Page.NoticeOfSaleActions;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController stdCon = new ApexPages.StandardController(testNOSCase);
        NoticeOfSaleActions_Extension extn = new NoticeOfSaleActions_Extension(stdCon);

        Test.startTest();

        extn.performNoticeOfSale();

        Case validateCase = getCaseDetails(testNOSCase.Id);
        //system.assert(validateCase.IsClosed);
        //system.assert(validateCase.Complete__c);

        Case testNOSCase2 = SObjectCreator.createCaseNoticeOfSale();
        testNOSCase2.Property__c = testProperty.Id;
        testNOSCase2.Billing_Account__c = testVendorBillingAccount.Id;
        testNOSCase2.Purchaser_Billing_Account__c = testPurchaserBillingAccount.Id;
        testNOSCase2.Vendor_Billing_Account__c = testVendorBillingAccount.Id;
        testNOSCase2.Tenant_Billing_Account__c = testTenantBillingAccount.Id;
        testNOSCase2.Settlement_Date__c = system.today()-1;
        testNOSCase2.Type_of_Sale__c = 'Sale of Business';
        testNOSCase2.Status = 'New';
        insert testNOSCase2;

        testNOSCase2 = getCaseDetails(testNOSCase2.Id);

        PageReference pageRef2 = Page.NoticeOfSaleActions;
        Test.setCurrentPage(pageRef2);

        ApexPages.StandardController stdCon2 = new ApexPages.StandardController(testNOSCase2);
        NoticeOfSaleActions_Extension extn2 = new NoticeOfSaleActions_Extension(stdCon2);
        extn2.performNoticeOfSale();

        Case validateCase2 = getCaseDetails(testNOSCase2.Id);

        //system.assert(validateCase2.IsClosed); // Sale of Business Cases closed by workflow rule
        //system.assert(!validateCase2.Complete__c);
        system.assert(ApexPages.hasMessages());

        extn2.back();
        Test.stopTest();

    }

    private static testMethod void testNoticeOfSaleExtension2(){
        //Setup Test Data
        Account testCustomerPurchaser = SObjectCreator.createAccountResidentialCustomer();
        insert testCustomerPurchaser;

        Billing_Account__c testPurchaserBillingAccount = SObjectCreator.createBillingAccountBillingAccount();
        testPurchaserBillingAccount.Customer__c = testCustomerPurchaser.Id;
        testPurchaserBillingAccount.Role__c = 'Owner Occupier';
        insert testPurchaserBillingAccount;


        Account testCustomerVendor = SObjectCreator.createAccountResidentialCustomer();
        insert testCustomerVendor;

        Property__c testProperty = SObjectCreator.createProperty();
        insert testProperty;

        Billing_Account__c testVendorBillingAccount = SObjectCreator.createBillingAccountBillingAccount();
        testVendorBillingAccount.Customer__c = testCustomerVendor.Id;
        testVendorBillingAccount.Role__c = 'Landlord';
        testVendorBillingAccount.Property__c = testProperty.Id;
        insert testVendorBillingAccount;

        Account testCustomerTenant = SObjectCreator.createAccountResidentialCustomer();
        insert testCustomerTenant;

        Billing_Account__c testTenantBillingAccount = SObjectCreator.createBillingAccountBillingAccount();
        testTenantBillingAccount.Customer__c = testCustomerTenant.Id;
        testTenantBillingAccount.Role__c = 'Tenant';
        testTenantBillingAccount.Property__c = testProperty.Id;
        insert testTenantBillingAccount;

        Case testNOSCase = SObjectCreator.createCaseNoticeOfSale();
        testNOSCase.Property__c = testProperty.Id;
        testNOSCase.Billing_Account__c = testVendorBillingAccount.Id;
        testNOSCase.Purchaser_Billing_Account__c = testPurchaserBillingAccount.Id;
        testNOSCase.Vendor_Billing_Account__c = testVendorBillingAccount.Id;
        testNOSCase.Tenant_Billing_Account__c = testTenantBillingAccount.Id;
        testNOSCase.Type_of_Sale__c = 'New Purchaser, Tenant Leaves';
        testNOSCase.Settlement_Date__c = system.today()+1;

        testNOSCase.Status = 'Waiting for HiAffinity';
        insert testNOSCase;

        testNOSCase = getCaseDetails(testNOSCase.Id);

        PageReference pageRef = Page.NoticeOfSaleActions;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController stdCon = new ApexPages.StandardController(testNOSCase);
        NoticeOfSaleActions_Extension extn = new NoticeOfSaleActions_Extension(stdCon);

        Test.startTest();

        extn.performNoticeOfSale();
        Test.stopTest();
        
        TibcoNoticeOfSale_MessageTypes.ErrorStatus_element err = new TibcoNoticeOfSale_MessageTypes.ErrorStatus_element();
    }


}