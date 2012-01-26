/*
    Type:       Webservice class
    Purpose:    web service for Hi-Af to call SFDC

    Used By:    
    ---------------------------------------------------------------
    History:

    20-Sep-2011 J.Pe (Davanti Consulting)    Created

*/
global class SFDCWS_COOTS{ 
    
    /* PUBLIC METHODS */
    webService static COOTSOutput apportion(String role, String hiAfAccNo, String cisPropRef, String source, String moveInType){
        try{
            COOTSUtil.apportion(role, hiAfAccNo, cisPropRef, source, moveInType);
            COOTSOutput response = new COOTSOutput();
            response.isSuccess = true;
            return response;
        }catch(COOTSUtil.COOTSMultiException multiEx){
            COOTSOutput response = new COOTSOutput();
            response.isSuccess = false;
            for(COOTSUtil.COOTSException ex: multiEx.multiExs){
                response.outputMessages.add(createOutputMessage(ex.exceptionType, ex.getMessage()));
            }
            return response;
        }catch(COOTSUtil.COOTSException ex){
            COOTSOutput response = new COOTSOutput();
            response.isSuccess = false;
            response.outputMessages.add(createOutputMessage(ex.exceptionType, ex.getMessage()));
            return response;
        }
    }
    
    webService static COOTSOutput completeSMR(String caseNumber){
        try{
            List<Billing_Account__c> accountsChanged = COOTSUtil.completeSMR(caseNumber);
            COOTSOutput response = new COOTSOutput();
            response.isSuccess = true;
            response.accountsChanged = accountsChanged;
            return response;
        }catch(COOTSUtil.COOTSMultiException multiEx){
            COOTSOutput response = new COOTSOutput();
            response.isSuccess = false;
            for(COOTSUtil.COOTSException ex: multiEx.multiExs){
                response.outputMessages.add(createOutputMessage(ex.exceptionType, ex.getMessage()));
            }
            return response;
        }catch(COOTSUtil.COOTSException ex){
            COOTSOutput response = new COOTSOutput();
            response.isSuccess = false;
            response.outputMessages.add(createOutputMessage(ex.exceptionType, ex.getMessage()));
            return response;
        }
    }

    webService static COOTSOutput completeNOS(String caseNumber, String purchaserRole, Boolean NOSComplete, /*String NOSExceptionCode,*/ String NOSExceptionMsg, List<ErrorStatus> errors){
        try{
            List<Billing_Account__c> accountsUpdated = COOTSUtil.completeNOS(caseNumber, PurchaserRole, NOSComplete, /*NOSExceptionCode,*/ NOSExceptionMsg, convertErrorStatus(errors));
            COOTSOutput response = new COOTSOutput();
            response.isSuccess = TRUE;
            response.accountsChanged = accountsUpdated;
            return response;
        } catch (COOTSUtil.COOTSMultiException multiEx){
            COOTSOutput response = new COOTSOutput();
            response.isSuccess = FALSE;
            for(COOTSUtil.COOTSException ex: multiEx.multiExs){
                response.outputMessages.add(createOutputMessage(ex.exceptionType, ex.getMessage()));
            }
            return response;
        } catch (COOTSUtil.COOTSException ex){
            COOTSOutput response = new COOTSOutput();
            response.isSuccess = false;
            response.outputMessages.add(createOutputMessage(ex.exceptionType, ex.getMessage()));
            return response;
        }
    }

    /* PRIVATE METHODS */
    private static OutputMessage createOutputMessage(String messageType, String messageDescription){
        OutputMessage msg = new OutputMessage();
        msg.messageType = messageType;
        msg.messageDescription = messageDescription;
        return msg;
    }

    private static List<COOTSUtil.ErrorStatus> convertErrorStatus(List<ErrorStatus> wsErrorStatuses){
        List<COOTSUtil.ErrorStatus> cootsErrorStatuses = new List<COOTSUtil.ErrorStatus>();
        for(ErrorStatus wsStatus: wsErrorStatuses){
            COOTSUtil.ErrorStatus cootsStatus = new COOTSUtil.ErrorStatus();
            cootsStatus.ErrorCode = wsStatus.ErrorCode;
            cootsStatus.ErrorSeverity = wsStatus.ErrorSeverity ;
            cootsStatus.ErrorDescription = wsStatus.ErrorDescription ;
            cootsErrorStatuses.add(cootsStatus);
        }
        return cootsErrorStatuses;
    }

    /* INNER CLASS */
    global class COOTSOutput{
        webservice boolean isSuccess;
        List<Billing_Account__c> accountsChanged = new List<Billing_Account__c>();
        webservice List<OutputMessage> outputMessages = new List<OutputMessage>();
    }
    global class OutputMessage{
        webservice String messageType;
        webservice String messageDescription;
    }

    global class ErrorStatus{
        webservice String ErrorCode;
        webservice String ErrorSeverity;
        webservice String ErrorDescription;
    }

    /* TEST METHODS */
    public static testmethod void test_SFDCWS_NOS(){

        COOTSOutput output = SFDCWS_COOTS.completeNOS('Crap', 'Crap', false, /*'Crap',*/ 'Crap', new List<ErrorStatus>());
        System.assertEquals(false, output.isSuccess);
        System.assertEquals('Case number not found',output.outputMessages[0].messageDescription);

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

        String caseNumber = [Select CaseNumber from Case where id = :testNOSCase.id][0].CaseNumber;

        output = SFDCWS_COOTS.completeNOS(caseNumber, 'Owner Occupier', false, 'Bad Error', new List<ErrorStatus>());
        System.assertEquals(true, output.isSuccess);
        System.assertEquals([Select Status from Case where id = :testNOSCase.id][0].Status, 'Pending');

        output = SFDCWS_COOTS.completeNOS(caseNumber, 'Owner Occupier', true, null, new List<ErrorStatus>());
        System.assertEquals(true, output.isSuccess);
        System.assertEquals([Select Status from Case where id = :testNOSCase.id][0].Status, 'Closed');
    }

    public static testmethod void test_SFDCWS_COOTS_SMR(){
        // create test data
        Account account = new Account();
        account.name = 'foo';
        insert account;

        Contact contact = new Contact();
        contact.LastName = 'Foo';
        contact.AccountId = account.id;
        contact.Title = 'x';
        contact.Phone = 'x';
        contact.Email = 'x@x.com';
        insert contact;

        Property__c prop = new Property__c();
        prop.Universal_Id_c__c = 'sdgfsdgf';
        prop.Name = 'Test Property';
        insert prop;

        Billing_Account__c billAcc1 = new Billing_Account__c();
        billAcc1.Name = 'TBD';
        billAcc1.Customer__c = account.id;
        billAcc1.Property__c = prop.id;
        billAcc1.Role__c = 'Tenant';
        billAcc1.Status__c = 'Pending';
        billAcc1.HiAF_Account_Number__c = 'dfvtserb';
        insert billAcc1;

        Billing_Account__c billAcc2 = new Billing_Account__c();
        billAcc2.Name = 'TBD';
        billAcc2.Customer__c = account.id;
        billAcc2.Property__c = prop.id;
        billAcc2.Role__c = 'Owner Occupier';
        billAcc2.Status__c = 'Active';
        billAcc2.HiAF_Account_Number__c = 'sdvrysey';
        insert billAcc2;

        Billing_Account__c billAcc4 = new Billing_Account__c();
        billAcc4.Name = 'TBD';
        billAcc4.Customer__c = account.id;
        billAcc4.Property__c = prop.id;
        billAcc4.Role__c = 'Tenant';
        billAcc4.Status__c = 'Active';
        billAcc4.HiAF_Account_Number__c = 'fdhbrny';
        insert billAcc4;

        RecordType smrRt = [Select id from RecordType where Name = 'Special Meter Read' and SobjectType = 'Case'];
        RecordType nosRt = [Select id from RecordType where Name = 'Notice of Sale' and SobjectType = 'Case'];

        COOTSOutput output = SFDCWS_COOTS.completeSMR('Crap');
        System.assertEquals(false, output.isSuccess);
        System.assertEquals('Case number not found',output.outputMessages[0].messageDescription);

        Case case1 = new Case(AccountId = account.id, Property__c = prop.id, Billing_Account__c = billAcc1.id,
            Contact_Type__c = 'Crap', Status = 'New', Type_of_Read__c = 'Information Read');
        insert case1;
        case1 = [Select id, CaseNumber from Case where id = :case1.id];
        output = SFDCWS_COOTS.completeSMR(case1.CaseNumber);
        System.assertEquals(false, output.isSuccess);

        Case case2 = new Case(recordTypeId = smrRt.id, AccountId = account.id, Property__c = prop.id, Billing_Account__c = billAcc1.id,
            Contact_Type__c = 'Agent', Status = 'Waiting for HiAffinity', Type_of_Read__c = 'Tenant Move In', Reading_Date__c = Date.newInstance(2050, 1, 3));
        insert case2;
        case2 = [Select id, CaseNumber from Case where id = :case2.id];
        output = SFDCWS_COOTS.completeSMR(case2.CaseNumber);
        System.assertEquals(true, output.isSuccess);
        System.assertEquals(3, output.accountsChanged.size());
        billAcc1 = [Select Status__c, Role__c from Billing_Account__c where id = :billAcc1.id ];
        System.assertEquals('Active', billAcc1.Status__c);
        billAcc2 = [Select Status__c, Role__c from Billing_Account__c where id = :billAcc2.id ];
        System.assertEquals('Active', billAcc2.Status__c);
        System.assertEquals('Landlord', billAcc2.Role__c);
        billAcc4 = [Select Status__c, Role__c from Billing_Account__c where id = :billAcc4.id ];
        System.assertEquals('Closed', billAcc4.Status__c);

        Case case3 = new Case(recordTypeId = smrRt.id, AccountId = account.id, Property__c = prop.id, Billing_Account__c = billAcc1.id,
            Contact_Type__c = 'Agent', Status = 'Waiting for HiAffinity', Type_of_Read__c = 'Tenant Move Out', Reading_Date__c = Date.newInstance(2050, 1, 3));
        insert case3;
        case3 = [Select id, CaseNumber from Case where id = :case3.id];
        output = SFDCWS_COOTS.completeSMR(case3.CaseNumber);
        System.assertEquals(true, output.isSuccess);
        System.assertEquals(2, output.accountsChanged.size());
        billAcc1 = [Select Status__c, Role__c from Billing_Account__c where id = :billAcc1.id ];
        System.assertEquals('Closed', billAcc1.Status__c);
        billAcc2 = [Select Status__c, Role__c from Billing_Account__c where id = :billAcc2.id ];
        System.assertEquals('Active', billAcc2.Status__c);
        System.assertEquals('Owner Occupier', billAcc2.Role__c);

    }

    public static testmethod void test_SFDCWS_COOTS_Apportion(){
        // create test data
        Account account = new Account();
        account.name = 'foo';
        insert account;

        Contact contact = new Contact();
        contact.LastName = 'Foo';
        contact.AccountId = account.id;
        contact.Title = 'x';
        contact.Phone = 'x';
        contact.Email = 'x@x.com';
        insert contact;

        Property__c prop = new Property__c();
        prop.Universal_Id_c__c = 'sdgfsdgf';
        prop.CIS_Property_Id__c= 'sfgsdgsg';
        prop.Name = 'Test Property';
        insert prop;

        Billing_Account__c billAcc1 = new Billing_Account__c();
        billAcc1.Name = 'TBD';
        billAcc1.Customer__c = account.id;
        billAcc1.Property__c = prop.id;
        billAcc1.Role__c = 'Tenant';
        billAcc1.Status__c = 'Active';
        billAcc1.HiAF_Account_Number__c = 'dfvtserb';
        insert billAcc1;

        Billing_Account__c billAcc2 = new Billing_Account__c();
        billAcc2.Name = 'TBD';
        billAcc2.Customer__c = account.id;
        billAcc2.Role__c = 'Owner Occupier';
        billAcc2.Status__c = 'Active';
        billAcc2.HiAF_Account_Number__c = 'sdvrysey';
        insert billAcc2;
        
        //COOTSOutput output = SFDCWS_COOTS.apportion(String purchaserRole, String hiAfAccNo, String cisPropRef, String source, String moveInType);
        COOTSOutput output = SFDCWS_COOTS.apportion(null, null, null, null, null);
        System.assertEquals(false, output.isSuccess);
        output = SFDCWS_COOTS.apportion(null, null, null, null, 'in');
        System.assertEquals(false, output.isSuccess);
        System.debug('##FOOHERE');
        output = SFDCWS_COOTS.apportion('Tenant', 'dfvtserb', null, 'Test', 'out');
        System.assertEquals(true, output.isSuccess);
        output = SFDCWS_COOTS.apportion('Owner Occupier', 'sdvrysey', 'sfgsdgsg', 'Test', 'in');
        for(OutputMessage msg: output.outputMessages){
            System.debug('**** '+msg.messageDescription);
        }
        System.assertEquals(true, output.isSuccess);
        output = SFDCWS_COOTS.apportion('Tenant', 'dfvtserb', 'sfgsdgsg', 'Test', 'in');
        //System.assertEquals(false, output.isSuccess);
    }
    public static testmethod void test_SFDCWS_COOTS_Other(){
        Case c = SobjectCreator.createCaseInfoStatementUpdate();
        insert c;
        String caseNumber = [Select CaseNumber from Case where id = :c.id][0].CaseNumber;
        CootsOutput output = SFDCWS_COOTS.completeNOS(caseNumber, 'Owner Occupier', true, null, new List<ErrorStatus>());

		ErrorStatus es = new ErrorStatus();

    }


}