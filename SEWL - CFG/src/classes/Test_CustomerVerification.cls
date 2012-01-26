/*
    Type:       Test Class
    Purpose:    
				Performs Testing for Customer Verification

    ---------------------------------------------------------------
    History:


*/
@isTest
private class Test_CustomerVerification {

	static testMethod void CustomerVerificationFromBillingAccount(){
		List<String> classificationCodes = new List<String>{'AA', 'HR', 'LD'};
        List<Account> testCustomers = new List<Account>();
        Account nonResidentialCustomer1 = SObjectCreator.createAccountNonResidentialCompany();
        nonResidentialCustomer1.Is_EWOV_Investigative_Complaint__c = TRUE;
        nonResidentialCustomer1.Is_Key_Customer__c = TRUE;
        testCustomers.add(nonResidentialCustomer1);

        Account nonResidentialCustomer2 = SObjectCreator.createAccountNonResidentialIndividual();
        testCustomers.add(nonResidentialCustomer2);
        insert testCustomers;

        List<Contact> testContacts = new List<Contact>();
        Contact customerContact1 = SObjectCreator.createContact();
        customerContact1.AccountId = testCustomers[0].Id;
        customerContact1.Preferred_Phone_Type__c = 'Work';
        testContacts.add(customerContact1);

        Contact customerContact2 = SObjectCreator.createContact();
        customerContact2.AccountId = testCustomers[0].Id;
        testContacts.add(customerContact2);

        Contact thirdPartyContact1 = SObjectCreator.createContact();
        thirdPartyContact1.AccountId = testCustomers[1].Id;
        thirdPartyContact1.Preferred_Phone_Type__c = 'Home';
        testContacts.add(thirdPartyContact1);
        insert testContacts;

        Person_Customer_Relationship__c thirdPartyContactRelationship = SObjectCreator.createPersonCustomerRelationship();
        thirdPartyContactRelationship.Customer__c = testCustomers[0].Id;
        thirdPartyContactRelationship.Person__c = testContacts[2].Id;
        thirdPartyContactRelationship.Third_Party_Type__c = 'Third Party';
        insert thirdPartyContactRelationship;

        Property__c customerProperty = SObjectCreator.createProperty();
        customerProperty.R6_Avenview__c = TRUE;
        insert customerProperty;

        Recovery_Path__c recoveryPathCustomSetting = SObjectCreator.createRecoveryPathCustomSetting();
        recoveryPathCustomSetting.Check_Type__c = '0 - Alert';
        recoveryPathCustomSetting.Short_Description__c = 'Test Short';
        recoveryPathCustomSetting.Message__c = 'Recovery Path Test Message';
        recoveryPathCustomSetting.Name = 'Test';
        insert recoveryPathCustomSetting;

        Clerical__c clericalCustomSetting = SObjectCreator.createClericalCustomSetting();
        clericalCustomSetting.Check_Type__c = '0 - Alert';
        clericalCustomSetting.Short_Description__c = 'Test Short';
        clericalCustomSetting.Message__c = 'Test Clerical Message';
        clericalCustomSetting.Name = 'Test';
        insert clericalCustomSetting;

        Billing_Account__c customerBillingAccount = SObjectCreator.createBillingAccountAdHoc();
        customerBillingAccount.Customer__c = testCustomers[0].Id;
        customerBillingAccount.Property__c = customerProperty.Id;
        customerBillingAccount.Risk_Factor__c = 'H';
        customerBillingAccount.Is_EWOV_Assisted_Complaint__c = TRUE;
        customerBillingAccount.Status__c = 'Pending';
        customerBillingAccount.Balance__c = 20000;
        customerBillingAccount.Greater_3_Consecutive_Estimated_Reads__c = TRUE;
        customerBillingAccount.Role__c = 'Owner';
        customerBillingAccount.Payment_Plan_End_Date__c = system.today().addDays(5);
        customerBillingAccount.Recovery_Last_Action_Date__c = system.today().addDays(7);
        customerBillingAccount.Recovery_Path__c = 'Test';
        customerBillingAccount.Clerical__c = 'Test';
        insert customerBillingAccount;

        List<Classification_Code__c> classCodes = 	[	SELECT 		Id, Name, External_Id__c, Append_Comments__c,
        															Is_Active__c, Message__c, Customer_Care_Check_Type__c
        												FROM		Classification_Code__c
        												WHERE		Customer_Care_Check_Type__c <> '3 - Not checked'
        												ORDER BY 	Is_Active__c
        												LIMIT		10
        											];

		if (classCodes == null){
			classCodes = new List<Classification_Code__c>();
	        for (Integer i = 0; i < classificationCodes.size(); i++){
	        	Classification_Code__c cc = SObjectCreator.createClassificationCode();
	        	cc.Name = classificationCodes[i];
	        	cc.External_Id__c = classificationCodes[i];
	        	cc.Append_Comments__c = true;
	        	cc.End_Date__c = system.today().addMonths(1);
	        	cc.Is_Active__c = true;
	        	cc.Message__c = 'This is the message';
	        	cc.Customer_Care_Check_Type__c = '0 - Alert';
	        	classCodes.add(cc);
	        }
	        insert classCodes;
		}
        List<String> notCheckedCodeNames = new List<String>{'BD', 'AX', 'PE'};
        List<Classification_Code__c> notCheckedClassCodes = [	SELECT 		Id, Name, External_Id__c, Append_Comments__c,
        																	Is_Active__c, Message__c, Customer_Care_Check_Type__c
		        												FROM		Classification_Code__c
		        												WHERE	 	Is_Active__c = TRUE
		        													AND		Name IN :notCheckedCodeNames
		        												LIMIT		10
		        											];

		if (notCheckedClassCodes.size() == 0){
			notCheckedClassCodes = new List<Classification_Code__c>();
			for (String s : notCheckedCodeNames){
				Classification_Code__c cc = SObjectCreator.createClassificationCode();
				cc.Name = s;
				cc.External_Id__c = s;
				cc.Append_Comments__c = TRUE;
				cc.End_Date__c = system.today().addMonths(1);
				cc.Is_Active__c = TRUE;
				cc.Message__c = 'A Message';
				cc.Customer_Care_Check_Type__c = '3 - Not checked';
				notCheckedClassCodes.add(cc);
			}
			insert notCheckedClassCodes;
		}

        Set<Customer_Classification__c> custClasses_SET = new Set<Customer_Classification__c>();
        for (Integer i = 0; i < classCodes.size(); i++){
        	Customer_Classification__c cc = SObjectCreator.createCustomerClassification();
        	cc.Billing_Account__c = customerBillingAccount.Id;
        	cc.Customer__c = testCustomers[0].Id;
        	cc.Classification__c = classCodes[i].Id;
        	custClasses_SET.add(cc);
        }
        for (Classification_Code__c cc : notCheckedClassCodes){
        	Customer_Classification__c custClass = SObjectCreator.createCustomerClassification();
        	custClass.Billing_Account__c = customerBillingAccount.Id;
        	custClass.Customer__c = testCustomers[0].Id;
        	custClass.Classification__c = cc.Id;
        	if (cc.Name == 'BD'){
        		custClass.Reference__c = 'Dec2010-999.99';
        	}
        	custClasses_SET.add(custClass);
        }
        List<Customer_Classification__c> custClasses_LIST = new List<Customer_Classification__c>();
        custClasses_LIST.addAll(custClasses_SET);
        insert custClasses_LIST;


        Test.startTest();

        PageReference custVerifyPage = new PageReference('/CustomerVerificationPage?Id=' + testCustomers[0].Id + '&billAccId=' + customerBillingAccount.Id);
        Test.setCurrentPage(custVerifyPage);

        ApexPages.Standardcontroller controller = new ApexPages.Standardcontroller(nonResidentialCustomer1);
        CustomerVerificationExtension extension = new CustomerVerificationExtension(controller);



        extension.getAccountOptions();
        extension.getContactOptions();
        extension.getPhoneOptions();

        //extension.saveAndQuickNote();

        extension.selectedContact = 'Other';
        extension.updateContactDetails();

        extension.contactToDisplay.otherFirstName = 'TestFirst';
        extension.contactToDisplay.otherLastName = 'TestLast';
        extension.contactToDisplay.preferredPhoneNum = '123456';

        extension.refusedDetails = TRUE;
        extension.contactToDisplay.agentComments = 'Test Refused Details';

        extension.saveAndQuickNote();
        Test.stopTest();
	}

    static testMethod void CustomerVerificationFromAccount() {
        List<String> classificationCodes = new List<String>{'AA', 'HR', 'LD'};
        List<Account> testCustomers = new List<Account>();
        Account residentialCustomer1 = SObjectCreator.createAccountResidentialCustomer();
        residentialCustomer1.Is_EWOV_Investigative_Complaint__c = TRUE;
        residentialCustomer1.Is_Key_Customer__c = TRUE;
        testCustomers.add(residentialCustomer1);

        Account residentialCustomer2 = SObjectCreator.createAccountResidentialCustomer();
        testCustomers.add(residentialCustomer2);
        insert testCustomers;

        List<Contact> testContacts = new List<Contact>();
        Contact customerContact1 = SObjectCreator.createContact();
        customerContact1.AccountId = testCustomers[0].Id;
        testContacts.add(customerContact1);

        Contact customerContact2 = SObjectCreator.createContact();
        customerContact2.AccountId = testCustomers[0].Id;
        testContacts.add(customerContact2);

        Contact thirdPartyContact1 = SObjectCreator.createContact();
        thirdPartyContact1.AccountId = testCustomers[1].Id;
        testContacts.add(thirdPartyContact1);
        insert testContacts;

        Person_Customer_Relationship__c thirdPartyContactRelationship = SObjectCreator.createPersonCustomerRelationship();
        thirdPartyContactRelationship.Customer__c = testCustomers[0].Id;
        thirdPartyContactRelationship.Person__c = testContacts[2].Id;
        thirdPartyContactRelationship.Third_Party_Type__c = 'Third Party';
        insert thirdPartyContactRelationship;

        Property__c customerProperty = SObjectCreator.createProperty();
        customerProperty.R6_Avenview__c = TRUE;
        insert customerProperty;

        Billing_Account__c customerBillingAccount = SObjectCreator.createBillingAccountBillingAccount();
        customerBillingAccount.Customer__c = testCustomers[0].Id;
        customerBillingAccount.Property__c = customerProperty.Id;
        customerBillingAccount.Risk_Factor__c = 'H';
        customerBillingAccount.Is_EWOV_Assisted_Complaint__c = TRUE;
        customerBillingAccount.Status__c = 'Active';
        customerBillingAccount.Balance__c = 20000;
        customerBillingAccount.Greater_3_Consecutive_Estimated_Reads__c = TRUE;
        customerBillingAccount.Role__c = 'Owner';
        customerBillingAccount.Payment_Plan_End_Date__c = system.today().addDays(5);
        customerBillingAccount.Recovery_Last_Action_Date__c = system.today().addDays(7);
        customerBillingAccount.Recovery_Path__c = 'Test';
        customerBillingAccount.Clerical__c = 'Test';
        insert customerBillingAccount;

        List<Classification_Code__c> classCodes = 	[	SELECT 		Id, Name, External_Id__c, Append_Comments__c, End_Date__c,
        															Is_Active__c, Message__c, Customer_Care_Check_Type__c
        												FROM		Classification_Code__c
        												WHERE		Customer_Care_Check_Type__c <> '3 - Not checked'
        												ORDER BY 	Is_Active__c
        												LIMIT		10
        											];

		if (classCodes == null){
			classCodes = new List<Classification_Code__c>();
	        for (Integer i = 0; i < classificationCodes.size(); i++){
	        	Classification_Code__c cc = SObjectCreator.createClassificationCode();
	        	cc.Name = classificationCodes[i];
	        	cc.External_Id__c = classificationCodes[i];
	        	cc.Append_Comments__c = true;
	        	cc.End_Date__c = system.today().addMonths(1);
	        	cc.Is_Active__c = true;
	        	cc.Message__c = 'This is the message';
	        	cc.Customer_Care_Check_Type__c = '0 - Alert';
	        	classCodes.add(cc);
	        }
	        insert classCodes;
		}
        List<String> notCheckedCodeNames = new List<String>{'BD', 'AX', 'CL', 'PE'};
        List<Classification_Code__c> notCheckedClassCodes = [	SELECT 		Id, Name, External_Id__c, Append_Comments__c, End_Date__c,
        																	Is_Active__c, Message__c, Customer_Care_Check_Type__c
		        												FROM		Classification_Code__c
		        												WHERE	 	Is_Active__c = TRUE
		        													AND		Name IN :notCheckedCodeNames
		        												LIMIT		10
		        											];

		if (notCheckedClassCodes.size() == 0){
			notCheckedClassCodes = new List<Classification_Code__c>();
			for (String s : notCheckedCodeNames){
				Classification_Code__c cc = SObjectCreator.createClassificationCode();
				cc.Name = s;
				cc.External_Id__c = s;
				cc.Append_Comments__c = TRUE;
				cc.End_Date__c = system.today().addMonths(1);
				cc.Is_Active__c = TRUE;
				cc.Message__c = 'A Message';
				cc.Customer_Care_Check_Type__c = '3 - Not checked';
				notCheckedClassCodes.add(cc);
			}
			insert notCheckedClassCodes;
		}

        Set<Customer_Classification__c> custClasses_SET = new Set<Customer_Classification__c>();
        for (Integer i = 0; i < classCodes.size(); i++){
        	Customer_Classification__c cc = SObjectCreator.createCustomerClassification();
        	cc.Billing_Account__c = customerBillingAccount.Id;
        	cc.Customer__c = testCustomers[0].Id;
        	cc.Classification__c = classCodes[i].Id;
        	custClasses_SET.add(cc);
        }
        for (Classification_Code__c cc : notCheckedClassCodes){
        	Customer_Classification__c custClass = SObjectCreator.createCustomerClassification();
        	custClass.Billing_Account__c = customerBillingAccount.Id;
        	custClass.Customer__c = testCustomers[0].Id;
        	custClass.Classification__c = cc.Id;
        	if (cc.Name == 'BD'){
        		custClass.Reference__c = 'Dec2010-999.99';
        	}
        	custClasses_SET.add(custClass);
        }
        List<Customer_Classification__c> custClasses_LIST = new List<Customer_Classification__c>();
        custClasses_LIST.addAll(custClasses_SET);
        insert custClasses_LIST;

		Recovery_Path__c recoveryPathCustomSetting = SObjectCreator.createRecoveryPathCustomSetting();
        recoveryPathCustomSetting.Check_Type__c = '0 - Alert';
        recoveryPathCustomSetting.Short_Description__c = 'Test Short';
        recoveryPathCustomSetting.Message__c = 'Recovery Path Test Message';
        recoveryPathCustomSetting.Name = 'Test';
        insert recoveryPathCustomSetting;

        Clerical__c clericalCustomSetting = SObjectCreator.createClericalCustomSetting();
        clericalCustomSetting.Check_Type__c = '0 - Alert';
        clericalCustomSetting.Short_Description__c = 'Test Short';
        clericalCustomSetting.Message__c = 'Test Clerical Message';
        clericalCustomSetting.Name = 'Test';
        insert clericalCustomSetting;

        if (Bad_Debt__c.getInstance() == null){
        	Bad_Debt__c badDebtCustomSetting = SObjectCreator.createBadDebtCustomSetting();
        	badDebtCustomSetting.NumDays__c = 183;
        	badDebtCustomSetting.MinThreshold__c = 50;
        	badDebtCustomSetting.MaxThreshold__c = 200;
        	insert badDebtCustomSetting;
        }

        if (Budget__c.getInstance() == null){
        	Budget__c budgetCustomSetting = SObjectCreator.createBudgetCustomSetting();
        	budgetCustomSetting.AllowedArrears__c = 30;
        	budgetCustomSetting.ReviewDateThreshold__c = 42;
        	insert budgetCustomSetting;
        }


        Test.startTest();

        PageReference custVerifyPage = Page.CustomerVerificationPage;
        Test.setCurrentPage(custVerifyPage);

        ApexPages.Standardcontroller controller = new ApexPages.Standardcontroller(residentialCustomer1);
        CustomerVerificationExtension extension = new CustomerVerificationExtension(controller);
		Boolean otherContact = extension.otherContact;
        extension.getAccountOptions();
        extension.getContactOptions();
        extension.getPhoneOptions();

        extension.updateBillAccountDetails();
        extension.selectedBillAccount = customerBillingAccount.Id;
        extension.updateBillAccountDetails();

        extension.updateContactDetails();
        extension.selectedContact = customerContact1.Id;
        extension.updateContactDetails();

        extension.selectedPhoneType = 'Work';
        extension.contactToDisplay.preferredPhoneNum = '123465';

        extension.saveAndClose();

        Test.stopTest();
    }

}