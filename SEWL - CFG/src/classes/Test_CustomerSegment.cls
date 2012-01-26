/*
    Type:       Test Class
    Purpose:    
				Performs Testing for Customer Segmentation

    ---------------------------------------------------------------
    History:

*/
@isTest
private class Test_CustomerSegment {
    
    private static testMethod void CustomerSegmentTest(){
        // setup a dummy segment usage quartile if necessary
        if (Segment_Usage_Quartile__c.getAll().values().isEmpty()) {
            Segment_Usage_Quartile__c q = new Segment_Usage_Quartile__c();
            q.Name = 'RES-LOW99';
            q.Quartile__c = '9 - Low';
            q.Lower_Bound_KL_day__c = -999999999;
            q.Upper_Bound_KL_day__c = Decimal.valueOf('9999999999.99'); 
            q.Type__c = 'Residential';
            insert q;
        }
                
        // Delete all the existing segments and questions for data independence
        DeleteSegmentsAndQuestions();
        CreateSegmentsAndQuestions();

        // Create the account, property and billing acct                
        RecordType rt1 = [Select Name, Id, DeveloperName 
                                From RecordType 
                                where sObjectType='Account' 
                                and isActive=true and Name like 'Residential%' LIMIT 1];
                
        Account acc1 = new Account();           
        acc1.Name = 'testAcc1';
        acc1.Q1_Is_your_property_a_house_or_a_unit_a__c = '0 - Unit';
        acc1.Q4_How_much_household_protect__c = '0 - Never';

        //rt1 must be found
        if(rt1 != NULL) {
                acc1.RecordTypeId = rt1.Id;
                acc1.RecordType = rt1;
        }
                
        insert acc1;
        
        system.debug('***acc1***' + acc1);

        Contact con1 = new Contact();
        con1.LastName = 'Foo';
        con1.Birthdate = System.today().addDays(-50000);
        con1.AccountId = acc1.id;
        con1.Primary_Secondary_Contact__c = 'Primary Contact';
        insert con1;

        Property__c testProperty = SObjectCreator.createProperty();
        insert testProperty;
        
        Billing_Account__c testBillingAccount = SObjectCreator.createBillingAccountBillingAccount();
        testBillingAccount.Customer__c = acc1.Id;
        testBillingAccount.Property__c = testProperty.Id;
        insert testBillingAccount;

        Consumption_and_Charge__c charge = new Consumption_and_Charge__c();
        charge.Water_Cost__c = 123.45;
        charge.Water_Volume__c = 123423.34;
        charge.Trade_Waste_Cost__c = 234234.32;
        charge.Sewage_Disposal_Cost__c = 3424232.34;
        charge.Billing_Account__c = testBillingAccount.id;
        charge.Name = 'Jan-Mar 2010';
        charge.Financial_Year__c = '2009/10';
        charge.Number_of_Days__c = 120;
        insert charge;
        charge = new Consumption_and_Charge__c();
        charge.Water_Cost__c = 123.45;
        charge.Water_Volume__c = 123423.34;
        charge.Trade_Waste_Cost__c = 234234.32;
        charge.Sewage_Disposal_Cost__c = 3424232.34;
        charge.Billing_Account__c = testBillingAccount.id;
        charge.Name = 'Jan-Mar 2009';
        charge.Financial_Year__c = '2008/09';
        charge.Number_of_Days__c = 120;
        insert charge;
                
        PageReference pageRef = Page.CustomerSegmentEntry;
        Test.setCurrentPageReference(pageRef);
        System.currentPageReference().getParameters().put('id',acc1.id);
       
        ApexPages.StandardController stdCon = new ApexPages.standardController(acc1);  
        CustomerSegmentEntryController controller = new CustomerSegmentEntryController(stdCon);
        //CustomerSegmentEntryController.questionAndAnswer QAlist = new CustomerSegmentEntryController.questionAndAnswer(q1,acc1); 
        //List<SelectOption> answerList = QAlist.answerList;
        
        //System.debug(controller.questionAndAnswers[0].answer);
        
        // Test questions and answers
        List<CustomerSegmentEntryController.QuestionAndAnswer> qaList = controller.questionAndAnswers;
        System.debug('###QALIST');
        System.debug(qaList);
        System.debug(qaList[0].answer);
                
        // First save
        controller.save();
        system.debug('###SEGMENTRESULT');
        system.debug([select segment__r.name from account where id=:acc1.id][0].segment__r.name);
                
        // Second save
        Account acct = (Account)stdCon.getRecord();
        acct.Q1_Is_your_property_a_house_or_a_unit_a__c = '1 - House';
        controller.save();

        system.debug('###SEGMENTRESULT2');
        system.debug([select segment__r.name from account where id=:acc1.id][0].segment__r.name);
                
        //CustomerSegmentEntryController controllerNull = new CustomerSegmentEntryController(null);              
        //controllerNull.save();
        
        // test batch
        List<Account> testcustomers = new List<Account>();
        testcustomers.add(acc1);
        RefreshCustomerSegment_BATCH batch = new RefreshCustomerSegment_BATCH();
        batch.testCustomers = testcustomers;
        
        Test.StartTest();
        ID batchprocessid = Database.executeBatch(batch );
        Test.StopTest();          
    }

    private static testMethod void CustomerSegmentTWTest(){
		// trade waste testing

        // setup a dummy segment usage quartile if necessary
        if (Segment_Usage_Quartile__c.getAll().values().isEmpty()) {
            Segment_Usage_Quartile__c q = new Segment_Usage_Quartile__c();
            q.Name = 'RES-LOW99';
            q.Quartile__c = '9 - Low';
            q.Lower_Bound_KL_day__c = -999999999;
            q.Upper_Bound_KL_day__c = Decimal.valueOf('9999999999.99'); 
            q.Type__c = 'Residential';
            insert q;
        }
                
        // Delete all the existing segments and questions for data independence
        DeleteSegmentsAndQuestions();
        CreateSegmentsAndQuestions();

        // Create the account, property and billing acct                
        RecordType rt1 = [Select Name, Id, DeveloperName 
                                From RecordType 
                                where sObjectType='Account' 
                                and isActive=true and Name like 'Residential%' LIMIT 1];
                
        Account acc1 = new Account();           
        acc1.Name = 'testAcc1';
        acc1.Q1_Is_your_property_a_house_or_a_unit_a__c = '0 - Unit';
        acc1.Q4_How_much_household_protect__c = '0 - Never';

        //rt1 must be found
        if(rt1 != NULL) {
                acc1.RecordTypeId = rt1.Id;
                acc1.RecordType = rt1;
        }
                
        insert acc1;

        Contact con1 = new Contact();
        con1.LastName = 'Foo';
        con1.Birthdate = System.today().addDays(-50000);
        con1.AccountId = acc1.id;
        con1.Primary_Secondary_Contact__c = 'Primary Contact';
        insert con1;

        Property__c testProperty = SObjectCreator.createProperty();
        insert testProperty;
        
        Billing_Account__c testBillingAccount = SObjectCreator.createBillingAccountBillingAccount();
        testBillingAccount.Customer__c = acc1.Id;
        testBillingAccount.Property__c = testProperty.Id;
        testBillingAccount.Role__c = 'Other';
        testBillingAccount.Status__c = 'Active';
        insert testBillingAccount;

		Service__c svc = new Service__c();
		svc.Billing_Account__c = testBillingAccount.Id;
		svc.Name = 'XYZ';
		svc.Tariff__c = 'TW1';
		insert svc;
		
		SegmentUtil.PopulateUsageQuartiles(new Account[]{acc1});
         
    }

        
    private static void DeleteSegmentsAndQuestions() {
        List<Segment__c> segmentsToDelete = new List<Segment__c>();
        List<Question__c> questionsToDelete = new List<Question__c>();
                
        for (Segment__c s : [select id from Segment__c]) {
                segmentsToDelete.add(s);
        }
                
        delete segmentsToDelete;

        for (Question__c q : [select id from Question__c]) {
                questionsToDelete.add(q);
        }
                
        delete questionsToDelete;
    }

    private static void CreateSegmentsAndQuestions() {
        Segment__c segment1 = new Segment__c();
        segment1.Name = 'Oldies';
        segment1.Intercept__c = -600;
        segment1.Code__c = 'TEST-OLD';
        segment1.Type__c = 'Residential';
        segment1.Background_Colour__c = 'FFFFFF';
        segment1.Text_Colour__c = '000000';
                
        insert segment1;

        Segment__c segment2 = new Segment__c();
        segment2.Name = 'Youngies';
        segment2.Intercept__c = 0;
        segment2.Code__c = 'TEST-YNG';
        segment2.Type__c = 'Residential';
        segment2.Background_Colour__c = 'FFFFFF';
        segment2.Text_Colour__c = '000000';
        insert segment2;

        Segment__c segment1_1 = new Segment__c();
        segment1_1.Name = 'Oldies, High';
        segment1_1.Intercept__c = -50;
        segment1_1.Code__c = 'TEST-OLDHIGH';
        segment1_1.Type__c = 'Residential';
        segment1_1.Parent_Segment__c = segment1.id;
        segment1_1.Background_Colour__c = 'FFFFFF';
        segment1_1.Text_Colour__c = '000000';
        insert segment1_1;              

        Segment__c segment1_2 = new Segment__c();
        segment1_2.Name = 'Oldies, LOW';
        segment1_2.Intercept__c = 0;
        segment1_2.Code__c = 'TEST-OLDLOW';
        segment1_2.Type__c = 'Residential';
        segment1_2.Parent_Segment__c = segment1.id;
        segment1_2.Background_Colour__c = 'FFFFFF';
        segment1_2.Text_Colour__c = '000000';
                
        insert segment1_2;      

        Segment__c segment2_1 = new Segment__c();
        segment2_1.Name = 'Youngies, High';
        segment2_1.Intercept__c = -50;
        segment2_1.Code__c = 'TEST-YNGHIGH';
        segment2_1.Type__c = 'Residential';
        segment2_1.Parent_Segment__c = segment2.id;
        segment2_1.Background_Colour__c = 'FFFFFF';
        segment2_1.Text_Colour__c = '000000';
                
        insert segment2_1;              

        Segment__c segment2_2 = new Segment__c();
        segment2_2.Name = 'Youngies, LOW';
        segment2_2.Intercept__c = 0;
        segment2_2.Code__c = 'TEST-YNGLOW';
        segment2_2.Type__c = 'Residential';
        segment2_2.Parent_Segment__c = segment2.id;
        segment2_2.Background_Colour__c = 'FFFFFF';
        segment2_2.Text_Colour__c = '000000';
                                
        insert segment2_2;      
                
                
        Question__c question1 = new Question__c();
        question1.Active__c = true;
        question1.API_Field__c = 'Q1_Is_your_property_a_house_or_a_unit_a__c';
        question1.Code__c = 'Q1';
        question1.Internal_Visible__c = true;
        question1.Portal_Visible__c = true;
        question1.Question__c  = 'House or Unit?';
        question1.Type__c = 'Residential';
        insert question1;

        Question__c question2 = new Question__c();
        question2.Active__c = true;
        question2.API_Field__c = 'Q4_How_much_household_protect__c';
        question2.Code__c = 'Q2';
        question2.Internal_Visible__c = true;
        question2.Portal_Visible__c = true;
        question2.Question__c  = 'Do I like the environment?';
        question2.Type__c = 'Residential';
        insert question2;
                
        Segment_Question__c segQuestionS1_Q1 = new Segment_Question__c();
        segQuestionS1_Q1.Customer_Segment__c = segment1.id;
        segQuestionS1_Q1.Question__c = question1.id;
        segQuestionS1_Q1.Weight__c = 601;
        insert segQuestionS1_Q1;

        Segment_Question__c segQuestionS2_Q1 = new Segment_Question__c();
        segQuestionS2_Q1.Customer_Segment__c = segment2.id;
        segQuestionS2_Q1.Question__c = question1.id;
        segQuestionS2_Q1.Weight__c = 0; 
        insert segQuestionS2_Q1;        

        Segment_Question__c segQuestionS1_1_Q2 = new Segment_Question__c();
        segQuestionS1_1_Q2.Customer_Segment__c = segment1_1.id;
        segQuestionS1_1_Q2.Question__c = question2.id;
        segQuestionS1_1_Q2.Weight__c = 0;
        insert segQuestionS1_1_Q2;

        Segment_Question__c segQuestionS1_2_Q2 = new Segment_Question__c();
        segQuestionS1_2_Q2.Customer_Segment__c = segment1_2.id;
        segQuestionS1_2_Q2.Question__c = question2.id;
        segQuestionS1_2_Q2.Weight__c = 51;
        insert segQuestionS1_2_Q2;

        Segment_Question__c segQuestionS2_1_Q2 = new Segment_Question__c();
        segQuestionS2_1_Q2.Customer_Segment__c = segment2_1.id;
        segQuestionS2_1_Q2.Question__c = question2.id;
        segQuestionS2_1_Q2.Weight__c = 0;
        insert segQuestionS2_1_Q2;

        Segment_Question__c segQuestionS2_2_Q2 = new Segment_Question__c();
        segQuestionS2_2_Q2.Customer_Segment__c = segment2_2.id;
        segQuestionS2_2_Q2.Question__c = question2.id;
        segQuestionS2_2_Q2.Weight__c = 51;
        insert segQuestionS2_2_Q2;
                
    }
}