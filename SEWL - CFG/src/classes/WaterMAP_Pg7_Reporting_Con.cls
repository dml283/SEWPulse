public without sharing class WaterMAP_Pg7_Reporting_Con {

/*
    Type:           Controller Extension
    Purpose:    Controller to display the Report page of the WaterMAP portal

    Used By:    WaterMap_Pg7_Reporting_Page VF Page
    ---------------------------------------------------------------
    History:

    21-Jun-2011 J.Pe (Davanti)  Created

*/
    /* STATIC VARIABLES AND METHODS */
    // Page Parameter constants
    private static final String PAGE_PARAM_SAVE_REVIEW = 'saveReview';
    private static final String PAGE_PARAM_RET_URL = 'retURL';
    
    /* PUBLIC PROPERTIES */
    // returns the current WaterMAP Submission record
    public WaterMAP_Submission__c waterMAPSub {get; set;}
    
    // reuse of action page controller to display actions
    public WaterMAP_Pg6_Action_Plan_Con actionController {get;set;}
    
    // displays water consumption for prior year
    public Decimal totalWaterConsumptionPreviousYr { 
        get{
            if(totalWaterConsumptionPreviousYr==null){
                totalWaterConsumptionPreviousYr = 0.0;
            }return totalWaterConsumptionPreviousYr;
        } 
        private set; 
    }
    
    // displays water consumption for current year
    public Decimal totalWaterConsumptionCurrentYr { 
        get{
            if(totalWaterConsumptionCurrentYr==null){
            totalWaterConsumptionCurrentYr = 0.0;
            }return totalWaterConsumptionCurrentYr;
        } 
        private set; 
    }
    
    // displays water consumption differences in KL
    public Decimal waterConsumpDiffInKL { 
        get{
            if(waterConsumpDiffInKL==null){
            waterConsumpDiffInKL = 0.0;
            }return waterConsumpDiffInKL;
        } 
        private set; 
    }
    
    // displays water consumption differences in %
    public Decimal waterConsumpDiffInPc { get;private set; }
    
    // returns true of the target is met
    public Boolean waterConsumpTargetMet{
        get{
            if(waterConsumpDiffInPc == null) return null;
            return waterConsumpDiffInPc <= waterMapSub.waterMAP__r.Forecast_Water_Use_Pct__c;
        }
    }
    
    // Returns the string of pervious year
    public String previousYear { 
        get{
            return WaterMAPUtil.getYearBeforePeriod(waterMapSub.Year__c);
        }
    }
    
    /* CONSTRUCTOR */
    public WaterMAP_Pg7_Reporting_Con(ApexPages.StandardController controller) {
        waterMapSub = (WaterMAP_Submission__c) controller.getRecord();
        actionController = new WaterMAP_Pg6_Action_Plan_Con(controller);
        setupWaterMAPSub();
    }
    
    /* PUBLIC METHODS */  
    // code below used to generate Review PDF and save attachment
    public Pagereference checkForSaveAndRedirect(){
        Map<String,String> parameters = Apexpages.currentPage().getParameters();
        if(parameters.containsKey(PAGE_PARAM_SAVE_REVIEW)){
        String saveReviewValue = parameters.get(PAGE_PARAM_SAVE_REVIEW).toLowerCase();
        if('1'.equals(saveReviewValue) || 'true'.equals(saveReviewValue)){
            WaterMAPAttachment.upsertWaterMAPReviewAttachment(this.waterMAPSub);
            if(parameters.containsKey(PAGE_PARAM_RET_URL)){
            PageReference pageRef = new Pagereference(parameters.get(PAGE_PARAM_RET_URL));
            pageRef.setRedirect(true);
            return pageRef;
            }
        }
        }
        return null;
    }
    
    // standard no-ops for javascript action
    public PageReference NoOp() {return null;}

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
    public PageReference complete() {
        // validate, save and update the section complete flag

        if (!SaveRecord()) {
            return null;
        }
        
        Savepoint sp = Database.setSavePoint();
        try {
            waterMAPSub.Status__c = 'Review Completed';
            waterMapSub.Review_Complete__c = true;
            update waterMAPSub;
        } catch (Exception e) {
            ApexPages.addMessages(e);
            Database.rollback(sp);
            return null;
        }
        // go to PDF with save parameters

        return saveReviewPDF();
    }
    /* PRIVATE METHODS */
    // method that saves review PDF
    private Pagereference saveReviewPDF(){
        PageReference pageRef = Page.WaterMAP_Review_PDF;
        pageRef.getParameters().put('id',this.waterMAPSub.id);
        pageRef.getParameters().put(PAGE_PARAM_SAVE_REVIEW,'1');
        pageRef.getParameters().put('retURL',Apexpages.currentPage().getUrl());
        pageRef.setRedirect(true);
        return pageRef;
    }
    
    // setup-default waterMAP submission fields here
    private void setupWaterMAPSub(){
        List<Consumption_and_Charge__c> priorYearCharges = WaterMAPUtil.getWaterMAPAllChargesInOrder(waterMapSub.watermap__c, new String[]{previousYear,waterMapSub.Year__c});
    
        Map<String, Decimal> totalWaterConsumptionMapToYear = new Map<String, Decimal>();
        for(Consumption_and_Charge__c charge: priorYearCharges){
            Decimal totalWaterConsumption;
            if(totalWaterConsumptionMapToYear.containsKey(charge.Financial_Year__c)){
            totalWaterConsumption = totalWaterConsumptionMapToYear.get(charge.Financial_Year__c);
            }else{
            totalWaterConsumption = 0.0;
            }
            totalWaterConsumption += charge.Water_Volume__c;
            totalWaterConsumptionMapToYear.put(charge.Financial_Year__c, totalWaterConsumption);
        }
        if(totalWaterConsumptionMapToYear.containsKey(previousYear)){
            totalWaterConsumptionPreviousYr = totalWaterConsumptionMapToYear.get(previousYear);
        }
        if(totalWaterConsumptionMapToYear.containsKey(waterMapSub.Year__c)){
            totalWaterConsumptionCurrentYr = totalWaterConsumptionMapToYear.get(waterMapSub.Year__c);
        }
        waterConsumpDiffInKL = totalWaterConsumptionCurrentYr - totalWaterConsumptionPreviousYr;
        if(totalWaterConsumptionPreviousYr == 0.0){
            waterConsumpDiffInPc = null;
        }else{
            waterConsumpDiffInPc = (waterConsumpDiffInKL / totalWaterConsumptionPreviousYr)*100.0;
        } 
    }
    
    // Save method used in both save and next button to save all details on page
    private boolean SaveRecord() {
        if (!validatePage()) {
            return false;
        }

        if (waterMAPSub.Status__c == 'Not Started')
            waterMAPSub.Status__c = 'In Progress';
            
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

    // validate page for all mandatory fields
    private boolean validatePage() {
        boolean valid=true;
        for(WaterMAP_Pg6_Action_Plan_Con.ActionItemWrapper itemWrapper :actionController.readOnlyNonOngoingActions){
            if(!itemWrapper.isReviewValid()){
                //apexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Review of specific action / projects are not completed correctly - please make sure all mandatory fields are filled-in.');
                //apexPages.addMessage(msg);
                valid=false;    
            }
        }
        return valid;
    }
    
    // Mechanism of saving the details on this page
    private void updateRecords(){
        update waterMapSub;
        update waterMapSub.WaterMAP__r;
        actionController.saveAllActionItems();
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
        charge.Name = 'Jan-Mar 2011';
        charge.Financial_Year__c = '2010/11';
        insert charge;
        charge = new Consumption_and_Charge__c();
        charge.Water_Cost__c = 123.45;
        charge.Water_Volume__c = 123423.34;
        charge.Trade_Waste_Cost__c = 234234.32;
        charge.Sewage_Disposal_Cost__c = 3424232.34;
        charge.Billing_Account__c = billAcc.id;
        charge.Name = 'Jan-Mar 2010';
        charge.Financial_Year__c = '2009/10';
        insert charge;

        Test.startTest();
        PageReference pageRef = Page.WaterMap_Pg7_Reporting_Page;
        ApexPages.StandardController sc = new ApexPages.StandardController(waterMapSub);
        Test.setCurrentPage(pageRef);
        WaterMAP_Pg7_Reporting_Con controller = new WaterMAP_Pg7_Reporting_Con(sc);
        controller.Save();

        waterMapSub.Status__c = 'Not Started';
        System.assertEquals(0.0,controller.waterConsumpDiffInKL);
        System.assertEquals(0.0,controller.waterConsumpDiffInPc);
        Boolean testboolean = controller.waterConsumpTargetMet;
        controller.complete();
        PageReference pageRef2 = Page.WaterMAP_Review_PDF;
        pageRef2.getParameters().put(PAGE_PARAM_SAVE_REVIEW,'1');
        pageRef2.getParameters().put(PAGE_PARAM_RET_URL,'/home/');
        Test.setCurrentPage(pageRef2);
        WaterMAP_Pg7_Reporting_Con controller2 = new WaterMAP_Pg7_Reporting_Con(sc);
        controller2.checkForSaveAndRedirect();
        Test.stopTest();

    }
}