public without sharing class WaterMAP_Pg1_Introduction_Controller {

/*
    Type:       Controller Extension
    Purpose:    Controller to display the cover page of the WaterMAP portal

    Used By:    WaterMAP_Pg1_Introduction_Page VF Page
    ---------------------------------------------------------------
    History:

    02-Feb-2011 D.Thong (Salesforce)    Created

*/

    public WaterMAP_Submission__c waterMAPSub {get; set;}

    public WaterMAP_Pg1_Introduction_Controller(ApexPages.StandardController controller) {
        waterMapSub = (WaterMAP_Submission__c) controller.getRecord();
    }
    public PageReference Next() {
        // navigate to the next page
        PageReference nextPage = Page.WaterMAP_Pg2_Company_Site_Info_Page;
        nextPage.setRedirect(true);
        nextPage.getParameters().put('id', waterMapSub.id);

        return nextPage;
    }
    
    public static testmethod void TestMe() {
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

        Watermap__c waterMap = new Watermap__c();
        waterMap.Name = 'Test Me';
        waterMap.Customer__c = account.id;
        waterMap.Status__c = 'Not Started';
        insert waterMap;

        WaterMAP_Submission__c waterMapSub = new WaterMAP_Submission__c();
        waterMapSub.Customer__c = account.id;
        waterMapSub.Prepared_By__c = contact.id;
        waterMapSub.Prepared_By__r = contact;
        waterMapSub.Authorised_By__c = contact.id;
        waterMapSub.Authorised_By__r = contact;
        waterMapSub.Status__c = 'Not Started';
        waterMapSub.Watermap__c = waterMap.id;
        waterMapSub.Watermap__r = waterMap;
        insert waterMapSub;

        Test.startTest();
        PageReference pageRef = Page.WaterMap_Pg1_Introduction_Page;

        ApexPages.StandardController sc = new ApexPages.StandardController(waterMapSub);
        Test.setCurrentPage(pageRef);
        WaterMAP_Pg1_Introduction_Controller controller = new WaterMAP_Pg1_Introduction_Controller (sc);

        waterMapSub.Status__c = 'Not Started';
        waterMapSub.Authorised_By__c = null;
        waterMapSub.Prepared_By__c = null;
        controller.Next();

        Test.stopTest();

    }
}