/**
 * Apex code is a strongly-typed, object-oriented programming language that allows developers to execute flow and
 * transaction control statements on the Force.com platform server in conjunction with calls to the Force.com API.
 * It has a syntax that will be familiar to Java and C# programmers and has the usual array of features such as classes,
 * interfaces, constants, class variables, and annotations.
 *
 * <Project>South East Water Limited - TestMethod Helper</Project>
 * <Title>SObjectCreator</Title>
 *
 * <Description>
 *  This class creates sObjects to be used in YOUR testMethods.
 *  It should be updated to include the custom sObjects needed for YOUR testMethods.
 *  Existing testMethods in this class may fail due to custom validation rules or required custom fields.
 *  These, if required, should be updated so that it can be successfully inserted to the database.
 *
 *  The sObjects created here have the bare minimum of fields needed to be inserted.
 *  Additional fields required for your testMethods should be added to in YOUR testMethods, not here.
 *  Any relationships including RecordTypes should be added to in YOUR testMethods, not here.
 *  There should be no DML or SOQL in the code here, only in the testMethods.
 *  Object with RecordType should be specified, otherwise they are default which is bad practice.
 *  All class should always have 100% code coverage.
 * </Description>
 *
 * <Organization>South East Water Limited<Organization>
 * <ClassName>SObjectCreator<ClassName>
 * <ApiVersion>22.0<ApiVersion>
 * <CreatedBy>Gareth Knight<CreatedBy>
 * <CreatedDate>Tue, 13/09/2011<CreatedDate>
 *
 * <Changes>
 *  <Author></Author>
 *  <Date></Date>
 *  <Description>
 *
 *  </Description>
 * </Changes>
 */

public with sharing class SObjectCreator {

    //******************************************************************************************
    //                          Set up for Test Methods
    //******************************************************************************************
    // <Get all required RecordTypes>
    static{
        getRecordTypeIds();
    }

    private static Id RecordTypeAccountResidentialId;
    private static Id RecordTypeAccountNonResidentialCompanyId;
    private static Id RecordTypeAccountNonResidentialIndividualId;
    private static Id RecordTypeBillingAccountGroupBillingAccountId;
    private static Id RecordTypeBillingAccountBillingAccountId;
    private static Id RecordTypeBillingAccountAdHocId;
    private static Id RecordTypeCaseConcessionId;
    private static Id RecordTypeCaseConcessionDeleteId;
    private static Id RecordTypeCaseGeneralEnquiryId;
    private static Id RecordTypeCaseInfoStatementUpdateId;
    private static Id RecordTypeCaseNoticeOfSaleId;
    private static Id RecordTypeCaseSpecialMeterReadId;
    private static Id RecordTypeCaseSuspendRecoveryId;
    private static Id RecordTypeCaseTakeCustomerMeterReadId;
    private static Id RecordTypeCaseWebId;


    private static void getRecordTypeIds(){
        List<RecordType> RecordType_List = [SELECT r.SobjectType, r.DeveloperName FROM RecordType r
            WHERE (
                (r.SobjectType = 'Account' AND r.DeveloperName = 'Residential') OR
                (r.SobjectType = 'Account' AND r.DeveloperName = 'Non_Residential_Company_Customer') OR
                (r.SobjectType = 'Account' AND r.DeveloperName = 'Non_Residential_Individual_Customer') OR
                (r.SobjectType = 'Billing_Account__c' AND r.DeveloperName = 'Ad_Hoc') OR
                (r.SobjectType = 'Billing_Account__c' AND r.DeveloperName = 'Group_Billing_Account') OR
                (r.SobjectType = 'Billing_Account__c' AND r.DeveloperName = 'Billing_Account') OR
                (r.SobjectType = 'Case' AND r.DeveloperName = 'Concession') OR
                (r.SobjectType = 'Case' AND r.DeveloperName = 'Concession_Delete') OR
                (r.SobjectType = 'Case' AND r.DeveloperName = 'General_Enquiry') OR
                (r.SobjectType = 'Case' AND r.DeveloperName = 'Information_Statement_Update') OR
                (r.SobjectType = 'Case' AND r.DeveloperName = 'Notice_of_Sale') OR
                (r.SobjectType = 'Case' AND r.DeveloperName = 'Special_Meter_Read') OR
                (r.SobjectType = 'Case' AND r.DeveloperName = 'Suspend_Recovery') OR
                (r.SobjectType = 'Case' AND r.DeveloperName = 'Take_Customer_Meter_Read') OR
                (r.SobjectType = 'Case' AND r.DeveloperName = 'Web')

            ) AND r.IsActive=true];
        for(RecordType r : RecordType_List){
            if(r.SobjectType=='Account' && r.DeveloperName=='Residential'){
                RecordTypeAccountResidentialId = r.Id;
            }
            else if(r.SobjectType=='Account' && r.DeveloperName=='Non_Residential_Company_Customer'){
                RecordTypeAccountNonResidentialCompanyId = r.Id;
            }
            else if(r.SobjectType=='Account' && r.DeveloperName=='Non_Residential_Individual_Customer'){
                RecordTypeAccountNonResidentialIndividualId = r.Id;
            }
            else if(r.SobjectType=='Billing_Account__c' && r.DeveloperName=='Ad_Hoc'){
                RecordTypeBillingAccountAdHocId = r.Id;
            }
            else if(r.SobjectType=='Billing_Account__c' && r.DeveloperName=='Billing_Account'){
                RecordTypeBillingAccountBillingAccountId = r.Id;
            }
            else if(r.SobjectType=='Billing_Account__c' && r.DeveloperName=='Group_Billing_Account'){
                RecordTypeBillingAccountGroupBillingAccountId = r.Id;
            }
            else if (r.SobjectType == 'Case' && r.DeveloperName == 'Concession'){
                RecordTypeCaseConcessionId = r.Id;
            }
            else if (r.SobjectType == 'Case' && r.DeveloperName == 'Concession_Delete'){
                RecordTypeCaseConcessionDeleteId = r.Id;
            }
            else if (r.SobjectType == 'Case' && r.DeveloperName == 'General_Enquiry'){
                RecordTypeCaseGeneralEnquiryId = r.Id;
            }
            else if (r.SobjectType == 'Case' && r.DeveloperName == 'Information_Statement_Update'){
                RecordTypeCaseInfoStatementUpdateId = r.Id;
            }
            else if (r.SobjectType == 'Case' && r.DeveloperName == 'Notice_of_Sale'){
                RecordTypeCaseNoticeOfSaleId = r.Id;
            }
            else if (r.SobjectType == 'Case' && r.DeveloperName == 'Special_Meter_Read'){
                RecordTypeCaseSpecialMeterReadId = r.Id;
            }
            else if (r.SobjectType == 'Case' && r.DeveloperName == 'Suspend_Recovery'){
                RecordTypeCaseSuspendRecoveryId = r.Id;
            }
            else if (r.SobjectType == 'Case' && r.DeveloperName == 'Take_Customer_Meter_Read'){
                RecordTypeCaseTakeCustomerMeterReadId = r.Id;
            }
            else if (r.SobjectType == 'Case' && r.DeveloperName == 'Web'){
                RecordTypeCaseWebId = r.Id;
            }
        }
    }
    //*/// </Get all required RecordTypes>

    //******************************************************************************************
    //                     Standard Object and RecordTypes Creation
    //******************************************************************************************

    // <Create AccountResidentialCustomer>
    public static Account createAccountResidentialCustomer(){
        Account AccountResidentialCustomerObject = new Account();
        AccountResidentialCustomerObject.Name = 'Test Account Residential Customer';
        AccountResidentialCustomerObject.RecordTypeId = RecordTypeAccountResidentialId;
        return AccountResidentialCustomerObject;
    }
    public static testMethod void testInsertAccountResidentialCustomer(){
        Account AccountResidentialCustomerObject = SObjectCreator.createAccountResidentialCustomer();
        //## Required Relationships

        //## Additional fields and relationships / Updated fields
        insert AccountResidentialCustomerObject;
    }
    //*/// </Create AccountResidentialCustomer>

    // <Create AccountNonResidentialIndividual>
    public static Account createAccountNonResidentialIndividual(){
        Account AccountNonResidentialIndividualObject = new Account();
        AccountNonResidentialIndividualObject.Name = 'Test Account Non-Residential Individual';
        AccountNonResidentialIndividualObject.RecordTypeId = RecordTypeAccountNonResidentialIndividualId;
        return AccountNonResidentialIndividualObject;
    }
    public static testMethod void testInsertAccountNonResidentialIndividual(){
        Account AccountNonResidentialIndividualObject = SObjectCreator.createAccountNonResidentialIndividual();
        //## Required Relationships

        //## Additional fields and relationships / Updated fields
        insert AccountNonResidentialIndividualObject;
    }
    //*/// </Create AccountNonResidentialIndividual>

    // <Create AccountNonResidentialCompany>
    public static Account createAccountNonResidentialCompany(){
        Account AccountNonResidentialCompanyObject = new Account();
        AccountNonResidentialCompanyObject.Name = 'Test Account Non-Residential Company';
        AccountNonResidentialCompanyObject.RecordTypeId = RecordTypeAccountNonResidentialCompanyId;
        return AccountNonResidentialCompanyObject;
    }
    public static testMethod void testInsertAccountNonResidentialCompany(){
        Account AccountNonResidentialCompanyObject = SObjectCreator.createAccountNonResidentialCompany();
        //## Required Relationships

        //## Additional fields and relationships / Updated fields
        insert AccountNonResidentialCompanyObject;
    }
    //*/// </Create AccountNonResidentialCompany>

    // <Create Contact>
    public static Contact createContact(){
        Contact ContactObject = new Contact();
        ContactObject.FirstName = 'TestFirstName';
        ContactObject.LastName = 'TestLastName';
        ContactObject.Title = 'TestTitle';
        ContactObject.Phone = '021123456';
        ContactObject.Email = 'testEmail@testEmail.com';
        return ContactObject;
    }

    public static testMethod void testInsertContact(){
        Contact ContactObject = SObjectCreator.createContact();
        Account AccountResidentialCustomerObject = SObjectCreator.createAccountResidentialCustomer();
        insert AccountResidentialCustomerObject;
        ContactObject.AccountId = AccountResidentialCustomerObject.Id;
        insert ContactObject;
    }
    //*/// </Create Contact>

    // <Create BillingAccountAdhoc>
    public static Billing_Account__c createBillingAccountAdHoc(){
        Billing_Account__c BillingAccountAdHocObject = new Billing_Account__c();
        BillingAccountAdhocObject.Name = 'Test AdHoc Account #';
        BillingAccountAdHocObject.RecordTypeId = RecordTypeBillingAccountAdHocId;
        return BillingAccountAdhocObject;
    }
    public static testMethod void testInsertBillingAccountAdhoc(){
        Billing_Account__c BillingAccountAdHocObject = SObjectCreator.createBillingAccountAdHoc();
        //## Required Relationships
        Account AccountResidentialCustomerObject = SObjectCreator.createAccountResidentialCustomer();
        insert AccountResidentialCustomerObject;
        BillingAccountAdHocObject.Customer__c = AccountResidentialCustomerObject.Id;
        insert BillingAccountAdHocObject;
    }
    //*/// </Create BillingAccountAdHoc>

    // <Create BillingAccountAdhoc>
    public static Billing_Account__c createBillingAccountBillingAccount(){
        Billing_Account__c BillingAccountBillingAccountObject = new Billing_Account__c();
        BillingAccountBillingAccountObject.Name = 'Test Billing Account #';
        BillingAccountBillingAccountObject.RecordTypeId = RecordTypeBillingAccountBillingAccountId;
        return BillingAccountBillingAccountObject;
    }
    public static testMethod void testInsertBillingAccountBillingAccount(){
        Billing_Account__c BillingAccountBillingAccountObject = SObjectCreator.createBillingAccountBillingAccount();
        //## Required Relationships
        Account AccountResidentialCustomerObject = SObjectCreator.createAccountResidentialCustomer();
        insert AccountResidentialCustomerObject;
        BillingAccountBillingAccountObject.Customer__c = AccountResidentialCustomerObject.Id;
        insert BillingAccountBillingAccountObject;
    }
    //*/// </Create BillingAccountBillingAccount>

    // <Create BillingAccountAdhoc>
    public static Billing_Account__c createBillingAccountGroupBillingAccount(){
        Billing_Account__c BillingAccountGroupBillingAccountObject = new Billing_Account__c();
        BillingAccountGroupBillingAccountObject.Name = 'Test Group Billing Account #';
        BillingAccountGroupBillingAccountObject.RecordTypeId = RecordTypeBillingAccountGroupBillingAccountId;
        return BillingAccountGroupBillingAccountObject;
    }
    public static testMethod void testInsertBillingAccountGroupBillingAccount(){
        Billing_Account__c BillingAccountGroupBillingAccountObject = SObjectCreator.createBillingAccountGroupBillingAccount();
        //## Required Relationships
        Account AccountResidentialCustomerObject = SObjectCreator.createAccountResidentialCustomer();
        insert AccountResidentialCustomerObject;
        BillingAccountGroupBillingAccountObject.Customer__c = AccountResidentialCustomerObject.Id;
        insert BillingAccountGroupBillingAccountObject;
    }
    //*/// </Create BillingAccountGroupBillingAccount>

    // <Create Property>
    public static Property__c createProperty(){
        Property__c PropertyObject = new Property__c();
        PropertyObject.Name = 'TestProperty';
        PropertyObject.Universal_Id_c__c = 'asdflkj';
        PropertyObject.CIS_Property_Id__c = '01A/00000/0';
        return PropertyObject;
    }

    public static testMethod void testInsertProperty(){
        Property__c PropertyObject = SObjectCreator.createProperty();
        insert PropertyObject;
    }
    //*/// </Create Property>

    // <Create CaseInfoStatementUpdate>
    public static Case createCaseInfoStatementUpdate(){
        Case CaseInfoStatementUpdateObject = new Case();
        CaseInfoStatementUpdateObject.RecordTypeId = RecordTypeCaseInfoStatementUpdateId;
        CaseInfoStatementUpdateObject.Status = 'New';
        return CaseInfoStatementUpdateObject;
    }

    public static testMethod void testInsertCaseInfoStatementUpdate(){
        Case CaseInfoStatementUpdateObject = SObjectCreator.createCaseInfoStatementUpdate();
        //## Required Relationships
        Account AccountResidentialCustomerObject = SObjectCreator.createAccountResidentialCustomer();
        insert AccountResidentialCustomerObject;
        Billing_Account__c BillingAccountBillingAccountObject = SObjectCreator.createBillingAccountBillingAccount();
        BillingAccountBillingAccountObject.Customer__c = AccountResidentialCustomerObject.Id;
        insert BillingAccountBillingAccountObject;
        CaseInfoStatementUpdateObject.AccountId = AccountResidentialCustomerObject.Id;
        CaseInfoStatementUpdateObject.Billing_Account__c = BillingAccountBillingAccountObject.Id;
        insert CaseInfoStatementUpdateObject;
    }
    //*/// </Create CaseInfoStatementUpdate>

    // <Create Notice of Sale case>
    public static Case createCaseNoticeOfSale(){
        Case CaseNoticeOfSaleObject = new Case();
        CaseNoticeOfSaleObject.RecordTypeId = RecordTypeCaseNoticeOfSaleId;
        CaseNoticeOfSaleObject.Status = 'New';
        return CaseNoticeOfSaleObject;
    }

    public static testMethod void testInsertCaseNoticeOfSale(){
        Case CaseNoticeOfSaleObject = SObjectCreator.createCaseNoticeOfSale();
        Account AccountResidentialCustomerObject = SObjectCreator.createAccountResidentialCustomer();
        insert AccountResidentialCustomerObject;
        Billing_Account__c BillingAccountBillingAccountObject = SObjectCreator.createBillingAccountBillingAccount();
        BillingAccountBillingAccountObject.Customer__c = AccountResidentialCustomerObject.Id;
        insert BillingAccountBillingAccountObject;
        CaseNoticeOfSaleObject.AccountId = AccountResidentialCustomerObject.Id;
        CaseNoticeOfSaleObject.Billing_Account__c = BillingAccountBillingAccountObject.Id;
        insert CaseNoticeOfSaleObject;
    }
    //*/// </Create Notice of Sale case>

    // <CreateClassificationCode>
    public static Classification_Code__c createClassificationCode(){
        Classification_Code__c ClassificationCodeObject = new Classification_Code__c();
        ClassificationCodeObject.Name = 'ZZ';
        ClassificationCodeObject.Short_Description__c = 'A test description';
        return ClassificationCodeObject;
    }

    public static testMethod void testInsertClassificationCode(){
        Classification_Code__c ClassificationCodeObject = SObjectCreator.createClassificationCode();
        insert ClassificationCodeObject;
    }
    //*/// </CreateClassificationCode>

    // <CreateCustomerClassification>
    public static Customer_Classification__c createCustomerClassification(){
        Customer_Classification__c CustomerClassificationObject = new Customer_Classification__c();
        return CustomerClassificationObject;
    }

    public static testMethod void testInsertCustomerClassification(){
        Customer_Classification__c CustomerClassificationObject = SObjectCreator.createCustomerClassification();

        Account AccountResidentialCustomerObject = SObjectCreator.createAccountResidentialCustomer();
        insert AccountResidentialCustomerObject;

        Classification_Code__c ClassificationCodeObject = SObjectCreator.createClassificationCode();
        insert ClassificationCodeObject;

        CustomerClassificationObject.Customer__c = AccountResidentialCustomerObject.Id;
        CustomerClassificationObject.Classification__c = ClassificationCodeObject.Id;
        insert CustomerClassificationObject;
    }
    //*/// </CreateCustomerClassification>

    // <CreatePersonCustomerRelationship >
    public static Person_Customer_Relationship__c createPersonCustomerRelationship(){
        Person_Customer_Relationship__c PersonCustomerRelationshipObject = new Person_Customer_Relationship__c();
        return PersonCustomerRelationshipObject;
    }

    public static testMethod void testInsertPersonCustomerRelationship(){
        Account AccountResidentialObject1 = SObjectCreator.createAccountResidentialCustomer();
        insert AccountResidentialObject1;

        Account AccountResidentialObject2 = SObjectCreator.createAccountResidentialCustomer();
        insert AccountResidentialObject2;

        Contact ContactObject = SObjectCreator.createContact();
        ContactObject.AccountId = AccountResidentialObject1.Id;
        insert ContactObject;

        Person_Customer_Relationship__c PersonCustomerRelationshipObject = SObjectCreator.createPersonCustomerRelationship();
        PersonCustomerRelationshipObject.Customer__c = AccountResidentialObject2.Id;
        PersonCustomerRelationshipObject.Person__c = ContactObject.Id;
        PersonCustomerRelationshipObject.Third_Party_Type__c = 'Third Party';
        insert PersonCustomerRelationshipObject;
    }
    //*/// </CreatePersonCustomerRelationship>

    // <CreateBadDebt>
    public Static Bad_Debt__c createBadDebtCustomSetting(){
        Bad_Debt__c BadDebtCustomSetting = new Bad_Debt__c();
        BadDebtCustomSetting.Name = 'Test';
        return BadDebtCustomSetting;
    }

    public static testMethod void testInsertBadDebtCustomSetting(){
        Bad_Debt__c BadDebtCustomSetting = SObjectCreator.createBadDebtCustomSetting();
        BadDebtCustomSetting.MaxThreshold__c = 200;
        BadDebtCustomSetting.MinThreshold__c = 50;
        BadDebtCustomSetting.NumDays__c = 183;
        try {
            insert BadDebtCustomSetting;
        } catch (Exception e) {}
    }
    //*/// </CreateBadDebt>

    // <CreateRecoveryPath>
    public static Recovery_Path__c createRecoveryPathCustomSetting(){
        Recovery_Path__c RecoveryPathCustomSetting = new Recovery_Path__c();
        RecoveryPathCustomSetting.Name = 'Test';
        return RecoveryPathCustomSetting;
    }

    public static testMethod void testInsertRecoveryPathCustomSetting(){
        Recovery_Path__c RecoveryPathCustomSetting = SObjectCreator.createRecoveryPathCustomSetting();
        RecoveryPathCustomSetting.Short_Description__c = 'Test Short';
        RecoveryPathCustomSetting.Message__c = 'Test Message';
        RecoveryPathCustomSetting.Check_Type__c = '0 - Alert';
        insert RecoveryPathCustomSetting;
    }
    //*/// </CreateRecoveryPath>

    // <CreateClerical>
    public static Clerical__c createClericalCustomSetting(){
        Clerical__c ClericalCustomSetting = new Clerical__c();
        ClericalCustomSetting.Name = 'test';
        return ClericalCustomSetting;
    }

    public static testMethod void testInsertClericalCustomSetting(){
        Clerical__c ClericalCustomSetting = SObjectCreator.createClericalCustomSetting();
        ClericalCustomSetting.Message__c = 'Test Message';
        ClericalCustomSetting.Short_Description__c = 'Test Short';
        ClericalCustomSetting.Check_Type__c = '0 - Alert';
        insert ClericalCustomSetting;
    }
    //*/// </CreateClerical>

    // <CreateBudget>
    public static Budget__c createBudgetCustomSetting(){
        Budget__c BudgetCustomSetting = new Budget__c();
        return BudgetCustomSetting;
    }

    public static testMethod void testInsertBudgetCustomSetting(){
        Budget__c BudgetCustomSetting = SObjectCreator.createBudgetCustomSetting();
        BudgetCustomSetting.AllowedArrears__c = 30;
        BudgetCustomSetting.ReviewDateThreshold__c = 42;
        try {
            insert BudgetCustomSetting;
        } catch (Exception e) {}
    }
}