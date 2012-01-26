public without sharing class CaseUtil {

/*
    Type:       Utility Class
    Purpose:    SetCaseDueDate () - sets the due date based on default offset and daily hours

    Used By:    CaseTrigger
    ---------------------------------------------------------------
    History:
        13-Sep-2011 - D.Thong (SFDC)    Created
*/


    public final static Id DEFAULT_BUSINESSHOURS_ID;
    public final static Id NOTICE_OF_SALE_RECORDTYPE_ID;
    public final static Id SMR_RECORDTYPE_ID;
    public final static Id INSURANCECLAIM_RECORDTYPE_ID;
    public final static Id COMPLAINT_RECORDTYPE_ID;

    private static final Set<String> LEGAL_CLASSIFICATION_CODES = new Set<String>{'LT', 'LS', 'L1', 'L2'};
    private static final Set<String> CAVEAT_CLASSIFICATION_CODES = new Set<String>{'CV'};
    private static final Set<String> DIALYSIS_CLASSIFICATION_CODES = new Set<String>{'DM'};
    private static final Map<Id,RecordType> CASE_RECORD_TYPE_MAP;
    private static final Id PORTAL_CASE_QUEUE_ID;
    
    static{
        String queueName ='Web Cases';
        String queuesObjectType ='Case';
        PORTAL_CASE_QUEUE_ID = [Select Id, QueueId from QueueSobject where Queue.Name = :queueName and SobjectType = :queueSObjectType].QueueId;
    }

    // Set the Case Due Date
    public static void SetCaseDueDate(List <Case> cases) {

        Decimal dueDateOffsetDays = SystemSettings__c.getInstance().Default_Case_DueDate_Offset__c;
        Decimal dailyBusinessHours = SystemSettings__c.getInstance().Default_Case_Daily_Business_Hours__c;
        Decimal ewovAssistedDueDateOffsetDays = SystemSettings__c.getInstance().Default_EWOV_Assisted_DueDate_Offset__c;
        Decimal ewovInvestigatedDueDateOffsetDays = SystemSettings__c.getInstance().Default_EWOV_Investigative_DueDate_Offse__c;

        if (dueDateOffsetDays == null) dueDateOffsetDays = 10;
        if (dailyBusinessHours == null) dailyBusinessHours = 10;
        if (ewovAssistedDueDateOffsetDays == null) ewovAssistedDueDateOffsetDays = 14;
        if (ewovInvestigatedDueDateOffsetDays == null) ewovInvestigatedDueDateOffsetDays = 14;


        for (Case c : cases) {
            // add the offset days in business hours
            Datetime dueDateTime;

            if (c.Complaint_Type__c == 'EWOV') {
                Datetime startdate;
                if (c.CreatedDate == null)
                    startDate = system.now();
                else
                    startDate = c.CreatedDate;
                if (c.EWOV_Type__c == 'Assisted') {
                    dueDateTime = BusinessHours.add(DEFAULT_BUSINESSHOURS_ID, startDate, (ewovAssistedDueDateOffsetDays * 60 * 60 * dailyBusinessHours * 1000L).longValue() + 1);
                } else {
                    dueDateTime = BusinessHours.add(DEFAULT_BUSINESSHOURS_ID, startDate, (ewovInvestigatedDueDateOffsetDays * 60 * 60 * dailyBusinessHours * 1000L).longValue() + 1);
                }
            }
            else {
                dueDateTime = BusinessHours.add(DEFAULT_BUSINESSHOURS_ID, system.now(), (dueDateOffsetDays * 60 * 60 * dailyBusinessHours * 1000L).longValue() + 1);
            }

            if (c.Due_Date__c == null || c.Complaint_Type__c != 'EWOV')
                c.Due_Date__c = dueDatetime.date();
        }
    }

    // Set defaults for Notice of Sale
    public static void SetNOSDefaults(List<Case> cases) {
        for (Case c : cases) {
            // set the billing account to the vendor billing account
            if (c.Billing_Account__c != c.Vendor_Billing_Account__c
                        && c.Vendor_Billing_Account__c != null)
                c.Billing_Account__c = c.Vendor_Billing_Account__c;

            // set the purchaser tot he tenant for a Tenant is purchaser
            if (c.Purchaser_Billing_Account__c != c.Tenant_Billing_Account__c
                        && c.Tenant_Billing_Account__c != null
                        && c.Type_of_Sale__c == 'Tenant is Purchaser') {
                c.Purchaser_Billing_Account__c = c.Tenant_Billing_Account__c;
            }
        }
    }

    // Set Customer Classification Flags for Notice of Sale
    /*public static void setNOSClassificationFlags(List<Case> cases){
        Set<Id> bAccIds = new Set<Id>();
        Map<Id, Id> caseIdToBillAccId = new Map<Id, Id>();
        for (Case c : cases){
            bAccIds.add(c.Billing_Account__c);
        }

    }*/

    // Set Customer Classification Flags for Notice of Sale
    public static void setNOSClassificationFlags(List<Case> cases){
        Set<Id> bAccIds = new Set<Id>();
        Map<Id, Id> billAccIdToCaseId = new Map<Id, Id>();
        Map<Id, Id> caseIdToCustAccId = new Map<Id, Id>();
        Map<Id, Set<String>> custAccIdToCustClasses = new Map<Id, Set<String>>();

        for (Case c : cases){
            bAccIds.add(c.Billing_Account__c);
            billAccIdToCaseId.put(c.Billing_Account__c, c.Id);
        }
        Set<Id> custIds = new Set<Id>();
        for (Billing_Account__c ba : [SELECT Customer__c FROM Billing_Account__c WHERE Id IN :bAccIds]){
            custIds.add(ba.Customer__c);
            caseIdToCustAccId.put(billAccIdToCaseId.get(ba.Id), ba.Customer__c);
        }
        List<Account> custAndCustCodes = new List<Account>();
        system.debug('### DEBUG Legal Class Codes = ' + LEGAL_CLASSIFICATION_CODES);
        system.debug('### DEBUG Caveat Class Codes = ' + CAVEAT_CLASSIFICATION_CODES);
        system.debug('### DEBUG Dialysis Class Codes = ' + DIALYSIS_CLASSIFICATION_CODES);
        custAndCustCodes =  [SELECT   Id
                                    , Name
                                    , ( SELECT    Id
                                                , Name
                                                , Classification__r.Name
                                                , Is_Active__c
                                        FROM    Customer_Warnings__r
                                        WHERE   Is_Active__c = TRUE
                                            AND (Classification__r.Name IN :LEGAL_CLASSIFICATION_CODES
                                            OR  Classification__r.Name IN :CAVEAT_CLASSIFICATION_CODES
                                            OR  Classification__r.Name IN :DIALYSIS_CLASSIFICATION_CODES)
                                        )
                                    FROM Account
                                    WHERE Id IN :custIds
                            ];
        //List<Customer_Classification__c> testCC = [SELECT Id, Name, Customer__c, Classification__r.Name FROM Customer_Classification__c WHERE Customer__c IN :custIds];
        //system.debug('#### Test Classifications = ' + testCC);

        system.debug('### DEBUG: Customers with Classification Codes: ' + custAndCustCodes);
        for(Account a : custAndCustCodes){
            List<Customer_Classification__c> custClass_LIST = a.Customer_Warnings__r;
            system.debug('### DEBUG: Cust Classes LIST = ' + custClass_LIST);

            Set<String> custClasses = new Set<String>();
            for(Customer_Classification__c cc : custClass_LIST){
                custClasses.add(cc.Classification__r.Name);
            }
            system.debug('### DEBUG: Classification Codes 1: ' + custClasses);
            custAccIdTocustClasses.put(a.Id, custClasses);
        }

        for(Case c : cases){
            Set<String> custClasses = new Set<String>();
            Id accId = caseIdToCustAccId.get(c.Id);
            custClasses = custAccIdToCustClasses.get(accId);
            system.debug('### DEBUG: Customer Classifciations 2 = ' + custClasses);
            if (custClasses.contains('LT') || custClasses.contains('LS') || custClasses.contains('L1') || custClasses.contains('L2')){
                c.Legal_Customer__c = TRUE;
            } else {
                c.Legal_Customer__c = FALSE;
            }
            if (custClasses.contains('CV')){
                c.Caveat_Customer__c = TRUE;
            } else {
                c.Caveat_Customer__c = FALSE;
            }
            if (custClasses.contains('DM')){
                c.Dialysis_Customer__c = TRUE;
            } else {
                c.Dialysis_Customer__c = FALSE;
            }
        }
    }

    // Default the customer from the billing account
    public static void DefaultCaseFieldsFromBAcct(List<Case> cases) {
        Set<Id> bAcctIds = new Set<Id>();
        Map<Id, Billing_Account__c> bAcctIdMap = new Map<Id, Billing_Account__c>();

        // get a set of unique billing account its from the case
        for (Case c : cases) {
            bAcctIds.add(c.Billing_Account__c);
        }

        // generate a map of bacct id to customer id
        for (Billing_Account__c ba : [select customer__c, property__c from billing_account__c where id in :bAcctIds]) {
            bAcctIdMap.put(ba.id, ba);
        }

        // update the case to the new customer
        for (Case c : cases) {
            if (c.AccountId == null)
                c.AccountId = bAcctIdMap.get(c.Billing_Account__c).customer__c;
            if (c.Property__c == null)
                c.Property__c = bAcctIdMap.get(c.Billing_Account__c).Property__c;
        }
    }

    // Jsun - Set Case Owner's Team Name to field for report, and if case owner is portal user & case is not closed, assign to portal queue
    public static void setCaseOwnerAndTeam(List<Case> cases){
        Set<Id> ownerIds = new Set<Id>();
        for(Case singleCase: cases){
            ownerIds.add(singleCase.ownerId);
        }
        Map<Id, User> ownersMap = new Map<Id, User>([Select Id, Profile.UserType, Team__c from User where id in :ownerIds]);
        for(Case singleCase: cases){
            if(ownersMap.get(singleCase.ownerId) != null){
                singleCase.HIDDEN_Owner_Team__c = ownersMap.get(singleCase.ownerId).Team__c;
                // check if owner is portal user
                if(!'Standard'.equals(ownersMap.get(singleCase.ownerId).Profile.UserType)){
                    if(!singleCase.isClosed){
                        singleCase.ownerId = PORTAL_CASE_QUEUE_ID ;
                    }
                }
            }
        }
    }

    // Jsun - Create and / or update Case type tasks (for show in interaction log)
    public static void createUpdateCaseDuplicateTask(List<Case> cases){
        // get existing activities from cases
        Set<String> caseIds = new Set<String>();
        for(Case caseRec: cases){
            if(caseRec.id!=null){
                caseIds.add(caseRec.id);
            }
        }
        List<Task> existingCaseDupTasks = [Select id, whatId, HIDDEN_Case_Type_Task_ID__c from Task where HIDDEN_Is_Case_Duplicate_Task__c = true and HIDDEN_Case_Type_Task_ID__c in :caseIds];
        Map<String, Task> existingCaseDupTasksMapToCaseId = new Map<String, Task>();
        for(Task tempTask: existingCaseDupTasks){
            existingCaseDupTasksMapToCaseId.put(tempTask.HIDDEN_Case_Type_Task_ID__c, tempTask);
        }
        List<Task> tasksToUpsert = new List<Task>();
        // update or create tasks
        for(Case caseRec: cases){
            Task caseTypeTask = existingCaseDupTasksMapToCaseId.get(caseRec.id);
            if(caseTypeTask == null){
                caseTypeTask = new Task(WhatId = ((caseRec.Billing_Account__c!=null)?(caseRec.Billing_Account__c):(caseRec.accountId)), HIDDEN_Is_Case_Duplicate_Task__c = true, HIDDEN_Case_Type_Task_ID__c = caseRec.id);
            }
            mapCaseFieldsToTaskFields(caseRec, caseTypeTask);
            tasksToUpsert.add(caseTypeTask);
        }
        // check if owner is active, if not assign to current user
        // then check if owner is portal user, if yes assign to integration user
        Set<Id> ownerIds = new Set<Id>();
        for(Task taskRec: tasksToUpsert){
            ownerIds.add(taskRec.ownerId);
        }
        // add current user id to check usertype
        ownerIds.add(UserInfo.getUserId());
        Map<Id, User> usersMap = new Map<Id, User>([Select id, Profile.UserType from User where id in :ownerIds and isActive = true]);
        for(Task taskRec: tasksToUpsert){
            if(!usersMap.containsKey(taskRec.ownerId)){
                taskRec.ownerId = UserInfo.getUserId();
            }
            // check if final assigned user is portal user - if yes, assign to integration
            if(!'Standard'.equals(usersMap.get(taskRec.ownerId).Profile.UserType)){
                taskRec.ownerId = PortalSettings__c.getInstance().Portal_Task_Default_User__c;
            }
        }
        System.debug(tasksToUpsert);
        upsert tasksToUpsert;
    }

    // Jsun - check and update flag on all billing accounts with open / just closed all ewov complaints
    public static void updateBillAcctEWOVflag(List<Case> cases){
        Set<Id> billAcctIds = new Set<Id>();
        for(Case caseRec: cases){
            if (caseRec.Billing_Account__c != null && caseRec.RecordTypeId == COMPLAINT_RECORDTYPE_ID)
                billAcctIds.add(caseRec.Billing_Account__c);
        }

        if (billAcctIds.isEmpty()) return;

        List<Billing_Account__c> billAccts= [Select id, Is_EWOV_Investigative_Complaint__c, Is_EWOV_Assisted_Complaint__c, (Select id, Complaint_Type__c, EWOV_Type__c from Cases__r where Complaint_Type__c = 'EWOV' and (EWOV_Type__c in ('Investigative', 'Assisted')) and IsClosed = false) from Billing_Account__c where id in :billAcctIds];
        updateSObjectEWOVflag(billAccts, 'Cases__r');
    }

    // Jsun - check and update flag on all customers with open / just closed all ewov complaints
    public static void updateCustEWOVflag(List<Case> cases){
        Set<Id> custIds = new Set<Id>();
        for(Case caseRec: cases){
            if (caseRec.AccountId != null && caseRec.RecordTypeId == COMPLAINT_RECORDTYPE_ID)
                custIds.add(caseRec.AccountId);
        }

        if (custIds.isEmpty()) return;

        List<Account> custs = [Select id, Is_EWOV_Investigative_Complaint__c, Is_EWOV_Assisted_Complaint__c, (Select id, Complaint_Type__c, EWOV_Type__c from Cases where Complaint_Type__c = 'EWOV' and (EWOV_Type__c in ('Investigative', 'Assisted')) and IsClosed = false) from Account where id in :custIds];
        updateSObjectEWOVflag(custs, 'Cases');
    }

    public static void UpdatePropertyInsuranceFlag(List<Case> cases) {
        Set<Id> propertyIds = new Set<Id>();
        List<Property__c> propertiesToUpdate = new List<Property__c>();

        for (Case c : cases) {
            if (c.property__c != null && c.RecordTypeId == INSURANCECLAIM_RECORDTYPE_ID) {
                propertyIds.add(c.property__c);
            }
        }

        if (propertyIds.isEmpty()) return;

        // Get the affected properties
        List<Property__c> properties = [Select id, Has_Insurance_Claim__c,
                                            (Select id from Cases__r where RecordType.DeveloperName = 'Insurance_Claim' and IsClosed = false LIMIT 1)
                                        from Property__c where id in :propertyIds];

        for (Property__c p : properties) {
            Boolean hasInsuranceClaim = false;
            if (!p.Cases__r.isEmpty()) hasInsuranceClaim = true;

            if (p.Has_Insurance_Claim__c && !hasInsuranceClaim) {
                p.Has_Insurance_Claim__c = false;
                propertiesToUpdate.add(p);
            } else if (!p.Has_Insurance_Claim__c && hasInsuranceClaim) {
                p.Has_Insurance_Claim__c = true;
                propertiesToUpdate.add(p);
            }
        }

        if (!propertiesToUpdate.isEmpty())
            update propertiesToUpdate;
    }

    public static void UpdateContactInsuranceFlag(List<Case> cases) {
        Set<Id> contactIds = new Set<Id>();
        List<Contact> contactsToUpdate = new List<Contact>();

        for (Case c : cases) {
            if (c.ContactId != null && c.RecordTypeId == INSURANCECLAIM_RECORDTYPE_ID) {
                contactIds.add(c.ContactId);
            }
        }

        if (contactIds.isEmpty()) return;

        // Get the affected properties
        List<Contact> contacts = [Select id, Has_Insurance_Claim__c,
                                            (Select id from Cases where RecordType.DeveloperName = 'Insurance_Claim' and IsClosed = false LIMIT 1)
                                        from Contact where id in :contactIds];

        for (Contact c : contacts) {
            Boolean hasInsuranceClaim = false;
            if (!c.Cases.isEmpty()) hasInsuranceClaim = true;

            if (c.Has_Insurance_Claim__c && !hasInsuranceClaim) {
                c.Has_Insurance_Claim__c = false;
                contactsToUpdate.add(c);
            } else if (!c.Has_Insurance_Claim__c && hasInsuranceClaim) {
                c.Has_Insurance_Claim__c = true;
                contactsToUpdate.add(c);
            }
        }

        if (!contactsToUpdate.isEmpty())
            update contactsToUpdate;
    }

    // Jsun - check cases if read date is less than 2 business days from today
    public static void checkSMRReadDateTwoBusinessDayFromToday(List<Case> cases){
        for(Case currentCase:cases){
            if(currentCase.recordTypeId == SMR_RECORDTYPE_ID &&
                    !currentCase.Is_SMR_Create_Performed__c && !currentCase.Is_SMR_Amend_Performed__c){
                if(currentCase.Contact_Type__c != 'B/O Tenant' &&
                        currentCase.Contact_Type__c != 'B/O Sale' &&
                        isLessThanTwoBusinessDaysFromToday(currentCase.Reading_Date__c)){
                    currentCase.Reading_Date__c.addError('Reading date must be specified to at least 2 business days after today');
                }
                if(currentCase.Contact_Type__c != 'B/O Tenant' &&
                        currentCase.Contact_Type__c != 'B/O Sale' &&
                        !isBusinessDay(currentCase.Reading_Date__c)) {
                    currentCase.Reading_Date__c.addError('Reading date must be a valid business day');
                }
            }
        }
    }

    // Jsun - on after insert, check if case type has auto-suspend AND case is not closed AND case auto suspend flag is on. if yes, set flag on billing account.
    public static void setBillAccAutoSuspendByCase(List<Case> cases){
        Set<Id> billAccsToAutoSuspend = new Set<Id>();
        for( Case caseRec: cases){
            if ((!caseRec.isClosed) && caseRec.Suspend_Billing__c && autoSuspendCaseTypeIdSet.contains(caseRec.RecordTypeId) && caseRec.Billing_Account__c != null){
                billAccsToAutoSuspend.add(caseRec.Billing_Account__c);
            }
        }
        if(billAccsToAutoSuspend.size()==0) return;

        // DT refactor to avoid query
        List<Billing_Account__c> billAccsToUpdate = new List<Billing_Account__c> ();
        for (Id bAcctId : billAccsToAutoSuspend) {
            billAccsToUpdate.add(new Billing_Account__c (id = bAcctId, HIDDEN_Is_Auto_Suspend_By_Case__c = true));
        }

        /*
        List<Billing_Account__c> billAccsToUpdate = [Select id from Billing_Account__c where id in :billAccsToAutoSuspend];
        for(Billing_Account__c billAcc: billAccsToUpdate){
            billAcc.HIDDEN_Is_Auto_Suspend_By_Case__c = true;
        }*/
        update billAccsToUpdate;
    }

    private static Set<Id> autoSuspendCaseTypeIdSet{
        get{
            if(autoSuspendCaseTypeIdSet==null){
                List<RecordType> recTypes = CaseTypeSettingUtil.getAutoSuspendCaseType();
                autoSuspendCaseTypeIdSet = new Set<Id>();
                for(RecordType rt: recTypes){
                    autoSuspendCaseTypeIdSet.add(rt.id);
                }
            }return autoSuspendCaseTypeIdSet;
        }set;
    }

    // Jsun - used in SMR View Extension
    public static boolean isLessThanTwoBusinessDaysFromToday(Date checkDate){
        if (checkDate == null) return false;
        Date twoBusinessDaysFromToday = Date.today().addDays(2);
        while((BusinessHours.diff(CaseUtil.DEFAULT_BUSINESSHOURS_ID,
                Datetime.newInstance(Date.today().year(),Date.today().month(),Date.today().day()),
                Datetime.newInstance(twoBusinessDaysFromToday.year(),twoBusinessDaysFromToday.month(),twoBusinessDaysFromToday.day())))<(16 * 60 * 60 * 1000L)){
            twoBusinessDaysFromToday = twoBusinessDaysFromToday.addDays(1);
        }
        if (twoBusinessDaysFromToday.daysBetween(checkDate)<0) return true;
        return false;
    }

    public static boolean isBusinessDay(Date checkDate) {
        if (checkDate == null) return true;

        // Add 1ms to today's date at noon and if its not the same day
        // then we are not in a business day
        Time noon = Time.newInstance(12, 0, 0, 0);
        Datetime dt = Datetime.newInstance(checkDate, noon);
        Date businessDate = BusinessHours.add(CaseUtil.DEFAULT_BUSINESSHOURS_ID, dt, 1).date();

        if (businessDate != checkDate)
            return false;

        return true;
    }
    
    public static void truncateAlertsInformationLongIntFields(List<Case> caseRecords){
        for(Case currentCase: caseRecords){
            if (currentCase.Alerts_Int_Long__c != null && currentCase.Alerts_Int_Long__c.length()>0 ) {
                Integer len = currentCase.Alerts_Int_Long__c.length();
                if (len > 255) len = 255;
                currentCase.Alerts_Int__c = currentCase.Alerts_Int_Long__c.substring(0, len-1);
    
            }else{
                currentCase.Alerts_Int__c = null;
            }
            if (currentCase.Information_Int_Long__c != null && currentCase.Information_Int_Long__c.length()>0) {
                Integer len = currentCase.Information_Int_Long__c.length();
                if (len > 255) len = 255;
                currentCase.Information_Int__c = currentCase.Information_Int_Long__c.substring(0, len-1);
            }else{
                currentCase.Information_Int__c = null;
            }
        }
    }

    private static void updateSObjectEWOVflag(List<Sobject> sObjects, String caseRelationshipFieldName){
        List<Sobject> sObjectsToUpdate = new List<Sobject>();
        for(Sobject sObjectRec: sObjects){
            List<Case> ewovComplaints = sObjectRec.getSObjects(caseRelationshipFieldName);
            // loop thru to check the type of EWOV complaint
            Boolean hasAssisted = false;
            Boolean hasInvestigative = false;
            Boolean addRow = false;

            if (ewovComplaints != null) {
                for (Case c : ewovComplaints) {
                    if (c.EWOV_Type__c == 'Assisted')
                        hasAssisted = true;
                    else if (c.EWOV_Type__c == 'Investigative')
                        hasInvestigative = true;
                }
            }

            if (!hasInvestigative){
                if((Boolean)sObjectRec.get('Is_EWOV_Investigative_Complaint__c')){
                    sObjectRec.put('Is_EWOV_Investigative_Complaint__c', false);
                    addRow = true;
                }
            }else{
                if(!((Boolean)sObjectRec.get('Is_EWOV_Investigative_Complaint__c'))){
                    sObjectRec.put('Is_EWOV_Investigative_Complaint__c', true);
                    addRow = true;
                }
            }

            if (!hasAssisted){
                if((Boolean)sObjectRec.get('Is_EWOV_Assisted_Complaint__c')){
                    sObjectRec.put('Is_EWOV_Assisted_Complaint__c', false);
                    addRow = true;
                }
            }else{
                if(!((Boolean)sObjectRec.get('Is_EWOV_Assisted_Complaint__c'))){
                    sObjectRec.put('Is_EWOV_Assisted_Complaint__c', true);
                    addRow = true;
                }
            }
            if (addRow) sObjectsToUpdate.add(sObjectRec);
        }
        update sObjectsToUpdate;
    }

    private static void mapCaseFieldsToTaskFields(Case caseRec, Task taskRec){
        taskRec.Subject = caseRec.Subject;
        taskRec.Description = caseRec.Description;
        taskRec.ActivityDate = ((caseRec.ClosedDate!=null)
                ?(Date.newInstance(caseRec.ClosedDate.year(),caseRec.ClosedDate.month(),caseRec.ClosedDate.day()))
                :(caseRec.Due_Date__c));
        RecordType crt = CASE_RECORD_TYPE_MAP.get(caseRec.recordTypeId);
        taskRec.Type = ((crt!=null)?(crt.Name):(null));
        taskRec.Group__c = caseRec.Type;
        taskRec.Category_Level_1__c = caseRec.Category_Level_1__c;
        taskRec.Category_Level_2__c = caseRec.Category_Level_2__c;
        taskRec.Category_Level_3__c = caseRec.Category_Level_3__c;
        taskRec.Hot_Issue__c = caseRec.Hot_Issues__c;
        taskRec.No_of_Contacts__c = caseRec.Number_of_contacts__c;
        taskRec.Mode__c = caseRec.Mode__c;
        taskRec.Priority = 'Business as Usual';
        if(caseRec.isClosed){
            taskRec.Status = 'Completed';
        }else if(caseRec.IsEscalated){
            taskRec.Status = 'Escalated';
        }else if('New'.equals(caseRec.Status)){
            taskRec.Status = 'Not Started';
        }else{
            taskRec.Status = 'In Progress';
        }
        taskRec.OwnerId = caseRec.OwnerId;
        if (!((String)taskRec.OwnerId).startsWith(User.sObjectType.getDescribe().getKeyPrefix())) {
            taskRec.ownerId = UserInfo.getUserId();
        } 
            
        taskRec.Priority = caseRec.Priority;
    }

    static {
        // get the default business hours
        DEFAULT_BUSINESSHOURS_ID = [Select Id from BusinessHours where isDefault=true LIMIT 1][0].id;
        CASE_RECORD_TYPE_MAP = new Map<Id, RecordType>([Select id, DeveloperName, Name from RecordType where SobjectType = 'Case']);

        for (RecordType recType : CASE_RECORD_TYPE_MAP.values()) {
            if (recType.DeveloperName == 'Notice_of_Sale')
                NOTICE_OF_SALE_RECORDTYPE_ID = recType.id;
            else if (recType.DeveloperName == 'Special_Meter_Read')
                SMR_RECORDTYPE_ID = recType.id;
            else if (recType.DeveloperName == 'Insurance_Claim')
                INSURANCECLAIM_RECORDTYPE_ID = recType.Id;
            else if (recType.DeveloperName == 'Complaint')
                COMPLAINT_RECORDTYPE_ID = recType.Id;
        }

    }

    private static TestMethod void TestMe() {
        Profile p = [select id from profile where name='SEW CSO (Customer Service Officer)'];
       User u = new User(alias = 'fgjdf', email='dfjdfh@dfhxfgh.com',
          emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
          localesidkey='en_US', profileid = p.Id,
          timezonesidkey='America/Los_Angeles', username='djgf@hjgfhj.com');
       insert u;

       System.runAs(u) {
            Id GeneralEnquiryRecordTypeId = [select id from RecordType where DeveloperName = 'General_Enquiry' and sObjectType = 'Case' LIMIT 1].id;
            Id ComplaintRecordTypeId = [select id from RecordType where DeveloperName = 'Complaint' and sObjectType = 'Case' LIMIT 1].id;
            // create account
            Account a = new Account(name='ABC');
            insert a;

            // create vendor billing account
            Billing_Account__c vendor = new Billing_Account__c();
            vendor.Customer__c = a.id;
            insert vendor;

            // create tenant billing account
            Billing_Account__c tenant = new Billing_Account__c();
            tenant.Customer__c = a.id;
            insert tenant;

            Case c = new Case (RecordTypeId = GeneralEnquiryRecordTypeId);

            insert c;
            system.assert([select Due_Date__c from Case where id = :c.id].Due_Date__c != null);

            Case c2 = new Case (RecordTypeId = GeneralEnquiryRecordTypeId, Billing_Account__c = vendor.id, Suspend_Billing__c = true);

            insert c2;
            system.assert([select HIDDEN_Owner_Team__c from Case where id = :c2.id].HIDDEN_Owner_Team__c == u.Team__c);
            system.assert([select AccountId from Case where id = :c2.id].AccountId == a.id);


            Case c3 = new Case (RecordTypeId = NOTICE_OF_SALE_RECORDTYPE_ID,
                                    Tenant_Billing_Account__c = tenant.id,
                                    Vendor_Billing_Account__c = vendor.id,
                                    Type_of_Sale__c = 'Tenant is Purchaser');

            insert c3;
            system.assert([select Billing_Account__c from Case where id = :c3.id].Billing_Account__c == c3.Vendor_Billing_Account__c);
            system.assert([select Purchaser_Billing_Account__c from Case where id = :c3.id].Purchaser_Billing_Account__c == c3.Tenant_Billing_Account__c);

            Set<String> casesIdsCreated = new Set<String>();
            casesIdsCreated.add(c.id);
            casesIdsCreated.add(c2.id);
            casesIdsCreated.add(c3.id);
            List<Task> caseDupTasks = [Select id from Task where HIDDEN_Case_Type_Task_ID__c in :casesIdsCreated and HIDDEN_Is_Case_Duplicate_Task__c = true];
            System.assertEquals(3, caseDupTasks.size());
            c2.Description += 'Testing update';
            c2.Status = 'In Progress';
            update c2;
            caseDupTasks = [Select id from Task where HIDDEN_Case_Type_Task_ID__c in :casesIdsCreated and HIDDEN_Is_Case_Duplicate_Task__c = true];
            System.assertEquals(3, caseDupTasks.size());
            caseDupTasks[0].Interaction_Type__c = 'Crap';
            update caseDupTasks[0];
            //caseDupTasks[0] = [Select id, Type, Interaction_Type__c from Task where id = :caseDupTasks[0].id];
            //System.assertEquals(caseDupTasks[0].Interaction_Type__c, caseDupTasks[0].Type);
       }

    }


    private static TestMethod void TestMe2() {
            Id GeneralEnquiryRecordTypeId = [select id from RecordType where DeveloperName = 'General_Enquiry' and sObjectType = 'Case' LIMIT 1].id;
            Id ComplaintRecordTypeId = [select id from RecordType where DeveloperName = 'Complaint' and sObjectType = 'Case' LIMIT 1].id;
            // create account
            Account a = new Account(name='ABC');
            insert a;

            // create vendor billing account
            Billing_Account__c vendor = new Billing_Account__c();
            vendor.Customer__c = a.id;
            insert vendor;

            // create tenant billing account
            Billing_Account__c tenant = new Billing_Account__c();
            tenant.Customer__c = a.id;
            insert tenant;

            Case c4 = new Case (RecordTypeId = GeneralEnquiryRecordTypeId, Billing_Account_SMR__c = vendor.id);
            insert c4;
            system.assert([select Billing_Account__c from Case where id = :c4.id].Billing_Account__c == c4.Billing_Account_SMR__c);

            Case c5 = new Case (RecordTypeId = ComplaintRecordTypeId , Billing_Account__c = vendor.id, Complaint_Type__c = 'EWOV', EWOV_Type__c = 'Investigative', Suspend_Billing__c = true);
            insert c5;
            system.assert([select id, Is_EWOV_Investigative_Complaint__c from Billing_Account__c where id = :vendor.id].Is_EWOV_Investigative_Complaint__c);
            c5.Status = 'Closed';
            update c5;
            system.assert(!([select id, Is_EWOV_Investigative_Complaint__c from Billing_Account__c where id = :vendor.id].Is_EWOV_Investigative_Complaint__c));

            Case c6 = new Case (RecordTypeId = ComplaintRecordTypeId , Billing_Account__c = vendor.id, Complaint_Type__c = 'EWOV', EWOV_Type__c = 'Assisted', Suspend_Billing__c = true);
            insert c6;

            system.assert([select id, Is_EWOV_Assisted_Complaint__c from Billing_Account__c where id = :vendor.id].Is_EWOV_Assisted_Complaint__c);
            c6.Status = 'Closed';
            update c6;
            system.assert(!([select id, Is_EWOV_Assisted_Complaint__c from Billing_Account__c where id = :vendor.id].Is_EWOV_Assisted_Complaint__c));

    }

    private static TestMethod void TestMe3() {

            // create account
            Account a = new Account(name='ABC');
            insert a;

            // create vendor billing account
            Billing_Account__c vendor = new Billing_Account__c();
            vendor.Customer__c = a.id;
            insert vendor;

            // create tenant billing account
            Billing_Account__c tenant = new Billing_Account__c();
            tenant.Customer__c = a.id;
            insert tenant;

            // in the future
            Case c4 = new Case (RecordTypeId = SMR_RECORDTYPE_ID, Billing_Account_SMR__c = vendor.id, Reading_Date__c = Date.newInstance(2050, 1, 1));
            try {
                insert c4;
            } catch (Exception e) {
                System.debug(e);
            }

            // in the past
            Case c5 = new Case (RecordTypeId = SMR_RECORDTYPE_ID, Billing_Account_SMR__c = vendor.id, Reading_Date__c = Date.newInstance(2001, 1, 1));
            try {
                insert c5;
            } catch (Exception e) {
                System.debug(e);
            }

    }

    private static TestMethod void TestMe4() {

        // create account
        Account a = new Account(name='ABC');
        insert a;

        // create contacts
        Contact con = new Contact(LastName = '1', AccountId = a.id);
        insert con;

        Property__c p = new Property__c();
        p.Name = 'TestProperty';
        p.Universal_Id_c__c = 'asdflkj';
        p.CIS_Property_Id__c = '01A/00000/0';
        insert p;

        Case c1 = new Case (RecordTypeId = INSURANCECLAIM_RECORDTYPE_ID, ContactId = con.id, Property__c = p.id, Status='New');
        insert c1;

        System.assert([Select Has_Insurance_Claim__c from Property__c where id = :p.id].Has_Insurance_Claim__c );
        System.assert([Select Has_Insurance_Claim__c from Contact where id = :con.id].Has_Insurance_Claim__c );

        c1.Status = 'Closed';
        update c1;
        System.assert(![Select Has_Insurance_Claim__c from Property__c where id = :p.id].Has_Insurance_Claim__c );
        System.assert(![Select Has_Insurance_Claim__c from Contact where id = :con.id].Has_Insurance_Claim__c );

    }

}