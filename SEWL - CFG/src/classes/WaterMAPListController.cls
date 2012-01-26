public with sharing class WaterMAPListController {

/*
    Type:       Controller
    Purpose:    Controller to display the list of current WaterMAPs

    Used By:    WaterMAPListPage VF Page
    ---------------------------------------------------------------
    History:

    02-Feb-2011 D.Thong (Salesforce)    Created

*/
    /* PUBLIC PROPERTIES */
    // list of submissions
    public List<WaterMAP_Submission__c> waterMapSubList { get; set; }

    // count of submissions
    public Integer waterMapSubCount {
        get {
            return waterMapSubList.size();
        }
        set;
    }

    /* CONSTRUCTOR */
    public WaterMAPListController () {

        // assume that the user is always there!
        User user = [Select ContactId, AccountId
                        From  User
                        Where Id = :UserInfo.getUserId() LIMIT 1];

        // get the watermap for the user's account for the current period
        waterMapSubList = [select  id, status__c, site_address__c, Year__c, watermap__r.billing_account__r.HiAF_Account_Number_Check_Digit__c
                        from    WaterMAP_Submission__c
                        where   Active__c = 'Y'
                        and     Customer__c = :user.AccountId];
    }

    /* TESTER */
    private static testmethod void testme () {

        Test.StartTest();
        WaterMAPListController w = new WaterMAPListController();
        Integer i = w.waterMapSubCount;
        Test.StopTest();
    }


}