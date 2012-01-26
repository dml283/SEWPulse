public without sharing class WaterMAP_Pg2_Comp_Site_Info_Con {

/*
    Type:       Controller Extension
    Purpose:    Controller to display the company and site info page of the WaterMAP portal

    Used By:    WaterMAP_Pg2_Company_Site_Info_Page VF Page
    ---------------------------------------------------------------
    History:

    18-May-2011 J.Pe (Davanti)  Created

*/
    /* PUBLIC PROPERTIES */
    // returns the current WaterMAP Submission record
    public WaterMAP_Submission__c waterMAPSub {get; set;}
    
    // returns the total water consumption statistics for the VF page
    public Decimal totalWaterConsumption { get; set; }
    public Decimal totalSewageDisposalVolume { get; set; }
    public Decimal totalTradeWasteVolume { get; set; }

    // returns the previous year in String
    public String previousYear{
        get{
            return WaterMAPUtil.getYearBeforePeriod(waterMapSub.Year__c);
        }
    }
    
    // boolean that sets / checks if site manager is also primary contact
    public boolean primaryContactIsSiteMgr{
        get{
            if(primaryContactIsSiteMgr==null){
                primaryContactIsSiteMgr = (waterMAPSub.WaterMAP__r.Site_Manager__c==waterMAPSub.WaterMAP__r.Primary_Contact__c);
            }return primaryContactIsSiteMgr;
        }set{
                if (value){
                        waterMAPSub.WaterMAP__r.Primary_Contact__c = waterMAPSub.WaterMAP__r.Site_Manager__c;
                }else if(primaryContactIsSiteMgr && !value){ // changes from true to false
                        waterMAPSub.WaterMAP__r.Primary_Contact__c = null;
                        RefreshPrimaryContact();
                }
                primaryContactIsSiteMgr = value;
        }
    }
    
    // boolean that checks if the postal address is same as site address
    public boolean postalAddressIsSiteAddress{
        get{
            if(postalAddressIsSiteAddress==null){
                postalAddressIsSiteAddress = false;
            }return postalAddressIsSiteAddress;
        }set;
    }
    
    // defines a default number of water-use breakdown rows to be visible
    public Integer defaultNoOfProcessEquipBreakdownRows{
        get{
            if(defaultNoOfProcessEquipBreakdownRows==null){
                defaultNoOfProcessEquipBreakdownRows = 5;
            }return defaultNoOfProcessEquipBreakdownRows;
        }set;
    }
    
    // returns the whole list of water-use breakdown by process / equipment
    // this includes the rows that users have hit the delete button on
    public List<ProcessEquipBreakdownWrapper> allProcessEquipBreakdowns {
        get{
            if(allProcessEquipBreakdowns==null){
                allProcessEquipBreakdowns = new List<ProcessEquipBreakdownWrapper>();
                List<Activity_Process_Equipment_Breakdown__c> breakdownRecords = [Select a.WaterMAP__c, a.Specify_Other__c, a.Percentage_of_Water_Use__c, a.Name, a.Id, a.Activity_Process_Equipment__c From Activity_Process_Equipment_Breakdown__c a where a.WaterMAP__c = :waterMapSub.Watermap__c];
                for(Activity_Process_Equipment_Breakdown__c breakdownRecord: breakdownRecords){
                        allProcessEquipBreakdowns.add(new ProcessEquipBreakdownWrapper(breakdownRecord,totalWaterConsumption));
                }
            }
            Integer numberOfNonDeletedRecords = 0;
            for(ProcessEquipBreakdownWrapper wrapper: allProcessEquipBreakdowns){
                if(!wrapper.isMarkedForDelete){
                    numberOfNonDeletedRecords++;
                }
            }
            for(Integer i = numberOfNonDeletedRecords ; i < defaultNoOfProcessEquipBreakdownRows ; i++){
                allProcessEquipBreakdowns.add(new ProcessEquipBreakdownWrapper(new Activity_Process_Equipment_Breakdown__c(WaterMAP__c = waterMapSub.WaterMAP__c),totalWaterConsumption));
            }
            return allProcessEquipBreakdowns;
        }private set;
    }    
    
    // this only returns the non-deleted list of water-use breakdown
    public List<ProcessEquipBreakdownWrapper> processEquipBreakdowns{
        get{
            List<ProcessEquipBreakdownWrapper> tempList = new List<ProcessEquipBreakdownWrapper>();
            for(ProcessEquipBreakdownWrapper wrapper: allProcessEquipBreakdowns){
                if(!wrapper.isMarkedForDelete){
                    tempList.add(wrapper);
                }
            }
            return tempList;
        }
    }
    
    // for PDF only - returns a list of water-use breakdown which is not deleted
    // and not empty, to display on the PDF
    public List<ProcessEquipBreakdownWrapper> readOnlyProcessEquipBreakdowns{
        get{
                List<ProcessEquipBreakdownWrapper> tempList = new List<ProcessEquipBreakdownWrapper>();
                for(ProcessEquipBreakdownWrapper breakdownWrapper: processEquipBreakdowns){
                        if(breakdownWrapper.breakdown.id!=null){
                                tempList.add(breakdownWrapper);
                        }
                }
                return tempList;
        }
    }
    
    // for PDF only - generates a Google pie chart based on the water-use 
    // breakdown and returns the URL that displays it
    public String googleProcessBreakdownPieChartURL {
        get {
            PageReference chartURL = new PageReference('http://chart.apis.google.com/chart');
            chartURL.getParameters().put('cht','p');
            chartURL.getParameters().put('chco','005F98|70BF49|00BBDE|00B085|C1D82F|717EBD|7E499D|595959|BBB0A6');
            // chart data
            String dataFigure = '';
            String dataLabel = '';
            Integer labelHeight = 0;
            if(readOnlyProcessEquipBreakdowns.size()==0) return null;
            for(ProcessEquipBreakdownWrapper wrapper: readOnlyProcessEquipBreakdowns){
                dataFigure += wrapper.breakdown.Percentage_of_Water_Use__c+',';
                if('Other (please specify)'.equals(wrapper.breakdown.Activity_Process_Equipment__c)){
                    dataLabel += 'Other - '+wrapper.breakdown.Specify_Other__c+'|';
                }else{
                    dataLabel += wrapper.breakdown.Activity_Process_Equipment__c+'|';
                }
                labelHeight +=20;
            }
            if(dataFigure.length()>1){
                dataFigure = dataFigure.substring(0,dataFigure.length()-1);
            }
            chartURL.getParameters().put('chd','t:'+dataFigure);
            if(dataLabel.length()>1){
                dataLabel = dataLabel.substring(0,dataLabel.length()-1);
            }
            chartURL.getParameters().put('chdl',dataLabel);
            chartURL.getParameters().put('chdlp','bv');
            chartURL.getParameters().put('chs','500x'+(200+labelHeight));
            chartURL.getParameters().put('chs','500x'+(200+labelHeight));
            chartURL.getParameters().put('chtt','Water Use Chart');
            return chartURL.getURL();
        }
    }
    
    // returns a list of consolidated accounts under the same watermap to list 
    // on the page
    public List<WaterMAP_Consolidated_Accounts__c> consolidatedAccounts{
        get{
            if(consolidatedAccounts == null){
                consolidatedAccounts = new List<WaterMAP_Consolidated_Accounts__c>();
                List<WaterMAP_Consolidated_Accounts__c> tempList = WaterMAPUtil.getWaterMAPConsolAccs(waterMAPSub.WaterMAP__c);
                for(WaterMAP_Consolidated_Accounts__c consolAcct: tempList){
                    if(!consolAcct.Primary__c){
                        consolidatedAccounts.add(consolAcct);
                    }
                }
            }return consolidatedAccounts;
        }private set;
    }
    
    // SelectOptions for contacts
    public List<SelectOption> selectableContacts{
        get{
            if(selectableContacts==null){
                selectableContacts = WaterMAPUtil.getSelectableContacts(waterMapSub.waterMAP__r.Customer__c);
            }return selectableContacts;
        }private set;
    }
    
    // SelectOptions for ANZSIC Code
    public List<SelectOption> selectableANZSIC{
        get{
            if(selectableANZSIC==null){
                selectableANZSIC = new List<SelectOption>();
                List<Anzic_Code__c> anzsics = [Select a.id, a.WaterMAP_Visible__c, a.Name, a.Description__c From Anzic_Code__c a where a.WaterMAP_Visible__c = true order by a.Description__c ASC];
                selectableANZSIC.add(new SelectOption('', '--None--'));
                for(Anzic_Code__c anzic: anzsics){
                    selectableANZSIC.add(new SelectOption(anzic.id, anzic.Name));
                }
            }return selectableANZSIC;
        }private set;
    }
    
    // variable used to display postal address
    public PostalAddress postalAddress{
        get{
            if(postalAddress == null){
                postalAddress = new PostalAddress();
            }return postalAddress;
        }private set;
    }
    
    /* PRIVATE PROPERTIES */

    /* CONSTRUCTOR */
    public WaterMAP_Pg2_Comp_Site_Info_Con(ApexPages.StandardController controller) {
        waterMapSub = (WaterMAP_Submission__c) controller.getRecord();
        setupWaterMAPSub();
    }
    
    /* PUBLIC METHODS */
    // allow users to add extra rows to the water-use breakdown table
    public void addBreakdownRow(){
        allProcessEquipBreakdowns.add(new ProcessEquipBreakdownWrapper(new Activity_Process_Equipment_Breakdown__c(WaterMAP__c = waterMapSub.WaterMAP__c)));
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
    public PageReference Next() {
        // validate, save and update the section complete flag

        if (!SaveRecord()) {
            return null;
        }

        return NextPage();
    }
    
    // used to refresh Site Manager details 
    public PageReference RefreshSiteMgr() {
        if (waterMAPSub.waterMAP__r.Site_Manager__c != null)
            waterMAPSub.waterMAP__r.Site_Manager__r = WaterMAPUtil.queryContact(waterMAPSub.waterMAP__r.Site_Manager__c);
        else {
            if(waterMAPSub.waterMAP__r.Site_Manager__r != null){
                waterMAPSub.waterMAP__r.Site_Manager__r.Organisation_Name__c = null;
                waterMAPSub.waterMAP__r.Site_Manager__r.title = null;
                waterMAPSub.waterMAP__r.Site_Manager__r.phone = null;
                waterMAPSub.waterMAP__r.Site_Manager__r.email = null;
                waterMAPSub.waterMAP__r.Site_Manager__r.MobilePhone = null;
            }
            waterMAPSub.waterMAP__r.Site_Manager__r = null;
        }
        refreshWaterManagementTeam();
        RefreshPostalAddress();
        return null;
    }
    
    // used to refresh Primary Contact details
    public PageReference RefreshPrimaryContact() {
        if (waterMAPSub.waterMAP__r.Primary_Contact__c != null)
            waterMAPSub.waterMAP__r.Primary_Contact__r = WaterMAPUtil.queryContact(waterMAPSub.waterMAP__r.Primary_Contact__c);
        else {
            if(waterMAPSub.waterMAP__r.Primary_Contact__r != null){
                waterMAPSub.waterMAP__r.Primary_Contact__r.Organisation_Name__c = null;
                waterMAPSub.waterMAP__r.Primary_Contact__r.title = null;
                waterMAPSub.waterMAP__r.Primary_Contact__r.phone = null;
                waterMAPSub.waterMAP__r.Primary_Contact__r.email = null;
                waterMAPSub.waterMAP__r.Primary_Contact__r.MobilePhone = null;
            }
            waterMAPSub.waterMAP__r.Primary_Contact__r = null;
        }
        refreshWaterManagementTeam();
        RefreshPostalAddress();
        return null;
    }
    
    // used to refresh Secondary Contact details
    public PageReference RefreshSecondaryContact() {
        if (waterMAPSub.waterMAP__r.Secondary_Contact__c != null)
            waterMAPSub.waterMAP__r.Secondary_Contact__r = WaterMAPUtil.queryContact(waterMAPSub.waterMAP__r.Secondary_Contact__c);
        else {
            if(waterMAPSub.waterMAP__r.Secondary_Contact__r != null){
                waterMAPSub.waterMAP__r.Secondary_Contact__r.Organisation_Name__c = null;
                waterMAPSub.waterMAP__r.Secondary_Contact__r.title = null;
                waterMAPSub.waterMAP__r.Secondary_Contact__r.phone = null;
                waterMAPSub.waterMAP__r.Secondary_Contact__r.email = null;
                waterMAPSub.waterMAP__r.Secondary_Contact__r.MobilePhone = null;
            }
            waterMAPSub.waterMAP__r.Secondary_Contact__r = null;
        }
        refreshWaterManagementTeam();
        RefreshPostalAddress();
        return null;
    }

    // used to refresh Water Management Team details
    // Note - only used if the field is not a rich text area
    public void refreshWaterManagementTeam(){
        /*
        String waterManagementTeamText = '';
        if(waterMAPSub.waterMAP__r.Site_Manager__c!=null){
            waterManagementTeamText += waterMAPSub.waterMAP__r.Site_Manager__r.Name +((waterMAPSub.waterMAP__r.Site_Manager__r.title==null)?(''):(' - '+ waterMAPSub.waterMAP__r.Site_Manager__r.title));
        }
        if(waterMAPSub.waterMAP__r.Primary_Contact__c!=null){
            waterManagementTeamText += ((waterManagementTeamText=='')?(''):('\n'))+waterMAPSub.waterMAP__r.Primary_Contact__r.Name +((waterMAPSub.waterMAP__r.Primary_Contact__r.title==null)?(''):(' - '+ waterMAPSub.waterMAP__r.Primary_Contact__r.title));
        }
        if(waterMAPSub.waterMAP__r.Secondary_Contact__c!=null){
            waterManagementTeamText += ((waterManagementTeamText=='')?(''):('\n'))+waterMAPSub.waterMAP__r.Secondary_Contact__r.Name +((waterMAPSub.waterMAP__r.Secondary_Contact__r.title==null)?(''):(' - '+ waterMAPSub.waterMAP__r.Secondary_Contact__r.title));
        }
        waterMAPSub.WaterMAP__r.Team_Members__c = waterManagementTeamText;
        */
    }
    // used to refresh postal address details
    public PageReference RefreshPostalAddress() {
        Id contactId;
        Contact con;
        if (waterMAPSub.WaterMAP__r.Preferred_Postal_Contact_Type__c != null){
            if(waterMAPSub.WaterMAP__r.Preferred_Postal_Contact_Type__c.toLowerCase().contains('site')){
                contactId = waterMAPSub.WaterMAP__r.Site_Manager__c;
            }else if(waterMAPSub.WaterMAP__r.Preferred_Postal_Contact_Type__c.toLowerCase().contains('primary')){
                contactId = waterMAPSub.WaterMAP__r.Primary_Contact__c;
            }else if(waterMAPSub.WaterMAP__r.Preferred_Postal_Contact_Type__c.toLowerCase().contains('second')){
                contactId = waterMAPSub.WaterMAP__r.Secondary_Contact__c;
            }
        }
        if (contactId!=null){
             con = WaterMAPUtil.queryContact(contactId);
        }
        // contact name
        if (con!=null){
            postalAddress.name = con.Name;
        }else{
            postalAddress.name = null;
        }
        // address
        if(postalAddressIsSiteAddress){
                postalAddress.street = waterMAPSub.Watermap__r.Billing_Account__r.Property__r.Street_Address__c;
                postalAddress.suburb = waterMAPSub.Watermap__r.Billing_Account__r.Property__r.Suburb__c;
                postalAddress.state = waterMAPSub.Watermap__r.Billing_Account__r.Property__r.State__c;
                postalAddress.postalCode = waterMAPSub.Watermap__r.Billing_Account__r.Property__r.Postal_Code__c;
        }else {
            if (con!=null) {
                postalAddress.street = con.MailingStreet;
                postalAddress.suburb = con.MailingCity;
                postalAddress.state = con.MailingState;
                postalAddress.postalCode = con.MailingPostalCode;
            }
            else{
                postalAddress.street = null;
                postalAddress.suburb = null;
                postalAddress.state = null;
                postalAddress.postalCode = null;
            }
        }
        return null;
    }
    
    /* PRIVATE METHODS */
    // setup-default waterMAP submission fields here
    private void setupWaterMAPSub(){
        if(!waterMapSub.Company_Site_Info_Complete__c && waterMapSub.waterMap__r.Site_Organisation_Name__c==null){
            waterMapSub.waterMap__r.Site_Organisation_Name__c = waterMapSub.watermap__r.Customer__r.Name;
        }
        List<Consumption_and_Charge__c> priorYearCharges = WaterMAPUtil.getWaterMAPAllChargesInOrder(waterMapSub.watermap__c, new String[]{previousYear});

        TotalWaterConsumption = 0;
        TotalSewageDisposalVolume = 0;
        TotalTradeWasteVolume = 0;
        for(Consumption_and_Charge__c charge: priorYearCharges){
            TotalWaterConsumption += charge.Water_Volume__c;
            TotalSewageDisposalVolume += charge.Sewage_Disposal_Volume__c;
            TotalTradeWasteVolume += charge.Trade_Waste_Volume__c;
        }
        RefreshPostalAddress();

    }
    
    // validate page for all mandatory fields
    private boolean validatePage() {
        boolean valid=true;

        if (waterMAPSub.Watermap__r.Site_Organisation_Name__c == null) {
            apexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Site Organisation Name is a required field.');
            apexPages.addMessage(msg);
            valid=false;
        }

        if (waterMAPSub.Watermap__r.Site_Manager__c == null) {
            apexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Site Manager is a required field.');
            apexPages.addMessage(msg);
            valid=false;
        }

        if (!primaryContactIsSiteMgr && waterMAPSub.Watermap__r.Primary_Contact__c == null) {
            apexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Primary Contact is a required field.');
            apexPages.addMessage(msg);
            valid=false;
        }
        if (waterMAPSub.Watermap__r.Preferred_Postal_Contact_Type__c == null) {
            apexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Preferred Postal Contact is a required field.');
            apexPages.addMessage(msg);
            valid=false;
        }
        if (waterMAPSub.Watermap__r.ANZSIC__c == null) {
            apexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'ANZSIC Code is a required field.');
            apexPages.addMessage(msg);
            valid=false;
        }

        Decimal totalPercentage = 0;
        boolean breakdownHasValue = false;
        for(ProcessEquipBreakdownWrapper breakdownWrapped: allProcessEquipBreakdowns){
            if(breakdownWrapped.isMarkedForDelete) continue;
            Activity_Process_Equipment_Breakdown__c breakdown = breakdownWrapped.breakdown;
            boolean specificBreakdownValid = true;
            if ('Other (please specify)'.equals(breakdown.Activity_Process_Equipment__c)&& breakdown.Specify_Other__c==null){
                apexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Please specifically state the type of Activity/Process/Equipment.');
                apexPages.addMessage(msg);
                specificBreakdownValid=false;
            }else if(breakdown.Activity_Process_Equipment__c==null&&breakdown.Percentage_of_Water_Use__c!=null){
                apexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Activity/Process/Equipment field is a required field for every Percentage of Water Use field entered.');
                apexPages.addMessage(msg);
                specificBreakdownValid=false;
            }else if(breakdown.Activity_Process_Equipment__c!=null && breakdown.Percentage_of_Water_Use__c==null){
                apexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Percentage of Water Use field is a required field for every Activity/Process/Equipment field entered.');
                apexPages.addMessage(msg);
                specificBreakdownValid=false;
            }
            if(!specificBreakdownValid){
                valid = false;
            }
            else if(breakdown.Activity_Process_Equipment__c!=null && breakdown.Percentage_of_Water_Use__c!=null){
                totalPercentage += breakdown.Percentage_of_Water_Use__c;
                breakdownHasValue = true;
            }
        }
        if(breakdownHasValue && totalPercentage != 100.00){
            apexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Total Percentage of Water Use does not add up to 100% - please review below and make adjustments.');
            apexPages.addMessage(msg);
            valid = false;
        }

        return valid;

    }
    
    // Save method used in both save and next button to save all details on page
    private boolean SaveRecord() {
        if (!validatePage()) {
            return false;
        }

        if (waterMAPSub.Status__c == 'Not Started')
            waterMAPSub.Status__c = 'In Progress';

        waterMapSub.Company_Site_Info_Complete__c = true;

        Savepoint sp = Database.setSavePoint();

        try {
            updateRecords();
        } catch (Exception e) {
            ApexPages.addMessages(e);
            Database.rollback(sp);
            return false;
        }
        allProcessEquipBreakdowns = null;
        return true;
    }
    
    // Returns the next page
    private PageReference NextPage() {
        // navigate to the next page
        PageReference nextPage = Page.WaterMAP_Pg3_Water_Consumption_Page;
        nextPage.setRedirect(true);
        nextPage.getParameters().put('id', waterMAPSub.id);

        return nextPage;
    }
    
    // Mechanism of saving the details on this page
    private void updateRecords(){
        update waterMapSub.WaterMAP__r;
        update waterMapSub;
        List<Activity_Process_Equipment_Breakdown__c> upsertBreakdowns = new List<Activity_Process_Equipment_Breakdown__c>();
        List<Activity_Process_Equipment_Breakdown__c> deleteBreakdowns = new List<Activity_Process_Equipment_Breakdown__c>();
        for(ProcessEquipBreakdownWrapper breakdownWrapped : allProcessEquipBreakdowns){
            Activity_Process_Equipment_Breakdown__c breakdown = breakdownWrapped.breakdown;
            if(breakdown.Activity_Process_Equipment__c != null && breakdown.Percentage_of_Water_Use__c != null && !breakdownWrapped.isMarkedForDelete){
                upsertBreakdowns.add(breakdown);
            }
            else if (breakdown.id != null && breakdownWrapped.isMarkedForDelete){
                deleteBreakdowns.add(breakdown);
            }
        }
        if(upsertBreakdowns.size()>0){
            upsert upsertBreakdowns;
        }
        if(deleteBreakdowns.size()>0){
            delete deleteBreakdowns;
        }
    }
    
    /* PUBLIC INNER CLASSES */
    // class that stores postal address details
    public class PostalAddress{
        public String name{get;set;}
        public String street{get;set;}
        public String suburb{get;set;}
        public String state{get;set;}
        public String postalCode{get;set;}
    }
    // class used to wrap around Activity_Process_Equipment_Breakdown__c for
    // use on VF page
    public class ProcessEquipBreakdownWrapper{
        public string uniqueID{get;private set;}
        public Activity_Process_Equipment_Breakdown__c breakdown{get; private set;}
        public Decimal totalWaterUsedKL{get;set;}
        public boolean isMarkedForDelete{
            get{
                if(isMarkedForDelete == null){
                    isMarkedForDelete = false;
                }return isMarkedForDelete;
            }
            set;
        }
        public Decimal waterUsedKL{
            get{
                if(totalWaterUsedKL!=null && breakdown.Percentage_of_Water_Use__c != null){
                    return totalWaterUsedKL*(breakdown.Percentage_of_Water_Use__c / 100);
                }
                return null;
            }
        }
        public ProcessEquipBreakdownWrapper(Activity_Process_Equipment_Breakdown__c breakdown){
                this.breakdown = breakdown;
                this.uniqueID = WaterMAPUtil.generateRandomID();
        }
        public ProcessEquipBreakdownWrapper(Activity_Process_Equipment_Breakdown__c breakdown, Decimal totalWaterUsedKL){
            this(breakdown);
            this.totalWaterUsedKL = totalWaterUsedKL;
        }
        public void deleteRecord(){
            isMarkedForDelete = true;
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

        Watermap__c waterMap = new Watermap__c();
        waterMap.Name = 'Test Me';
        waterMap.Customer__c = account.id;
        waterMap.Status__c = 'Not Started';
        insert waterMap;

        Anzic_Code__c anzic = new Anzic_Code__c();
        anzic.Name = 'Test';
        anzic.ANZSIC_External_Code_ID__c = 'ufujk';
        anzic.Description__c = 'Test Description';
        anzic.WaterMAP_Visible__c = true;
        insert anzic;

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
        waterMapSub = [Select w.Year__c, w.WaterMap__r.Site_Manager__r.Name, w.WaterMap__r.Primary_Contact__r.Name, w.WaterMap__r.Secondary_Contact__r.Name, w.watermap__r.Customer__r.Name , w.Watermap__r.Efficiency_Change_Comments__c, w.Watermap__r.Prior_Yr_Fcst_Water_Use_KL_Pct__c, w.Watermap__r.Prior_Yr_Fcst_Water_Cost_Pct__c, w.Watermap__r.Prior_Yr_Fcst_Trade_Waste_Cost_Pct__c, w.Watermap__r.Prior_Yr_Fcst_Sewage_Disposal_Cost_Pct__c, w.Watermap__r.Customer__r.Is_EREP__c, w.Watermap__r.Billing_Account_Id__c, w.Watermap__r.Preferred_Postal_Contact_Type__c, w.Watermap__r.Site_Organisation_Name__c, w.Watermap__r.ANZSIC__c, w.Watermap__r.Customer_Number__c, w.Watermap__r.About_Your_Site__c, w.Watermap__r.Type__c, w.Watermap__r.Start_Year__c, w.Watermap__r.Property_Id__c, w.Watermap__r.Billing_Account__c, w.Watermap__r.Customer_ID__c, w.Watermap__r.Status__c, w.Watermap__r.Equipment_Infrastructure_Processes__c, w.Watermap__r.People_and_Culture__c, w.Watermap__r.Water_Use_Outlook__c, w.Watermap__r.Water_Use_Comments__c, w.Watermap__r.Team_Members__c, w.Watermap__r.Additional_Comments__c, w.Watermap__r.Forecast_Trade_Waste_Cost_Pct__c, w.Watermap__r.Forecast_Sewage_Disposal_Pct__c, w.Watermap__r.Forecast_Water_Cost_Pct__c, w.Watermap__r.Forecast_Water_Use_Pct__c, w.Watermap__r.Water_Use_Influencing_Factors__c, w.Watermap__r.Migration_Id__c, w.Watermap__r.Secondary_Contact__c, w.Watermap__r.Primary_Contact__c, w.Watermap__r.Site_Manager__c, w.Watermap__r.Site_Address__c, w.Watermap__r.Peak_industry_body__c, w.Watermap__r.Organisation_Name__c, w.Watermap__r.Customer__c, w.Watermap__r.LastActivityDate, w.Watermap__r.SystemModstamp, w.Watermap__r.LastModifiedById, w.Watermap__r.LastModifiedDate, w.Watermap__r.CreatedById, w.Watermap__r.CreatedDate, w.Watermap__r.Name, w.Watermap__r.IsDeleted, w.Watermap__r.Id, w.Watermap__c, w.WaterMAP_Customer_Id__c, w.SystemModstamp, w.Submitted_Datetime__c, w.Status__c, w.Site_Address__c,w.Company_Site_Info_Complete__c, w.Property_Ref__c, w.Prepared_By__c, w.Name, w.LastModifiedDate, w.LastModifiedById, w.IsDeleted, w.Id, w.Customer__c, w.Customer_Name__c, w.CreatedDate, w.CreatedById, w.Cover_Complete__c, w.Authorised_By__c From WaterMAP_Submission__c w where w.id = :waterMapSub.id];
        Test.startTest();
        PageReference pageRef = Page.WaterMap_Pg2_Company_Site_Info_Page;
        ApexPages.StandardController sc = new ApexPages.StandardController(waterMapSub);
        Test.setCurrentPage(pageRef);
        WaterMAP_Pg2_Comp_Site_Info_Con controller = new WaterMAP_Pg2_Comp_Site_Info_Con(sc);
        List<ProcessEquipBreakdownWrapper> temp = controller.processEquipBreakdowns;
        controller.addBreakdownRow();
        temp[0].breakdown.Activity_Process_Equipment__c = 'Test';
        temp[1].breakdown.Percentage_of_Water_Use__c = 10;
        controller.Next();
        temp[1].breakdown.Activity_Process_Equipment__c = 'Other (please specify)';
        temp[0].breakdown.Percentage_of_Water_Use__c = 90;
        controller.Next();
        temp[1].breakdown.Specify_Other__c = 'blah';
        waterMapSub.WaterMap__r.Site_Manager__c = contact.id;
        waterMapSub.WaterMap__r.Primary_Contact__c = contact.id;
        waterMapSub.WaterMap__r.Secondary_Contact__c = contact.id;
        controller.RefreshSiteMgr();
        controller.RefreshPrimaryContact();
        controller.RefreshSecondaryContact();
        waterMapSub.WaterMap__r.Site_Manager__c = null;
        waterMapSub.WaterMap__r.Primary_Contact__c = null;
        waterMapSub.WaterMap__r.Secondary_Contact__c = null;
        controller.RefreshSiteMgr();
        controller.RefreshPrimaryContact();
        controller.RefreshSecondaryContact();
        controller.RefreshPostalAddress();
        controller.postalAddressIsSiteAddress = true;
        controller.RefreshPostalAddress();
        waterMapSub.WaterMap__r.Site_Manager__c = contact.id;
        waterMapSub.WaterMap__r.Primary_Contact__c = contact.id;
        waterMapSub.WaterMap__r.Secondary_Contact__c = contact.id;
        waterMapSub.WaterMap__r.Site_Organisation_Name__c = 'Test';
        waterMapSub.WaterMap__r.Preferred_Postal_Contact_Type__c = 'Secondary';
        controller.RefreshPostalAddress();
        waterMapSub.WaterMap__r.Preferred_Postal_Contact_Type__c = 'Site Manager';
        controller.RefreshPostalAddress();
        waterMapSub.WaterMap__r.Preferred_Postal_Contact_Type__c = 'Primary';
        controller.RefreshPostalAddress();
        waterMAPSub.Watermap__r.ANZSIC__c = anzic.id;
        controller.Save();
        controller.Next();
        waterMapSub.Status__c = 'Not Started';
        waterMapSub.Authorised_By__c = null;
        waterMapSub.Prepared_By__c = null;
        controller.Next();
        controller.NoOp();
        String url = controller.googleProcessBreakdownPieChartURL;

        Test.stopTest();

    }
}