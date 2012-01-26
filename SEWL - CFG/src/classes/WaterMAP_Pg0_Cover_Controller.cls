public with sharing class WaterMAP_Pg0_Cover_Controller {
/*
    Type:       Controller Extension
    Purpose:    Controller to display the cover page of the WaterMAP portal

    Used By:    WaterMAP_Pg0_Cover_Page VF Page
    ---------------------------------------------------------------
    History:

    02-Feb-2011 D.Thong (Salesforce)    Created

*/

    /* PUBLIC PROPERTIES */
    // returns the current WaterMAP Submission record
    public WaterMAP_Submission__c waterMAPSub {get; set;}

    // SelectOptions for contacts
    public List<SelectOption> selectableContacts{
        get{
            if(selectableContacts==null){
                selectableContacts = WaterMAPUtil.getSelectableContacts(waterMAPSub.waterMap__r.Customer__c);
            }return selectableContacts;
        }private set;
    }
    public boolean IsEREP{
        get{
            return waterMAPSub.waterMap__r.Customer__r.Is_EREP__c;
        }
        set{
            waterMAPSub.waterMap__r.Customer__r.Is_EREP__c = value;
        }
    }

    /* PRIVATE PROPERTIES */
    private ApexPages.StandardController theController {get; set;}

    /* CONSTRUCTOR */
    public WaterMAP_Pg0_Cover_Controller(ApexPages.StandardController controller) {
        waterMAPSub = (WaterMAP_Submission__c) controller.getRecord();
        theController = controller;
        setupWaterMapSub();
    }

    /* PUBLIC METHODS */
    // Validates and Saves the record
    public PageReference Save() {

        if (!SaveRecord()) {
            return null;
        }

        // redirect to refresh
        PageReference thisPage = ApexPages.currentPage();
        //thisPage.setRedirect(true);
        thisPage.getParameters().put('id', waterMAPSub.id);

        return thisPage;
    }

    // Validates, Saves and moves to next page
    public PageReference Next() {
        // validate, save and update the section complete flag

        if (!SaveRecord()) {
            return null;
        }

        return NextPage();
    }

    public PageReference NoOp() {return null;}

    // AJAX Refresher for refreshing preparer
    public PageReference RefreshPreparedBy() {
        if (waterMAPSub.Prepared_By__c != null)
            waterMAPSub.Prepared_By__r = WaterMAPUtil.queryContact(waterMAPSub.Prepared_By__c);
        else {
            waterMAPSub.Prepared_By__c = null;
            waterMAPSub.Prepared_By__r = null;
            //waterMAPSub.Prepared_By__r.Organisation_Name__c = null;
            //waterMAPSub.Prepared_By__r.title = null;
            //waterMAPSub.Prepared_By__r.phone = null;
            //waterMAPSub.Prepared_By__r.email = null;
        }

        return null;
    }

    // AJAX Refresher for refreshing authoriser
    public PageReference RefreshAuthorisedBy() {
        if (waterMAPSub.Authorised_By__c != null)
            waterMAPSub.Authorised_By__r = WaterMAPUtil.queryContact(waterMAPSub.Authorised_By__c);
        else {
            waterMAPSub.Authorised_By__c = null;
            waterMAPSub.Authorised_By__r = null;
            //waterMAPSub.Authorised_By__r.Organisation_Name__c = null;
            //waterMAPSub.Authorised_By__r.title = null;
            //waterMAPSub.Authorised_By__r.phone = null;
            //waterMAPSub.Authorised_By__r.email = null;
        }
        return null;
    }

    // Validates the page
    public boolean ValidatePage() {
        boolean valid=true;

        if (waterMAPSub.Prepared_By__c == null) {
            apexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Prepared By is a required field.');
            apexPages.addMessage(msg);
            valid=false;
        }

        if (waterMAPSub.Authorised_By__c == null) {
            apexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Authorised By is a required field.');
            apexPages.addMessage(msg);
            valid=false;
        }

        return valid;

    }

    /* PRIVATE METHODS */
    private boolean SaveRecord() {
        if (!ValidatePage()) {
            return false;
        }

        if (waterMAPSub.Status__c == 'Not Started')
            waterMAPSub.Status__c = 'In Progress';

        waterMAPSub.Cover_Complete__c = true;

        Savepoint sp = Database.setSavePoint();

        try {
            WaterMAPUtil.UpdateWaterMAP(waterMapSub.WaterMAP__r);
            WaterMAPUtil.UpdateWaterMAPSubmission(waterMapSub);
            update waterMapSub.waterMap__r.Customer__r;
        } catch (Exception e) {
            ApexPages.addMessages(e);
            Database.rollback(sp);
            return false;
        }

        return true;

    }

    private PageReference NextPage() {
        // navigate to the next page
        PageReference nextPage = Page.WaterMAP_Pg2_Company_Site_Info_Page;
        nextPage.setRedirect(true);
        nextPage.getParameters().put('id', waterMAPSub.id);

        return nextPage;
    }

    private void SetupWaterMapSub(){
        User currentUser = [Select ContactId from User where id =:UserInfo.getUserId()];
        if (currentUser.ContactId != null && waterMAPSub.Prepared_By__c == null){
            waterMAPSub.Prepared_By__c = currentUser.ContactId;
            RefreshPreparedBy();
        }
    }

    private static testmethod void testme () {

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
        insert waterMapSub;

        waterMapSub = [select id, name, prepared_by__c, prepared_by__r.name,
                            prepared_by__r.title, prepared_by__r.phone, prepared_by__r.email,
                            authorised_by__c, authorised_by__r.name,
                            authorised_by__r.title, authorised_by__r.phone, authorised_by__r.email,
                            Cover_Complete__c, Status__c, watermap__c, watermap__r.Customer__c
                    from    WaterMAP_Submission__c
                    where   id = :waterMapSub.id];

        Test.startTest();
        PageReference pageRef = Page.WaterMap_Pg0_CoverPage;
        ApexPages.StandardController sc = new ApexPages.StandardController(waterMapSub);
        Test.setCurrentPage(pageRef);
        WaterMAP_Pg0_Cover_Controller controller = new WaterMAP_Pg0_Cover_Controller (sc);

        List<SelectOption> sopt = controller.selectableContacts;

        controller.RefreshPreparedBy();
        controller.RefreshAuthorisedBy();
        controller.Save();
        controller.Next();

        waterMapSub.Status__c = 'Not Started';
        waterMapSub.Authorised_By__c = null;
        waterMapSub.Prepared_By__c = null;
        controller.RefreshPreparedBy();
        controller.RefreshAuthorisedBy();
        controller.Save();

        controller.NoOp();

        Test.stopTest();
    }
}