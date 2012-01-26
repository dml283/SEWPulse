public without sharing class WaterMAPUtil {
    /**************************************************************************/
    /*  Description:
    /*      Generic utility class for WaterMAP
    /*      DenormPrimaryConsolidatedAcct()
    /*          Denormalises the billing acct from the waterMap to the
    /*          consolidated acct as the primary
    /*      UpdateBAcctWMAPIds()
    /*          Updates the WaterMAP Id on the BAcct from the watermap
    /*      UpdateContactRoles()
    /*          updates the customer's contact roles from the watermap
    /*      ActivateWaterMAPs()
    /*          Creates a new submission for a watermap
    /*
    /*  Change History:
    /*      D.Thong     12-May-2011     Created
    /**************************************************************************/

    /* CONSTANTS */
    // current period is stored in a custom setting
    public static final String CURRENT_PERIOD;
    public static final string PREVIOUS_PERIOD;
    public static final List<String> PREVIOUS_PERIODS_DESC;
    private static final Integer PREVIOUS_PERIODS_DESC_LEN = 10;

    /* PUBLIC METHODS */

    // Updates the WaterMAP
    public static void UpdateWaterMAP(WaterMAP__c wmap) {
        update wmap;
    }

    // Updates the WaterMAP Submission
    public static void UpdateWaterMAPSubmission(WaterMAP_Submission__c sub) {
        update sub;
    }

    // Denormalises the billing account on the watermap to the consolidated acct as primary
    public static void DenormPrimaryConsolidatedAcct(List <Id> wMAP_Ids) {

        List <WaterMAP__c> wMAPs = ([select Billing_Account__c,
                                        (select Id, Billing_Account__c, Primary__c
                                         from WaterMAP_Consolidated_Accounts__r)
                                        from WaterMAP__c
                                        where Id = :wMap_Ids]);


        List <WaterMAP_Consolidated_Accounts__c> wMap_Cons_Accts_ToAdd = new List <WaterMAP_Consolidated_Accounts__c>();
        List <WaterMAP_Consolidated_Accounts__c> wMap_Cons_Accts_ToUpdate = new List <WaterMAP_Consolidated_Accounts__c>();

        for (WaterMap__c wMap : wMaps) {
            Boolean found = false;

            for (WaterMAP_Consolidated_Accounts__c con : wMap.WaterMAP_Consolidated_Accounts__r) {
                // set the new primary and unset old ones
                if (con.Billing_Account__c == wMap.Billing_Account__c) {
                    found=true;
                    if (con.Primary__c == false) {
                        con.Primary__c = true;
                        wMap_Cons_Accts_ToUpdate.add(con);
                    }
                }
                if (con.Billing_Account__c != wMap.Billing_Account__c && con.Primary__c == true) {
                    con.Primary__c = false;
                    wMap_Cons_Accts_ToUpdate.add(con);
                }
            }

            // we didn't update an existing one, so insert
            if (wMap.Billing_Account__c != null && !found) {
                // add the primary
                WaterMAP_Consolidated_Accounts__c wMap_Cons_Acct = new WaterMAP_Consolidated_Accounts__c();
                wMap_Cons_Acct.Billing_Account__c = wMap.Billing_Account__c;
                wMap_Cons_Acct.Primary__c = true;
                wMap_Cons_Acct.WaterMap__c = wMap.id;
                wMap_Cons_Accts_ToAdd.add(wMap_Cons_Acct);
            }
            found = false;
        }

        if (!wMap_Cons_Accts_ToUpdate.isEmpty()) {
            update wMap_Cons_Accts_ToUpdate;
        }
        if (!wMap_Cons_Accts_ToAdd.isEmpty()) {
            insert wMap_Cons_Accts_ToAdd;
        }
    }

    // updates the WaterMAP Id on the BAcct from the watermap
    public static void UpdateBAcctWMAPIds(Map <Id, Id> bAcctIdToWMapId) {
        List <Billing_Account__c> bAcctsToUpdate = new List <Billing_Account__c>();

        for (Id bAcctId : bAcctIdToWMapId.keySet()) {
            Billing_Account__c bAcct = new Billing_Account__c(Id = bAcctId,
                                                                WaterMAP__c = bAcctIdToWMapId.get(bAcctId));
            bAcctsToUpdate.add(bAcct);
        }

        if (!bAcctsToUpdate.isEmpty())
            update bAcctsToUpdate;
    }

    // Updates the WaterMAP contact roles based on the WaterMAP contacts
    public static void UpdateContactRoles(Set<Id> accountIds) {
        List <Account> accounts = [select id,
                                        (select primary_contact__c, secondary_contact__c, site_manager__c
                                         from WaterMAPs__r),
                                        (select id, role, isprimary, contactid, accountid from AccountContactRoles
                                         where role like 'WaterMAP%')
                                    from Account
                                    where Id in :accountIds];
        List <AccountContactRole> newRoles = new List <AccountContactRole>();
        List <AccountContactRole> oldRoles = new List <AccountContactRole>();

        for (Account a : accounts) {
            Set <Id> wMapPrimaryConIds = new Set<Id>();
            Set <Id> wMapSecondaryConIds = new Set<Id>();
            Set <Id> wMapSitemgrConIds = new Set<Id>();

            Set <Id> rolePrimaryConIds = new Set<Id>();
            Set <Id> roleSecondaryConIds = new Set<Id>();
            Set <Id> roleSitemgrConIds = new Set<Id>();

            List <WaterMAP__c> wmaps = a.WaterMAPs__r;
            List <AccountContactRole> roles = a.AccountContactRoles;

            // First, get a set of each type of contacts on the watermap
            if (wmaps != null) {
                for (WaterMAP__c w : wmaps) {
                    if (w.Primary_Contact__c != null) wMapPrimaryConIds.add(w.Primary_Contact__c);
                    if (w.Secondary_Contact__c != null) wMapSecondaryConIds.add(w.Secondary_Contact__c);
                    if (w.site_manager__c != null) wMapSitemgrConIds.add(w.site_manager__c);
                }
            }

            // next, get a set of each type of contact in the account contact roles
            if (roles != null) {
                for (AccountContactRole r : roles) {
                    if (r.role == 'WaterMAP Contact - Primary') rolePrimaryConIds.add(r.ContactId);
                    if (r.role == 'WaterMAP Contact - Secondary') roleSecondaryConIds.add(r.ContactId);
                    if (r.role == 'WaterMAP Site Manager') roleSitemgrConIds.add(r.ContactId);
                }

            }
            // add new roles
            newRoles.addAll(addNewRoles(a.Id, wMapPrimaryConIds, rolePrimaryConIds, 'WaterMAP Contact - Primary'));
            newRoles.addAll(addNewRoles(a.Id, wMapSecondaryConIds, roleSecondaryConIds, 'WaterMAP Contact - Secondary'));
            newRoles.addAll(addNewRoles(a.Id, wMapSitemgrConIds, roleSitemgrConIds, 'WaterMAP Site Manager'));

            // delete old roles
            oldRoles.addAll(delOldRoles(a.Id, wMapPrimaryConIds, rolePrimaryConIds, 'WaterMAP Contact - Primary', roles));
            oldRoles.addAll(delOldRoles(a.Id, wMapSecondaryConIds, roleSecondaryConIds, 'WaterMAP Contact - Secondary', roles));
            oldRoles.addAll(delOldRoles(a.Id, wMapSitemgrConIds, roleSitemgrConIds, 'WaterMAP Site Manager', roles));

        }
        if (!newRoles.isEmpty()) insert newRoles;
        if (!oldRoles.isEmpty()) delete oldRoles;

    }

    // when the watermap is activated, create a new submission
    // if no current one exists
    public static void ActivateWaterMAPs (List <Id> wMAPIds) {
        List <WaterMAP_Submission__c> subs = new  List <WaterMAP_Submission__c>();

        // WMAP must be active and have active submissions
        for (WaterMAP__c wmap : [select id, customer__c, Start_Year__c
                                 from   WaterMAP__c
                                 where  id in :wMAPIds
                                 and    Status__c = 'Active'
                                 and    Count_of_Active_Submissions__c = 0]) {

            String year;

            if (wmap.Start_Year__c > CURRENT_PERIOD)
                year = wmap.Start_Year__c;
            else
                year = CURRENT_PERIOD;

            subs.add(new WaterMAP_Submission__c (WaterMAP__c = wmap.id,
                                                 Customer__c = wmap.customer__c,
                                                 Year__c = year));

        }

        if (!subs.isEmpty())
            insert subs;
    }

    // when the watermap is inactivated, cancel any current submissions
    public static void InactivateWaterMAPs (List <Id> wMAPIds) {
        List <WaterMAP_Submission__c> subs = new  List <WaterMAP_Submission__c>();

        for (WaterMAP_Submission__c sub : [select id from WaterMAP_Submission__c
                                           where  WaterMAP__c in :wMAPIds
                                           and    Active__c = 'Y'
                                           and    WaterMAP__r.Status__c = 'Inactive']) {
            sub.Status__c = 'Cancelled';
            subs.add(sub);
        }

        if (!subs.isEmpty()) update subs;

    }

    // when the watermap submission is no longer active, create next years one
    // by taking the greater of the current year + 1 or the current period
    // rollover forecasts to prior year and zero out next years forecast
    public static void CreateNextYearsSubmissions (List <Id> createNextYearSubIds) {
        List <WaterMAP_Submission__c> newsubs = new List <WaterMAP_Submission__c>();
        List <WaterMAP_Submission__c> subs = [select Year__c, WaterMAP__c,
                                                        Active__c, Customer__c,
                                                        Rolled_Over_Flag__c,
                                                        WaterMAP__r.Forecast_Sewage_Disposal_Pct__c,
                                                        WaterMAP__r.Forecast_Trade_Waste_Cost_Pct__c,
                                                        WaterMAP__r.Forecast_Water_Cost_Pct__c,
                                                        WaterMAP__r.Forecast_Water_Use_Pct__c,
                                                        WaterMAP__r.Prior_Yr_Fcst_Sewage_Disposal_Cost_Pct__c,
                                                        WaterMAP__r.Prior_Yr_Fcst_Trade_Waste_Cost_Pct__c,
                                                        WaterMAP__r.Prior_Yr_Fcst_Water_Cost_Pct__c,
                                                        WaterMAP__r.Prior_Yr_Fcst_Water_Use_KL_Pct__c
                                              from  WaterMAP_Submission__c
                                              where id in :createNextYearSubIds];
        List <WaterMAP__c> wmaps = new List <WaterMAP__c>(); // watermaps to rollover

        for (WaterMAP_Submission__c sub : subs) {
            if (sub.Active__c == 'N') {
                // create the next years sub
                String nextYear = getYearAfterPeriod(sub.Year__c);
                if (nextYear < CURRENT_PERIOD) nextYear = CURRENT_PERIOD;

                newsubs.add(new WaterMAP_Submission__c (WaterMAP__c = sub.WaterMAP__c,
                                                        Year__c = nextYear,
                                                        Customer__c = sub.Customer__c ));
                // set a flag to prevent a new record from being created again
                sub.Rolled_Over_Flag__c = true;

                // rollover forecast to prior year
                WaterMAP__c wmap = sub.WaterMAP__r;
                wmap.Prior_Yr_Fcst_Sewage_Disposal_Cost_Pct__c = wmap.Forecast_Sewage_Disposal_Pct__c;
                wmap.Prior_Yr_Fcst_Trade_Waste_Cost_Pct__c = wmap.Forecast_Trade_Waste_Cost_Pct__c;
                wmap.Prior_Yr_Fcst_Water_Cost_Pct__c = wmap.Forecast_Water_Cost_Pct__c;
                wmap.Prior_Yr_Fcst_Water_Use_KL_Pct__c = wmap.Forecast_Water_Use_Pct__c;

                wmap.Forecast_Sewage_Disposal_Pct__c = 0;
                wmap.Forecast_Trade_Waste_Cost_Pct__c = 0;
                wmap.Forecast_Water_Cost_Pct__c = 0;
                wmap.Forecast_Water_Use_Pct__c = 0;

                wmaps.add(wmap);
            }
        }

        Savepoint sp = Database.setSavePoint();

        if (!newsubs.isEmpty()) {
            try {
                insert newsubs;
                update subs;
                update wmaps;
            } catch (Exception e) {
                Database.rollback(sp);
                throw(e);
            }
        }
    }

    // Submits the submission for approval
    // the email is done in workflow
    public static void SubmitWMAPSubmission(WaterMAP_Submission__c wsub) {
        wsub.Status__c = 'Submitted for Approval';
        wsub.Submitted_Datetime__c = System.now();
        wsub.Approver__c = wsub.Customer__r.OwnerId;
        update wsub;
    }

    public static User GetKeyAccountMgrForPortalUser() {
        // assume that the user is always there!
        User user = [Select ContactId, AccountId
                    From  User
                    Where Id = :UserInfo.getUserId() LIMIT 1];

        If (user.AccountId != null) {
            Account account = [Select OwnerId, Is_Key_Customer__c from Account
                            Where Id = :user.AccountId LIMIT 1];


            return WaterMAPUtil.GetUser(account.OwnerId);
        }
        return null;
    }

    // used to query contact information
    public static Contact QueryContact(Id contactId) {
        // retrieve the contact based on Id
        List<Contact> contacts;
        try {
            contacts = [SELECT Name, FirstName, LastName, Title, Phone, Email, MobilePhone,
                                MailingStreet, MailingState, MailingPostalCode, MailingCity,
                                Organisation_Name__c
                        FROM    Contact
                        WHERE   Id = :contactId LIMIT 1];
        } catch (QueryException e) {
            ApexPages.addMessages(e);

        }

        if (!contacts.isEmpty()) {
            return contacts[0];
        }

        return null;

    }

    // used to query waterMAP consolidated Account information
    public static List<WaterMAP_Consolidated_Accounts__c> getWaterMAPConsolAccs(Id waterMAPId){
        return [Select Watermap__c, Id, Billing_Account__c, Primary__c,
                            Site_Address__c, Billing_Account__r.HiAF_Account_Number_Check_Digit__c
                        From WaterMAP_Consolidated_Accounts__c
                        where WaterMAP__c = :waterMAPId];
    }

    // used to query all consumption charges for particular waterMAP, in order
    public static List<Consumption_and_Charge__c> getWaterMAPAllChargesInOrder(Id waterMapId, List<String> yearsToDisplay){
        List<WaterMAP_Consolidated_Accounts__c> waterMAPConsolAccs = getWaterMAPConsolAccs(waterMapId);
        Set<Id> billingAccIds = new Set<Id>();
        for(WaterMAP_Consolidated_Accounts__c acc: waterMAPConsolAccs){
            billingAccIds.add(acc.Billing_Account__c);
        }
        return [Select Trade_Waste_Volume__c, Sewage_Disposal_Volume__c,
                            Water_Volume__c, Water_Cost__c, Trade_Waste_Cost__c,
                            Sewage_Disposal_Cost__c, Name, Financial_Year__c,
                            Billing_Account__r.Name
                        From Consumption_and_Charge__c
                        where Financial_Year__c in :yearsToDisplay
                            and Billing_Account__c in :billingAccIds
                            order by End_Date__c ASC];
    }

    // used to roll-up all consumption charges for particular waterMAP, in order
    public static List<Consumption_and_Charge__c> getWaterMAPRolledUpChargesInOrder(Id waterMapId, List<String> yearsToDisplay){
        List<Consumption_and_Charge__c> priorCharges = getWaterMAPAllChargesInOrder(waterMapId, yearsToDisplay);
        List<String> orderedChargesPeriods = new List<String>();
        Map<String, Consumption_and_Charge__c> baselineWaterUseRecordsMapByPeriod = new Map<String, Consumption_and_Charge__c>();
        for(Consumption_and_Charge__c charge: priorCharges){
            Consumption_and_Charge__c chargeInMap;
            if(baselineWaterUseRecordsMapByPeriod.containsKey(charge.Name)){
                chargeInMap = baselineWaterUseRecordsMapByPeriod.get(charge.Name);
            }else{
                chargeInMap = new Consumption_and_Charge__c();
                chargeInMap.Name = charge.Name;
                chargeInMap.Financial_Year__c = charge.Financial_Year__c;
                chargeInMap.Water_Volume__c = 0;
                chargeInMap.Water_Cost__c = 0;
                chargeInMap.Sewage_Disposal_Cost__c = 0;
                chargeInMap.Trade_Waste_Cost__c = 0;
                baselineWaterUseRecordsMapByPeriod.put(charge.Name, chargeInMap);
                orderedChargesPeriods.add(charge.Name);
            }
            chargeInMap.Water_Volume__c += charge.Water_Volume__c;
            chargeInMap.Water_Cost__c += charge.Water_Cost__c;
            chargeInMap.Sewage_Disposal_Cost__c += charge.Sewage_Disposal_Cost__c;
            chargeInMap.Trade_Waste_Cost__c += charge.Trade_Waste_Cost__c;
        }
        List<Consumption_and_Charge__c> rolledUpChargesOrdered = new List<Consumption_and_Charge__c>();
        for(String periodName: orderedChargesPeriods){
            rolledUpChargesOrdered.add(baselineWaterUseRecordsMapByPeriod.get(periodName));
        }
        return rolledUpChargesOrdered;
    }

    // returns selectOptions of all available contacts for a customer
    public static List<SelectOption> getSelectableContacts(Id customerId){
        List<SelectOption> selectableContacts = new List<SelectOption>();
        List<Contact> contacts = [Select id, Name from Contact where accountid =:customerId order by Lastname];
        selectableContacts.add(new SelectOption('', '--None--'));
        for(Contact con: contacts){
            selectableContacts.add(new SelectOption(con.id, con.Name));
        }
        return selectableContacts;
    }

    // returns the string representation of the year before the specified year
    public static String getYearBeforePeriod(String thisPeriod){
        String[] splittedStr = thisPeriod.split('/',0);
        Integer prevYr1 = Decimal.valueOf(splittedStr[0]).intValue()-1;
        Integer prevYr2 = Decimal.valueOf(splittedStr[1]).intValue()-1;
        return ''+prevYr1+'/'+((prevYr2<10)?('0'+prevYr2):(''+prevYr2));
    }

    // returns the string representation of the year after the specified year
    public static String getYearAfterPeriod(String thisPeriod){
        String[] splittedStr = thisPeriod.split('/',0);
        Integer prevYr1 = Decimal.valueOf(splittedStr[0]).intValue()+1;
        Integer prevYr2 = Decimal.valueOf(splittedStr[1]).intValue()+1;
        return ''+prevYr1+'/'+((prevYr2<10)?('0'+prevYr2):(''+prevYr2));
    }

    // get the last N years in ascending order, including the current year
    public static List<String> getLastNYearsInOrder(String currentYear, Integer noOfYears){
        if(noOfYears<1) return null;
        if(noOfYears<2) return new String[]{currentYear};
        String[] yearsToDisplay = new String[noOfYears];
        yearsToDisplay[noOfYears-1] = currentYear;
        for(Integer i = noOfYears - 2 ; i>=0 ; i--){
            yearsToDisplay[i] = WaterMAPUtil.getYearBeforePeriod(yearsToDisplay[i+1]);
        }
        return yearsToDisplay;
    }

    // for consumption and changes - get the month / quarter period without
    // the year component
    public static String getPeriodWithoutYear(String periodWithYear){
        return periodWithYear.substring(0,periodWithYear.indexof(' '));
    }

    // queries user details
    public static User GetUser(Id userId) {
        return [select Name, Phone, Email from user where Id = :userId LIMIT 1][0];
    }

    // used to generate random IDs for wrapper class (for javascript)
    public static String generateRandomID(){
        return (''+Datetime.now().getTime()+(Math.roundToLong(Decimal.valueof(Math.random()*10000))));
    }
    /* INNER CLASSES */
    // class to represent a KBAI year table
    public class KBAIYearTable{
        public String year{get;private set;}
        public List<KBAILine> kbaiLines{
            get{
                if(kbaiLines == null){
                    kbaiLines = new List<KBAILine>();
                }return kbaiLines;
            }set;
        }
        public KBAIYearTable(String year){
            this.year = year;
        }
        public KBAIYearTable(String year, List<KBAILine> kbaiLines){
            this(year);
            this.kbaiLines = kbaiLines;
        }
    }
    // class to represent a KBAI line fully, including the kbai, usage and calculated average
    public class KBAILine {
        public Key_Business_Activity_Indicator__c kbai {
            get{
                if(kbai==null){
                    kbai = new Key_Business_Activity_Indicator__c();
                }return kbai;
            }
            set;
        }
        public Integer rowNum { get; set; }

        public String  periodName {
            get{
                return kbai.Period__c;
            }
            set{
                kbai.Period__c = value;
            }
        }
        public String  year {
            get{
                return kbai.year__c;
            }
            set{
                kbai.year__c = value;
            }
        }
        public Decimal kbaiCount {
            get{
                return kbai.Count__c;
            }
            set{
                kbai.Count__c = value;
            }
        }
        public Decimal usage {get; set;}
        public Decimal klperkbai {
            get {
                if (kbaiCount != null && usage != null && kbaiCount != 0) {
                    return (usage / kbaiCount).setScale(2);
                }
                return null;
            }
        }

        public KBAILine(String periodName, String year, Decimal kbaiCount, Decimal usage) {
            this.periodName = periodName;
            this.year = year;
            this.kbaiCount = kbaiCount;
            this.usage = usage;
        }
        public KBAILine(String periodName, String year, Decimal kbaiCount, Decimal usage, Date endDate, Id watermapId) {
            this(periodName, year, kbaiCount, usage);
            this.kbai.End_Date__c = endDate;
            this.kbai.WaterMAP__c = watermapId;
        }
        public KBAILine(Key_Business_Activity_Indicator__c existingKBAI, Decimal usage){
            this.kbai = existingKBAI;
            this.usage = usage;
        }
    }
    /* PRIVATE METHODS */

    private static List <AccountContactRole> AddNewRoles (Id accntId, Set<Id> wMapConIds, Set<Id> roleConIds, String role ) {

        List <AccountContactRole> newRoles = new List <AccountContactRole>();

        Set <Id> newConIds = wMapConIds.clone();
        newConIds.removeAll(roleConIds);

        for (Id cId : newConIds) {
            AccountContactRole newRole = new AccountContactRole (AccountId = accntId,
                                                                ContactId = cId,
                                                                Role = role);
            newRoles.add(newRole);
        }

        return newRoles;
    }

    private static List <AccountContactRole> DelOldRoles (Id accntId, Set<Id> wMapConIds, Set<Id> roleConIds, String role, List <AccountContactRole> roles) {

        List <AccountContactRole> oldRoles = new List <AccountContactRole>();

        Set <Id> oldConIds = roleConIds.clone();
        oldConIds.removeAll(wMapConIds);

        for (Id cId : oldConIds) {
            for (AccountContactRole r : roles)
                if (r.ContactId == cId && r.role == role && !r.IsPrimary)
                    oldRoles.add(new AccountContactRole(Id = r.Id));
        }

        return oldRoles;
    }

    // gets the current period from the custom settings
    private static String GetCurrentPeriod() {
        // retrieve from watermap settings
        WaterMAPSettings__c settings = WaterMAPSettings__c.getInstance();
        return settings.Current_Period__c;
    }

    /* STATIC INITIALISERS */
    static {
        CURRENT_PERIOD = GetCurrentPeriod();
        PREVIOUS_PERIOD = getYearBeforePeriod(CURRENT_PERIOD);
        PREVIOUS_PERIODS_DESC = new List<String>();
        PREVIOUS_PERIODS_DESC.add(CURRENT_PERIOD);
        PREVIOUS_PERIODS_DESC.add(PREVIOUS_PERIOD);
        String period = PREVIOUS_PERIOD;
        for(Integer i = PREVIOUS_PERIODS_DESC_LEN - PREVIOUS_PERIODS_DESC.size() ; i > 0 ; i-- ){
            period = getYearBeforePeriod(period);
            PREVIOUS_PERIODS_DESC.add(period);
        }
    }
}