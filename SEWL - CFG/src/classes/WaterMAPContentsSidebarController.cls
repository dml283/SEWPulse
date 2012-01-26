public with sharing class WaterMAPContentsSidebarController {

/*
    Type:       Component Controller
    Purpose:    Controller to display the sidebar of the watermap
                Returns the sections of the watermap that are complete
                as well as the property address

    Used By:    WaterMAPContentsSidebar Component
    ---------------------------------------------------------------
    History:

    02-Feb-2011 D.Thong (Salesforce)    Created

*/

    /* PUBLIC PROPERTIES */
    public Id waterMAPSubId { get; set; }

    public WaterMap_Submission__c waterMapSub {
        get {
            if (waterMAPSubId != null && waterMapSubRecord == null) {
                waterMapSubRecord = [select id, status__c, site_address__c, cover_complete__c,
                                  Action_Plan_Complete__c, Indicators_Targets_Complete__c,
                                  Opportunities_to_Save_Water_Complete__c, Review_Complete__c,
                                  Water_Consumption_Complete__c, Company_Site_Info_Complete__c
                                  from WaterMap_Submission__c
                                  where Id = :waterMAPSubId];
            }

            return waterMapSubRecord;

        }
        set;
    }

    /* PRIVATE PROPERTIES */
    private WaterMap_Submission__c waterMapSubRecord;

    public static testmethod void TestMe() {
        // create test data
        Account account = new Account();
        account.name = 'foo';
        insert account;

        Watermap__c waterMap = new Watermap__c();
        waterMap.Name = 'Test Me';
        waterMap.Customer__c = account.id;
        insert waterMap;

        Watermap_Submission__c waterMapSub = new Watermap_Submission__c();
        waterMapSub.Watermap__c = waterMap.id;
        insert waterMapSub;

        // start the test
        Test.startTest();
        WaterMAPContentsSidebarController controller = new WaterMAPContentsSidebarController();
        controller.waterMAPSubId = waterMapSub.id;
        Watermap_Submission__c newWaterMap = controller.waterMapSub;
        Test.stopTest();
    }
}