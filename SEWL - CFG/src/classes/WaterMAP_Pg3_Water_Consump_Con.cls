public without sharing class WaterMAP_Pg3_Water_Consump_Con {

/*
    Type:           Controller Extension
    Purpose:    Controller to display the company and site info page of the WaterMAP portal

    Used By:    WaterMAP_Pg3_Water_Consumption_Page VF Page
    ---------------------------------------------------------------
    History:

    23-May-2011 J.Pe (Davanti)  Created

*/
    /* PUBLIC PROPERTIES */
    // returns the current WaterMAP Submission record
    public WaterMAP_Submission__c waterMAPSub {get; set;}
    
    public Integer noOfYearsToDisplayForWaterUseTables{
        get{
            if(noOfYearsToDisplayForWaterUseTables==null){
                noOfYearsToDisplayForWaterUseTables = 3;
            }return noOfYearsToDisplayForWaterUseTables;
        }set;
    }
    
    // returns the baseline water use statistics for the VF page
    public List<BaselineWaterUseTable> baselineWaterUseTables{
        get{
            if(baselineWaterUseTables == null){
                baselineWaterUseTables = new List<BaselineWaterUseTable>();
                List<String> yearsToDisplay = WaterMAPUtil.getLastNYearsInOrder(WaterMAPUtil.getYearBeforePeriod(waterMapSub.Year__c), noOfYearsToDisplayForWaterUseTables);
                List<Consumption_and_Charge__c> orderedCharges = WaterMAPUtil.getWaterMAPRolledUpChargesInOrder(waterMapSub.watermap__c, yearsToDisplay);
                Map<String, List<Consumption_and_Charge__c>> baselineWaterUseRecordsMapByYear = new Map<String, List<Consumption_and_Charge__c>>();
                // divide all records into respective financial years
                for(Consumption_and_Charge__c charge: orderedCharges){
                    List<Consumption_and_Charge__c> chargesInMap;
                    if(baselineWaterUseRecordsMapByYear.containsKey(charge.Financial_Year__c)){
                        chargesInMap = baselineWaterUseRecordsMapByYear.get(charge.Financial_Year__c);
                    }else{
                        chargesInMap = new List<Consumption_and_Charge__c>();
                        baselineWaterUseRecordsMapByYear.put(charge.Financial_Year__c, chargesInMap);
                    }
                    chargesInMap.add(charge);
                }
                // create tables
                for(String yearString:yearsToDisplay){
                    List<Consumption_and_Charge__c> chargesInMap = baselineWaterUseRecordsMapByYear.get(yearString);
                    baselineWaterUseTables.add(new BaselineWaterUseTable(yearString,chargesInMap));
                }
            }return baselineWaterUseTables;
        }private set;
    }
    
    // Returns the summary statics for the current year
    public List<WaterMAP__c> baselineSummaryCurrentYr{
        get{
            if(baselineSummaryCurrentYr == null){
                baselineSummaryCurrentYr = new List<WaterMAP__c>();
                // add actual
                Consumption_and_Charge__c currentCharge = baselineWaterUseTables[noOfYearsToDisplayForWaterUseTables-1].totalCharge;
                Consumption_and_Charge__c prevCharge = baselineWaterUseTables[noOfYearsToDisplayForWaterUseTables-2].totalCharge;
                WaterMAP__c actual = new WaterMAP__c();
                if(prevCharge.Water_Volume__c!=null && prevCharge.Water_Volume__c!=0)
                    actual.Prior_Yr_Fcst_Water_Use_KL_Pct__c = (((currentCharge.Water_Volume__c-prevCharge.Water_Volume__c)/prevCharge.Water_Volume__c)*100.0).setScale(2);
                if(prevCharge.Water_Cost__c!=null && prevCharge.Water_Cost__c!=0)
                    actual.Prior_Yr_Fcst_Water_Cost_Pct__c = (((currentCharge.Water_Cost__c-prevCharge.Water_Cost__c)/prevCharge.Water_Cost__c)*100.0).setScale(2);
                if(prevCharge.Sewage_Disposal_Cost__c!=null && prevCharge.Sewage_Disposal_Cost__c!=0)
                    actual.Prior_Yr_Fcst_Sewage_Disposal_Cost_Pct__c = (((currentCharge.Sewage_Disposal_Cost__c-prevCharge.Sewage_Disposal_Cost__c)/prevCharge.Sewage_Disposal_Cost__c)*100.0).setScale(2);
                if(prevCharge.Trade_Waste_Cost__c!=null && prevCharge.Trade_Waste_Cost__c!=0)
                    actual.Prior_Yr_Fcst_Trade_Waste_Cost_Pct__c = (((currentCharge.Trade_Waste_Cost__c-prevCharge.Trade_Waste_Cost__c)/prevCharge.Trade_Waste_Cost__c)*100.0).setScale(2);
                baselineSummaryCurrentYr.add(actual);
                // add current yr forecast
                baselineSummaryCurrentYr.add(waterMapSub.WaterMAP__r);
            }return baselineSummaryCurrentYr;
        }private set;
    }
    
    // Returns the summary statics for the forcast for this coming year
    public List<WaterMAP__c> baselineForecastNextYr{
        get{
            if(baselineForecastNextYr == null){
                baselineForecastNextYr = new List<WaterMAP__c>();
                baselineForecastNextYr.add(waterMapSub.WaterMAP__r);
            }return baselineForecastNextYr;
        }private set;
    }
    /* PRIVATE PROPERTIES */

    /* CONSTRUCTOR */
    public WaterMAP_Pg3_Water_Consump_Con(ApexPages.StandardController controller) {
        waterMapSub = (WaterMAP_Submission__c) controller.getRecord();
        setupWaterMAPSub();
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

    // standard no-ops for javascript action
    public PageReference NoOp() {return null;}

    // Validates, Saves and moves to next page
    public PageReference Next() {
        // validate, save and update the section complete flag

        if (!SaveRecord()) {
            return null;
        }

        return NextPage();
    }
    
    /* PRIVATE METHODS */
    // setup-default waterMAP submission fields here
    private void setupWaterMAPSub(){

    }
    
    // Save method used in both save and next button to save all details on page
    private boolean SaveRecord() {
        if (!validatePage()) {
            return false;
        }

        if (waterMAPSub.Status__c == 'Not Started')
            waterMAPSub.Status__c = 'In Progress';

        waterMapSub.Water_Consumption_Complete__c = true;

        Savepoint sp = Database.setSavePoint();

        try {
            updateRecords();
        } catch (Exception e) {
            ApexPages.addMessages(e);
            Database.rollback(sp);
            return false;
        }

        return true;
    }

    // Returns the next page
    private PageReference NextPage() {
        // navigate to the next page
        PageReference nextPage = Page.WaterMAP_Pg4_Indicators_Targets_Page;
        nextPage.setRedirect(true);
        nextPage.getParameters().put('id', waterMAPSub.id);

        return nextPage;
    }

    // validate page for all mandatory fields
    private boolean validatePage() {
        boolean valid=true;
        
        return valid;

    }
    
    // Mechanism of saving the details on this page
    private void updateRecords(){
        update waterMapSub;
        update waterMapSub.WaterMAP__r;
    }
    
    /* PUBLIC INNER CLASSES */
    // used to record the water-use statistics to display on the VF
    public class BaselineWaterUseTable{
        public String financialYear{get;private set;}
        public List<Consumption_and_Charge__c> charges{
            get{
                if(charges == null){
                    charges = new List<Consumption_and_Charge__c>();
                }return charges;
            }private set;
        }
        public Consumption_and_Charge__c totalCharge{get;private set;}
        public List<Consumption_and_Charge__c> chargesWithTotal{
            get{
                List<Consumption_and_Charge__c> temp = new List<Consumption_and_Charge__c>(charges);
                temp.add(totalCharge);
                return temp;
            }
        }
        public Integer size { get { return charges.size(); } private set; }

        public BaselineWaterUseTable(){}
        public BaselineWaterUseTable(String financialYear, List<Consumption_and_Charge__c> chargesWithoutTotal){
            this.financialYear = financialYear;
            this.charges = chargesWithoutTotal;
            // calculate total cost for final summary row display
            Consumption_and_Charge__c totalCharge = new Consumption_and_Charge__c(Name = 'Total',
                    Water_Volume__c = 0, Water_Cost__c = 0, Sewage_Disposal_Cost__c = 0, Trade_Waste_Cost__c = 0);
            for(Consumption_and_Charge__c charge: this.charges){
                if(charge.Water_Volume__c != null) totalCharge.Water_Volume__c += charge.Water_Volume__c;
                if(charge.Water_Cost__c != null) totalCharge.Water_Cost__c += charge.Water_Cost__c;
                if(charge.Sewage_Disposal_Cost__c != null) totalCharge.Sewage_Disposal_Cost__c += charge.Sewage_Disposal_Cost__c;
                if(charge.Trade_Waste_Cost__c != null) totalCharge.Trade_Waste_Cost__c += charge.Trade_Waste_Cost__c;
            }
            this.totalCharge = totalCharge;
        }
    }
    /* TEST METHODS */
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
        waterMapSub.Year__c = '2010/11';
        insert waterMapSub;

        Consumption_and_Charge__c charge = new Consumption_and_Charge__c();
        charge.Water_Cost__c = 123.45;
        charge.Water_Volume__c = 123423.34;
        charge.Trade_Waste_Cost__c = 234234.32;
        charge.Sewage_Disposal_Cost__c = 3424232.34;
        charge.Billing_Account__c = billAcc.id;
        charge.Name = 'Jan-Mar 2010';
        charge.Financial_Year__c = '2009/10';
        insert charge;
        charge = new Consumption_and_Charge__c();
        charge.Water_Cost__c = 123.45;
        charge.Water_Volume__c = 123423.34;
        charge.Trade_Waste_Cost__c = 234234.32;
        charge.Sewage_Disposal_Cost__c = 3424232.34;
        charge.Billing_Account__c = billAcc.id;
        charge.Name = 'Jan-Mar 2009';
        charge.Financial_Year__c = '2008/09';
        insert charge;

        Test.startTest();
        PageReference pageRef = Page.WaterMap_Pg3_Water_Consumption_Page;
        ApexPages.StandardController sc = new ApexPages.StandardController(waterMapSub);
        Test.setCurrentPage(pageRef);
        WaterMAP_Pg3_Water_Consump_Con controller = new WaterMAP_Pg3_Water_Consump_Con(sc);
        List<BaselineWaterUseTable> tempTables = controller.baselineWaterUseTables;
        List<WaterMap__c> tempMaps = controller.baselineSummaryCurrentYr;
        tempMaps = controller.baselineForecastNextYr;
        controller.Save();

        waterMapSub.Status__c = 'Not Started';
        waterMapSub.Authorised_By__c = null;
        waterMapSub.Prepared_By__c = null;
        controller.Next();
        controller.NoOp();
        Test.stopTest();

    }
}