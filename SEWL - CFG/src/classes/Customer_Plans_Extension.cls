public with sharing class Customer_Plans_Extension {

/*
    Type:       Controller Extension
    Purpose:    Controller to input customer plan parameters

    Used By:    WaterMAP_KBAI_Preview_Chart Component
    ---------------------------------------------------------------
    History:

    14-Jun-2011 D.Thong (Salesforce)    Created

*/

    /* PUBLIC PROPERTIES */
    public String selectedYear {
        get {
            if (selectedYear == null)
                selectedYear = WaterMAPUtil.CURRENT_PERIOD;

            return selectedYear;
        }
        set;
    }

    public List<SelectOption> selectableYears {
        get {
            if (selectableYears == null) {
                List<SelectOption> selectableYears = new List<SelectOption>();
                for (String year : WaterMAPUtil.getLastNYearsInOrder(WaterMAPUtil.CURRENT_PERIOD, 4)) {
                    selectableYears.add(new SelectOption(year, year));
                }
                this.selectableYears = selectableYears;
            }
            return selectableYears;
        }
        private set;
    }

    /* PRIVATE PROPERTIES */
    private ApexPages.StandardController theController {get; set;}
    private Account customer {get; set;}


    /* CONSTRUCTOR */
    public Customer_Plans_Extension(ApexPages.StandardController controller) {
        customer = (Account) controller.getRecord();
        theController = controller;
    }

    /* PUBLIC METHODS */
    public PageReference Run() {
        try {
            RefreshReportData();

        } catch (System.QueryException e) {
            ApexPages.AddMessages(e);
        }
        return null;
    }

    // refresh the report data for all the watermaps for this customer
    private Void RefreshReportData() {

        List <WaterMAP__c> wMAPs = new List <WaterMAP__c>(); // list of watermaps
        Set <Id> bAcctIds = new Set<Id>(); // set of unique bacct ids
        Set <Id> custIds = new Set<Id>(); // set of all customer Ids
        // map of billing account id to billing account to allow for aggregation
        Map <Id, AnnualConsumption> annualConsumptionByBAcctMap = new Map <Id, AnnualConsumption>();

        // get the parent and all the children
        for (Account a : [select id from Account
                            where (id = :customer.id or parentid = :customer.id)
                            and   is_WaterMAP__c=true]) {
            custIds.add(a.Id);
        }

        // get all the watermaps and their consolidated accounts
        for (WaterMAP__c wMap : ([select Billing_Account__c,
                                        (select Id, Billing_Account__c
                                         from WaterMAP_Consolidated_Accounts__r)
                                        from WaterMAP__c
                                        where Customer__c in :custIds])) {
            wMaps.add(wMap);
            for (WaterMAP_Consolidated_Accounts__c consAcct : wMap.WaterMAP_Consolidated_Accounts__r) {
                bAcctIds.add(consAcct.Billing_Account__c);
            }
        }

        // build the aggregated result set
        for (AggregateResult ar : [Select  c.Billing_Account__c,
                                            sum(c.Drainage_Charge__c) DrainageCharge,
                                            sum(c.Parks_Charge__c) ParksCharge,
                                            sum(c.Recycled_Water_Cost__c) RecycledWaterCost,
                                            sum(c.Recycled_Water_Volume__c) RecycledWaterVolume,
                                            sum(c.Sewage_Disposal_Cost__c) SewageCost,
                                            sum(c.Sewage_Disposal_Volume__c) SewageVolume,
                                            sum(c.Trade_Waste_Cost__c) TradeWasteCost,
                                            sum(c.Trade_Waste_Volume__c) TradeWasteVolume,
                                            sum(c.Water_Volume__c) WaterVolume,
                                            sum(c.Water_Cost__c) WaterCost
                                    From Consumption_and_Charge__c c
                                    Where Billing_Account__c in :bAcctIds
                                    and   Financial_Year__c = :selectedYear
                                    group by c.Billing_Account__c]) {

            // populate the consumption class
            AnnualConsumption cons = new AnnualConsumption();
            cons.drainageCharge = (Decimal) ar.get('DrainageCharge');
            cons.parksCharge = (Decimal) ar.get('ParksCharge');
            cons.recycledWaterVolume = (Decimal) ar.get('RecycledWaterVolume');
            cons.recycledWaterCost = (Decimal) ar.get('RecycledWaterCost');
            cons.sewageVolume = (Decimal) ar.get('SewageVolume');
            cons.sewageCost = (Decimal) ar.get('SewageCost');
            cons.tradeWasteVolume = (Decimal) ar.get('TradeWasteVolume');
            cons.tradeWasteCost = (Decimal) ar.get('TradeWasteCost');
            cons.waterVolume = (Decimal) ar.get('WaterVolume');
            cons.waterCost = (Decimal) ar.get('WaterCost');
            cons.billingAcctId = (Id) ar.get('Billing_Account__c');
            annualConsumptionByBAcctMap.put(cons.billingAcctId, cons);
        }

        System.debug(annualConsumptionByBAcctMap);

        // loop through and populate the consolidated consumption data
        for (WaterMAP__c wMap : wMaps) {
            wmap.Report_Data_Year__c = selectedYear;
            wmap.Report_Data_Drainage_Charge__c = 0;
            wmap.Report_Data_Parks_Charge__c = 0;
            wmap.Report_Data_Recycled_Water_Cost__c = 0;
            wmap.Report_Data_Recycled_Water_Volume__c = 0;
            wmap.Report_Data_Sewage_Cost__c = 0;
            wmap.Report_Data_Sewage_Volume__c = 0;
            wmap.Report_Data_Trade_Waste_Cost__c = 0;
            wmap.Report_Data_Trade_Waste_Volume__c = 0;
            wmap.Report_Data_Water_Cost__c = 0;
            wmap.Report_Data_Water_Volume__c = 0;

            for (WaterMAP_Consolidated_Accounts__c consAcct : wMap.WaterMAP_Consolidated_Accounts__r) {
                AnnualConsumption cons = annualConsumptionByBAcctMap.get(consAcct.Billing_Account__c);

                if (cons != null) {
                    wmap.Report_Data_Drainage_Charge__c += cons.drainageCharge;
                    wmap.Report_Data_Parks_Charge__c += cons.parksCharge;
                    wmap.Report_Data_Recycled_Water_Cost__c += cons.recycledWaterCost;
                    wmap.Report_Data_Recycled_Water_Volume__c += cons.recycledWaterVolume;
                    wmap.Report_Data_Sewage_Cost__c += cons.sewageCost;
                    wmap.Report_Data_Sewage_Volume__c += cons.sewageVolume;
                    wmap.Report_Data_Trade_Waste_Cost__c += cons.tradeWasteCost;
                    wmap.Report_Data_Trade_Waste_Volume__c += cons.tradeWasteVolume;
                    wmap.Report_Data_Water_Volume__c  += cons.WaterVolume;
                    wmap.Report_Data_Water_Cost__c  += cons.waterCost;
                }
            }
        }

        update wmaps;
    }


    // private class to structure the consumption data
    private class AnnualConsumption {
        public Id billingAcctId {get; set;}
        public Decimal drainageCharge {get {if (drainageCharge==null) drainageCharge=0; return drainageCharge;} set;}
        public Decimal parksCharge {get {if (parksCharge==null) parksCharge=0; return parksCharge;} set;}
        public Decimal recycledWaterVolume {get {if (recycledWaterVolume==null) recycledWaterVolume=0; return recycledWaterVolume;} set;}
        public Decimal recycledWaterCost {get {if (recycledWaterCost==null) recycledWaterCost=0; return recycledWaterCost;} set;}
        public Decimal sewageVolume {get {if (sewageVolume==null) sewageVolume=0; return sewageVolume;} set;}
        public Decimal sewageCost {get {if (sewageCost==null) sewageCost=0; return sewageCost;} set;}
        public Decimal tradeWasteVolume {get {if (tradeWasteVolume==null) tradeWasteVolume=0; return tradeWasteVolume;} set;}
        public Decimal tradeWasteCost {get {if (tradeWasteCost==null) tradeWasteCost=0; return tradeWasteCost;} set;}
        public Decimal waterVolume {get {if (waterVolume==null) waterVolume=0; return waterVolume;} set;}
        public Decimal waterCost {get {if (waterCost==null) waterCost=0; return waterCost;} set;}

        public AnnualConsumption () {}
    }

    private static testmethod void TestMe() {
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

        Billing_Account__c billAcc = new Billing_Account__c();
        billAcc.Name = 'asetwetwrt';
        billAcc.Customer__c = account.id;
        billAcc.Property__c = prop.id;
        insert billAcc;

        Watermap__c waterMap = new Watermap__c();
        waterMap.Name = 'Test Me';
        waterMap.Customer__c = account.id;
        waterMap.Status__c = 'Not Started';
        waterMap.Billing_Account__c = billAcc.id;
        waterMAP.KBAI_Type__c = 'Average';
        waterMAP.KBAI_Description__c = 'Widget';
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
        waterMapSub.Year__c = WaterMAPUtil.CURRENT_PERIOD;
        insert waterMapSub;

        Consumption_and_Charge__c charge = new Consumption_and_Charge__c();
        charge.Water_Volume__c = 1000;
        charge.Water_Cost__c = 10000;
        charge.Billing_Account__c = billAcc.id;
        charge.Financial_Year__c = WaterMAPUtil.CURRENT_PERIOD;
        charge.Name = 'Jan-Mar 2010/11';
        insert charge;

        charge = new Consumption_and_Charge__c();
        charge.Water_Volume__c = 2000;
        charge.Water_Cost__c = 10000;
        charge.Billing_Account__c = billAcc.id;
        charge.Financial_Year__c = WaterMAPUtil.CURRENT_PERIOD;
        charge.Name = 'Apr-Jun 2010/11';
        insert charge;

        charge = new Consumption_and_Charge__c();
        charge.Water_Volume__c = 3000;
        charge.Water_Cost__c = 10000;
        charge.Billing_Account__c = billAcc.id;
        charge.Financial_Year__c = WaterMAPUtil.CURRENT_PERIOD;
        charge.Name = 'Jul-Sep 2010/11';
        insert charge;

        charge = new Consumption_and_Charge__c();
        charge.Water_Volume__c = 4000;
        charge.Water_Cost__c = 10000;
        charge.Billing_Account__c = billAcc.id;
        charge.Financial_Year__c = WaterMAPUtil.CURRENT_PERIOD;
        charge.Name = 'Oct-Dec 2010/11';
        insert charge;

        charge = new Consumption_and_Charge__c();
        charge.Water_Volume__c = 1000;
        charge.Billing_Account__c = billAcc.id;
        charge.Financial_Year__c = WaterMAPUtil.PREVIOUS_PERIOD;
        charge.Name = 'Oct-Dec 2009/10';
        insert charge;


        PageReference pageRef = Page.Customer_Plans;
        ApexPages.StandardController sc = new ApexPages.StandardController(account);
        Test.setCurrentPage(pageRef);
        Customer_Plans_Extension controller = new Customer_Plans_Extension(sc);
        controller.run();

        System.assertEquals(WaterMAPUtil.CURRENT_PERIOD, controller.selectedYear);
        System.assertEquals(controller.selectableYears.size(), 4);
        System.assertEquals(10000, [select Report_Data_Water_Volume__c from WaterMAP__c where id = :waterMap.id LIMIT 1].Report_Data_Water_Volume__c);
        System.assertEquals(40000, [select Report_Data_Water_Cost__c from WaterMAP__c where id = :waterMap.id LIMIT 1].Report_Data_Water_Cost__c);

    }
}