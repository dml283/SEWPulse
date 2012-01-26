public without sharing class WaterMAP_Pg6_Action_Plan_Con {

/*
    Type:           Controller Extension
    Purpose:    Controller to display the company and site info page of the WaterMAP portal

    Used By:    WaterMap_Pg6_Action_Plan_Page VF Page
    ---------------------------------------------------------------
    History:

    02-Jun-2011 J.Pe (Davanti)  Created

*/
    /* STATIC VARIABLES AND METHODS */
    private static final String ACTION_ITEM_STATUS_COMPLETED = 'Completed';
    private static final String ACTION_ITEM_OTHER_STRING = 'Other (please specify)';
    
    private static final Id ACTION_ITEM_RECORDTYPE_ID_WATERMAP;
    static{
        RecordType rt = [Select id, sobjecttype, developername from RecordType 
            where sobjecttype = 'Action_Item__c' 
                and developername = 'WaterMAP_Action_Item'];
        ACTION_ITEM_RECORDTYPE_ID_WATERMAP = rt.id;
    }
    
    /* PUBLIC PROPERTIES */
    // returns the current WaterMAP Submission record
    public WaterMAP_Submission__c waterMAPSub {get; set;}
    
    // retrieve ALL action items linked to this waterMAP
    public List<Action_Item__c> allActionItems{
        get{
            if (allActionItems==null){
                allActionItems = [Select Id, Name, RecordTypeId, Action__c, 
                        Action_Category__c, Description__c,
                        Cost__c, Estimated_Savings_Other_Cost_Per_Yr__c,
                        Estimated_Savings_Water_Cost_Per_Yr__c,
                        Estimated_Savings_Water_Usage_Per_Yr__c,
                        Funding_Required__c, Item_Number__c,
                        Long_Term_Actions__c, Medium_Term_Actions__c,
                        Ongoing_and_Future_Consideration_Actions__c,
                        Is_Ongoing_Initiative__c, Payback_Years_Calc__c,
                        Scheduled_Completion_Date__c, Short_Term_Actions__c,
                        Status__c, Watermap__c, Year_Action_Completed__c, 
                        Other_Action_Type__c, Project_Comments__c
                    From Action_Item__c
                    where Watermap__c =: waterMapSub.Watermap__c
                        and RecordTypeId = :ACTION_ITEM_RECORDTYPE_ID_WATERMAP
                        and (Status__c <> 'Cancelled')
                        order by Year_Action_Completed__c asc];
            }return allActionItems;
        }private set;
    }

    // only returns the completed action items (action items that are completed
    // in previous waterMAPs)
    public List<ActionItemYearWrapper> completedActionItems{
        get{
            if(completedActionItems==null){
                List<ActionItemWrapper> tempList = new List<ActionItemWrapper>();
                for(Action_Item__c actionItem : allActionItems){
                    if(ACTION_ITEM_STATUS_COMPLETED.equals(actionItem.Status__c) &&
                            !waterMapSub.Year__c.equals(actionItem.Year_Action_Completed__c) &&
                            !actionItem.Is_Ongoing_Initiative__c){
                        ActionItemWrapper itemWrapper = new ActionItemWrapper(actionItem);
                        tempList.add(itemWrapper);
                    }
                }
                completedActionItems = new List<ActionItemYearWrapper>();
                // reverse the list
                ActionItemYearWrapper yearWrapper;
                for(Integer i = tempList.size()-1; i >= 0 ; i--){
                    if(i == tempList.size()-1 || tempList[i+1].actionItem.Year_Action_Completed__c != tempList[i].actionItem.Year_Action_Completed__c){
                        if (i != tempList.size()-1){
                            completedActionItems.add(yearWrapper);
                        }
                        yearWrapper = new ActionItemYearWrapper(tempList[i].actionItem.Year_Action_Completed__c);
                        yearWrapper.itemWrappers.add(tempList[i]);
                    }else{
                        yearWrapper.itemWrappers.add(tempList[i]);
                    }
                }
                if(yearWrapper!=null && yearWrapper.itemWrappers.size()>0){
                    completedActionItems.add(yearWrapper);
                }
            }
            return completedActionItems;
        }private set;
    }
    
    // only return complete action items that are not deleted
    public List<ActionItemYearWrapper> nonDeletedCompletedActionItems{
        get{
            List<ActionItemYearWrapper> tempList = new List<ActionItemYearWrapper>();
            for(ActionItemYearWrapper itemYearWrapper: completedActionItems){
                ActionItemYearWrapper tempItemYearWrapper = new ActionItemYearWrapper(itemYearWrapper.year);
                tempList.add(tempItemYearWrapper);
                for(ActionItemWrapper itemWrapper :itemYearWrapper.itemWrappers){
                    if (!itemWrapper.isMarkedForDelete){
                        tempItemYearWrapper.itemWrappers.add(itemWrapper);
                    }
                }
            }
            for(Integer i = 0 ; i < tempList.size() ; i++){
                if(tempList[i].itemWrappers.size()==0){
                    tempList.remove(i);
                }
            }
            return tempList;
        }
    }
    
    // default number of non-ongoing actions to show on the screen
    public Integer minRequiredNonOngoingActions{
        get{
            if(minRequiredNonOngoingActions == null){
                minRequiredNonOngoingActions = 1;
            }return minRequiredNonOngoingActions;
        }set;
    }
    
    // returns list of specific actions
    public List<ActionItemWrapper> nonOngoingActions{
        get{
            if(nonOngoingActions == null){
                nonOngoingActions = new List<ActionItemWrapper>();
                for(Action_Item__c actionItem: allActionItems){
                    if (!actionItem.Is_Ongoing_Initiative__c && ((!ACTION_ITEM_STATUS_COMPLETED.equals(actionItem.Status__c))||(waterMapSub.Year__c.equals(actionItem.Year_Action_Completed__c)))){
                        nonOngoingActions.add(new ActionItemWrapper(actionItem));
                    }
                }
            }
            // find out how many recordsMarkedForDelete
            Integer noOfRecordsMarkedForDelete = 0;
            for(ActionItemWrapper itemWrapper: nonOngoingActions){
                if(itemWrapper.isMarkedForDelete){
                    noOfRecordsMarkedForDelete++;
                }
            }
            for(Integer i = nonOngoingActions.size()-noOfRecordsMarkedForDelete; i<minRequiredNonOngoingActions;i++){
                nonOngoingActions.add(new ActionItemWrapper(new Action_Item__c(
                        RecordTypeId = ACTION_ITEM_RECORDTYPE_ID_WATERMAP,
                        WaterMAP__c = waterMapSub.waterMAP__c,
                        Customer__c = waterMapSub.waterMAP__r.Customer__c)));
            }return nonOngoingActions;
        }private set;
    }
    
    // returns list of specific actions that are not deleted
    public List<ActionItemWrapper> notDeletedNonOngoingActions{
        get{
            List<ActionItemWrapper> tempList = new List<ActionItemWrapper>();
            for(ActionItemWrapper itemWrapper: nonOngoingActions){
                if(!itemWrapper.isMarkedForDelete){
                    tempList.add(itemWrapper);
                }
            }
            numberingActionItemWrapper(tempList);
            return tempList;
        }
    }
    
    // for PDF - returns list of specific actions that are not deleted and 
    // not empty
    public List<ActionItemWrapper> readOnlyNonOngoingActions{
            get{
            List<ActionItemWrapper> tempList = new List<ActionItemWrapper>();
            for(ActionItemWrapper itemWrapper: nonOngoingActions){
                if(!itemWrapper.isEmpty()){
                    tempList.add(itemWrapper);
                }
            }
            numberingActionItemWrapper(tempList);
            return tempList;
        }
    }
    
    // returns list of ongoing actions
    public List<ActionItemWrapper> ongoingActionsChecklist{
        get{
            if(ongoingActionsChecklist==null){
                // setup initial list
                ongoingActionsChecklist = getInitialOngoingActionsList();
                // map to Map
                Map<String,Map<String,ActionItemWrapper>> itemWrapperMapByActionCat = new Map<String,Map<String,ActionItemWrapper>>();
                for(ActionItemWrapper itemWrapper: ongoingActionsChecklist){
                    Map<String,ActionItemWrapper> itemWrapperMapByAction;
                    if(itemWrapperMapByActionCat.containsKey(itemWrapper.actionCategoryStr)){
                        itemWrapperMapByAction = itemWrapperMapByActionCat.get(itemWrapper.actionCategoryStr);
                    }else{
                        itemWrapperMapByAction = new Map<String,ActionItemWrapper>();
                        itemWrapperMapByActionCat.put(itemWrapper.actionCategoryStr,itemWrapperMapByAction);
                    }if(itemWrapper.actionStr != null){
                        itemWrapperMapByAction.put(itemWrapper.actionStr, itemWrapper);
                    }
                }
                // for each ongoingAction
                Boolean newItemWrappersAdded = false;
                for(Action_Item__c actionItem: allActionItems){
                    if (actionItem.Is_Ongoing_Initiative__c){
                        // find wrapper in map
                        Map<String,ActionItemWrapper> itemWrapperMapByAction;
                        if(itemWrapperMapByActionCat.containsKey(actionItem.Action_Category__c)){
                            itemWrapperMapByAction = itemWrapperMapByActionCat.get(actionItem.Action_Category__c);
                        }else{// action category not found - add new action category (and new action later)
                            itemWrapperMapByAction = new Map<String,ActionItemWrapper>();
                            itemWrapperMapByActionCat.put(actionItem.Action_Category__c,itemWrapperMapByAction);
                        }
                        if(itemWrapperMapByAction.containsKey(actionItem.Action__c)){
                            // found wrapper - add item to wrapper + marked for save
                            ActionItemWrapper itemWrapper = itemWrapperMapByAction.get(actionItem.Action__c);
                            itemWrapper.actionItem = actionItem;
                            itemWrapper.isMarkedForSaving = true;
                        }else{
                            // wrapper not found - add wrapper with item (auto add wrapper action category + action + save)
                            ActionItemWrapper itemWrapper = new ActionItemWrapper(actionItem);
                            itemWrapperMapByAction.put(actionItem.Action__c, itemWrapper);
                            newItemWrappersAdded = true;
                        }
                    }
                }
                if(newItemWrappersAdded){
                    // re-loop through Map to compile newest list
                    ongoingActionsChecklist = new List<ActionItemWrapper>();
                    List<String> actionCatKeys = new List<String>(itemWrapperMapByActionCat.keySet());
                    actionCatKeys.sort();
                    for(String actionCatStr: actionCatKeys){
                        ongoingActionsChecklist.add(new ActionItemWrapper(actionCatStr));
                        Map<String,ActionItemWrapper> itemWrapperMapByAction = itemWrapperMapByActionCat.get(actionCatStr);
                        List<String> actionKeys = new List<String>(itemWrapperMapByAction.keySet());
                        actionKeys.sort();
                        for(String actionStr: actionKeys){
                            ongoingActionsChecklist.add(itemWrapperMapByAction.get(actionStr));
                        }
                    }
                }
            }return ongoingActionsChecklist;
        }private set;
    }
    
    // for PDF - returns list of ongoing actions that have been selected
    public List<ActionItemWrapper> readOnlyOngoingActionslist{
        get{
            List<ActionItemWrapper> tempList = new List<ActionItemWrapper>();
            for(ActionItemWrapper itemWrapper: ongoingActionsChecklist){
                if(itemWrapper.isHeader || itemWrapper.isMarkedForSaving){
                    tempList.add(itemWrapper);
                }
            }return tempList;
        }
    }
    
    /* PRIVATE PROPERTIES */
    // method to number the specific actions on the page / PDF
    private void numberingActionItemWrapper(List<ActionItemWrapper> tempList){
        Integer itemNumber = 1;
        for(ActionItemWrapper itemWrapper: tempList){
            itemWrapper.itemNo = itemNumber;
            itemNumber++;
        }
    }
    
    // method that constructs the initial ongoing actions checklist
    private List<ActionItemWrapper> getInitialOngoingActionsList(){
        List<ActionItemWrapper> initialList = new List<ActionItemWrapper>();
        initialList.add(new ActionItemWrapper('Culture and water management'));
        initialList.add(new ActionItemWrapper('Culture and water management','Display water awareness stickers and posters'));
        initialList.add(new ActionItemWrapper('Culture and water management','Engage staff / tenants in water efficient practices (includes training)'));
        initialList.add(new ActionItemWrapper('Culture and water management','Hold staff / tenant engagement or environmental forums'));
        initialList.add(new ActionItemWrapper('Culture and water management','Monitor water consumption regularly'));
        initialList.add(new ActionItemWrapper('Culture and water management','Monthly reporting of water data'));
        initialList.add(new ActionItemWrapper('Culture and water management','Publish and circulate staff / tenant newsletters'));
        initialList.add(new ActionItemWrapper('Culture and water management','Report waterMAP status to management or board meetings'));
        initialList.add(new ActionItemWrapper('Culture and water management','Appoint water conservation champions'));
        initialList.add(new ActionItemWrapper('Culture and water management','waterMAP representative has copies of water accounts'));
        initialList.add(new ActionItemWrapper('Alternative water sources'));
        initialList.add(new ActionItemWrapper('Alternative water sources','Capture and re-use fire service testing water'));
        initialList.add(new ActionItemWrapper('Alternative water sources','Capture and re-use irrigation runoff'));
        initialList.add(new ActionItemWrapper('Alternative water sources','Collect and recycle condensate'));
        initialList.add(new ActionItemWrapper('Alternative water sources','Collect and use rainwater or stormwater'));
        initialList.add(new ActionItemWrapper('Alternative water sources','Recycle process or cooling tower water'));
        initialList.add(new ActionItemWrapper('Alternative water sources','Recycle / re-use filter backwash'));
        initialList.add(new ActionItemWrapper('Alternative water sources','Treat and recycle trade waste effluent'));
        initialList.add(new ActionItemWrapper('Alternative water sources','Use alternative (non potable water) for toilet flushing'));
        initialList.add(new ActionItemWrapper('Alternative water sources','Use bore water'));
        initialList.add(new ActionItemWrapper('Alternative water sources','Use class A recycle water'));
        initialList.add(new ActionItemWrapper('Alternative water sources','Use class C recycle water'));
        initialList.add(new ActionItemWrapper('Operational efficiencies'));
        initialList.add(new ActionItemWrapper('Operational efficiencies','Fix leaks immediately'));
        initialList.add(new ActionItemWrapper('Operational efficiencies','Mulch garden beds'));
        initialList.add(new ActionItemWrapper('Operational efficiencies','Monitor and enforce water efficient operating procedures'));
        initialList.add(new ActionItemWrapper('Operational efficiencies','Use chemicals to minimise evaporation'));
        initialList.add(new ActionItemWrapper('Operational efficiencies','Use pool or dam covers'));
        return initialList;
    }
    
    /* CONSTRUCTOR */
    public WaterMAP_Pg6_Action_Plan_Con(ApexPages.StandardController controller) {
        waterMapSub = (WaterMAP_Submission__c) controller.getRecord();
        setupWaterMAPSub();
    }
    
    /* PUBLIC METHODS */  
    // allow users to add new specific action on the VF Page 
    public void addNewAction(){
        nonOngoingActions.add(new ActionItemWrapper(new Action_Item__c(
                                RecordTypeId = ACTION_ITEM_RECORDTYPE_ID_WATERMAP,
                                WaterMAP__c = waterMapSub.waterMAP__c,
                                Customer__c = waterMapSub.waterMAP__r.Customer__c)));
    }
    //  method that saves all changes in action item
    public void saveAllActionItems(){
        List<Action_Item__c> actionsToSave = new List<Action_Item__c>();
        List<Action_Item__c> actionsToDelete = new List<Action_Item__c>();
        // for non-ongoing action items
        for(ActionItemWrapper itemWrapper :nonOngoingActions){
            if (!itemWrapper.isMarkedForDelete & !itemWrapper.isEmpty() && itemWrapper.isValidNewActionOrProject()){
                if(ACTION_ITEM_STATUS_COMPLETED.equals(itemWrapper.actionItem.Status__c)){
                    if(itemWrapper.actionItem.Year_Action_Completed__c == null){
                        itemWrapper.actionItem.Year_Action_Completed__c = waterMapSub.Year__c;
                    }
                }else{
                    if(itemWrapper.actionItem.Year_Action_Completed__c != null){
                        itemWrapper.actionItem.Year_Action_Completed__c = null;
                    }
                }
                actionsToSave.add(itemWrapper.actionItem);
            }else if(itemWrapper.isMarkedForDelete && itemWrapper.actionItem.id != null){
                actionsToDelete.add(itemWrapper.actionItem);
            }
        }
        // for ongoing action items
        for(ActionItemWrapper itemWrapper :ongoingActionsChecklist){
            // if no action item object but marked for saving - brand new action item to save
            if(itemWrapper.actionItem==null){
                if(itemWrapper.isMarkedForSaving){
                    actionsToSave.add(new Action_Item__c(
                            RecordTypeId = ACTION_ITEM_RECORDTYPE_ID_WATERMAP,
                            WaterMAP__c = waterMapSub.waterMAP__c,
                            Customer__c = waterMapSub.waterMAP__r.Customer__c,
                            Is_Ongoing_Initiative__c = true,
                            Action_Category__c = itemWrapper.actionCategoryStr,
                            Action__c = itemWrapper.actionStr));
                }
            }else{ // else if there is action item but not marked for saving, need to delete
                if(!itemWrapper.isMarkedForSaving){
                    actionsToDelete.add(itemWrapper.actionItem);
                }
            }
        }
        // for completed action items
        for(ActionItemYearWrapper itemYearWrapper: completedActionItems){
            for(ActionItemWrapper itemWrapper :itemYearWrapper.itemWrappers){
                if (itemWrapper.isMarkedForDelete){
                    actionsToDelete.add(itemWrapper.actionItem);
                }
            }
        }
        upsert actionsToSave;
        delete actionsToDelete;
        resetAllActionItems();
    }
    // method that resets variables so the VF page will requery and get
    // latest info
    public void resetAllActionItems(){
        allActionItems = null;
        nonOngoingActions = null;
        ongoingActionsChecklist = null;
        completedActionItems = null;
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

        waterMapSub.Action_Plan_Complete__c = true;

        Savepoint sp = Database.setSavePoint();

        try {
            updateRecords();
        } catch (Exception e) {
            ApexPages.addMessages(e);
            Database.rollback(sp);
            return false;
        }
        allActionItems = null;
        nonOngoingActions = null;
                ongoingActionsChecklist = null;
                completedActionItems = null;
        return true;
    }

    // Returns the next page
    private PageReference NextPage() {
        // navigate to the next page
        PageReference nextPage = Page.WaterMAP_Submit_Page;
        nextPage.setRedirect(true);
        nextPage.getParameters().put('id', waterMAPSub.id);

        return nextPage;
    }

    // validate page for all mandatory fields
    private boolean validatePage() {
        boolean valid=true;
        Integer numberOfValidActions = 0;
        for(ActionItemWrapper itemWrapper :nonOngoingActions){
            if (!itemWrapper.isMarkedForDelete){
                if(!itemWrapper.isEmpty()){
                    if(!itemWrapper.isValidNewActionOrProject()){
                            //apexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'New Action / Project not completed correctly - please make sure Action Category, Action Description and Action Status have been filled in.');
                            //apexPages.addMessage(msg);
                            valid=false;    
                    }else{
                        numberOfValidActions++;
                    }
                }
            }
        }   
        for(ActionItemWrapper itemWrapper :ongoingActionsChecklist){
            if(itemWrapper.isMarkedForSaving){
                numberOfValidActions++;
            }
        }
        if(numberOfValidActions<2){
            apexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'At least 2 new actions / projects or ongoing actions are required.');
                apexPages.addMessage(msg);
                valid=false;
        }
        return valid;
    }
    
    // Mechanism of saving the details on this page
    private void updateRecords(){
        update waterMapSub;
        //update waterMapSub.WaterMAP__r;
        saveAllActionItems();
    }
    
    // wrapper that splits action items into years
    public class ActionItemYearWrapper{
        public String year {get;private set;}
        public List<ActionItemWrapper> itemWrappers{
            get{
                if (itemWrappers==null){
                    itemWrappers = new List<ActionItemWrapper>();
                }return itemWrappers;
            }private set;
        }
        public ActionItemYearWrapper(String year){
            this.year = year;
        }
    }
    
    // Action Item wrapper to allow for VF functionality
    public class ActionItemWrapper{
            public Integer itemNo{get;set;}
        public Action_Item__c actionItem{get;set;}
        //For ongoing actions only
        public boolean isMarkedForSaving{
            get{
                return !isMarkedForDelete;
            }set{
                isMarkedForDelete = !value;
            }
        }
        public String actionCategoryStr{get; private set;}
        public String actionStr{get; private set;}
        public boolean isHeader{
            get{
                return actionStr==null;
            }
        }
        //For non-ongoing actions only
        public String uniqueID{get;private set;}
        public boolean isMarkedForDelete {
            get{
                if(isMarkedForDelete==null){
                    isMarkedForDelete = false;
                }return isMarkedForDelete;
            }set;
        }

        public List<Action_Item__c> actionItemListWrapper{
            get{
                List<Action_Item__c> tempList = new List<Action_Item__c>();
                tempList.add(actionItem);
                return tempList;
            }
        }
        public ActionItemWrapper(Action_Item__c item){
            this(item.Action_Category__c, item.Action__c);
            this.actionItem = item;
            this.isMarkedForSaving = true;
        }
        public ActionItemWrapper(String actionCategoryStr){
            this(actionCategoryStr, null);
        }
        public ActionItemWrapper(String actionCategoryStr, String actionStr){
            this.actionCategoryStr = actionCategoryStr;
            this.actionStr = actionStr;
            this.uniqueID = WaterMAPUtil.generateRandomID();
            this.isMarkedForSaving = false;
        }
        public void deleteRecord(){
            isMarkedForDelete = true;
        }
        // validates the minimum level of completeness of action item info
        public boolean isValidNewActionOrProject(){
            boolean valid = true;
            if(this.actionItem.Action_Category__c == null){
                this.actionItem.Action_Category__c.addError('Action Category is required.');
                valid = false;
            }
            if(this.actionItem.Action__c == null && !ACTION_ITEM_OTHER_STRING.equals(this.actionItem.Action_Category__c)){
                this.actionItem.Action__c.addError('Action is required.');
                valid = false;
            }
            if((ACTION_ITEM_OTHER_STRING.equals(this.actionItem.Action_Category__c) || ACTION_ITEM_OTHER_STRING.equals(this.actionItem.Action__c)) && this.actionItem.Other_Action_Type__c == null){
                this.actionItem.Other_Action_Type__c.addError('Other action type needs to be specified.');
                valid = false;
            }
            if(this.actionItem.Description__c == null){
                this.actionItem.Description__c.addError('Action Description is required.');
                valid = false;
            }
            if(this.actionItem.Status__c == null){
                this.actionItem.Status__c.addError('Action Status is required.');
                valid = false;
            }
            return valid;
        }
        // validates all necessary fields are filled in
        public boolean isReviewValid(){
            boolean valid = isValidNewActionOrProject();
            if(!ACTION_ITEM_STATUS_COMPLETED.equals(this.actionItem.Status__c) && this.actionItem.Project_Comments__c == null){
                this.actionItem.Project_Comments__c.addError('Project Comments are required.');
                valid = false;
            }
            if(ACTION_ITEM_STATUS_COMPLETED.equals(this.actionItem.Status__c)){
                if(this.actionItem.Cost__c == null){
                    this.actionItem.Cost__c.addError('Required field.');
                    valid = false;
                }
                if(this.actionItem.Estimated_Savings_Water_Usage_Per_Yr__c == null){
                    this.actionItem.Estimated_Savings_Water_Usage_Per_Yr__c.addError('Required field.');
                    valid = false;
                }
                if(this.actionItem.Estimated_Savings_Water_Cost_Per_Yr__c == null){
                    this.actionItem.Estimated_Savings_Water_Cost_Per_Yr__c.addError('Required field.');
                    valid = false;
                }
                if(this.actionItem.Estimated_Savings_Other_Cost_Per_Yr__c == null){
                    this.actionItem.Estimated_Savings_Other_Cost_Per_Yr__c.addError('Required field.');
                    valid = false;
                }
            }
            return valid;
        }
        // check if the action is empty
        public boolean isEmpty(){
            return this.actionItem.Action_Category__c == null && this.actionItem.Action__c == null &&
                    this.actionItem.Description__c == null && this.actionItem.Status__c == null;
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
        insert charge;

        Test.startTest();
        PageReference pageRef = Page.WaterMap_Pg6_Action_Plan_Page;
        ApexPages.StandardController sc = new ApexPages.StandardController(waterMapSub);
        Test.setCurrentPage(pageRef);
        WaterMAP_Pg6_Action_Plan_Con controller = new WaterMAP_Pg6_Action_Plan_Con(sc);
        controller.NoOp();
        controller.Save();
        controller.notDeletedNonOngoingActions[0].actionItem.Action_Category__c = 'Test';
        controller.Save();
        controller.notDeletedNonOngoingActions[0].actionItem.Action_Category__c = ACTION_ITEM_OTHER_STRING;
        controller.Save();
        controller.notDeletedNonOngoingActions[0].actionItem.Action_Category__c = null;
        controller.notDeletedNonOngoingActions[0].actionItem.Action__c = 'Test';
        controller.Save();
        controller.notDeletedNonOngoingActions[0].actionItem.Action_Category__c = 'Test Category';
        controller.notDeletedNonOngoingActions[0].actionItem.Action__c = ACTION_ITEM_OTHER_STRING;
        controller.notDeletedNonOngoingActions[0].actionItem.Other_Action_Type__c = 'Test other';
        controller.notDeletedNonOngoingActions[0].actionItem.Status__c = 'In Progress';
        controller.notDeletedNonOngoingActions[0].actionItem.Description__c = 'Test Description';
        controller.notDeletedNonOngoingActions[0].isReviewValid();
        controller.addNewAction();
        controller.notDeletedNonOngoingActions[1].actionItem.Action_Category__c = 'Test Category';
        controller.notDeletedNonOngoingActions[1].actionItem.Action__c = ACTION_ITEM_OTHER_STRING;
        controller.notDeletedNonOngoingActions[1].actionItem.Other_Action_Type__c = 'Test other';
        controller.notDeletedNonOngoingActions[1].actionItem.Status__c = 'In Progress';
        controller.notDeletedNonOngoingActions[1].actionItem.Description__c = 'Test Description';
        controller.notDeletedNonOngoingActions[1].actionItem.Project_Comments__c = 'Test';
        controller.notDeletedNonOngoingActions[1].isReviewValid();
        controller.notDeletedNonOngoingActions[1].actionItem.Status__c = ACTION_ITEM_STATUS_COMPLETED;
        controller.notDeletedNonOngoingActions[1].isReviewValid();
        controller.notDeletedNonOngoingActions[1].actionItem.Cost__c = 100000;
        controller.notDeletedNonOngoingActions[1].actionItem.Estimated_Savings_Water_Usage_Per_Yr__c = 100000;
        controller.notDeletedNonOngoingActions[1].actionItem.Estimated_Savings_Water_Cost_Per_Yr__c = 100000;
        controller.notDeletedNonOngoingActions[1].actionItem.Estimated_Savings_Other_Cost_Per_Yr__c = 100000;
        controller.notDeletedNonOngoingActions[1].isReviewValid();
        controller.Save();
        controller.notDeletedNonOngoingActions[0].deleteRecord();
        controller.Save();
        for(ActionItemWrapper itemWrapper: controller.ongoingActionsChecklist){
            if(!itemWrapper.isHeader){
                itemWrapper.isMarkedForSaving = true;
            }
        }
        controller.Next();
        List<ActionItemYearWrapper> aiyw = controller.completedActionItems;
        List<ActionItemWrapper> aiw = controller.readOnlyNonOngoingActions;
        aiw = controller.readOnlyOngoingActionslist;
        WaterMAP_Pg6_Action_Plan_Con controller2 = new WaterMAP_Pg6_Action_Plan_Con(sc);
        Boolean tempBool = false;
        for(ActionItemWrapper itemWrapper: controller2.ongoingActionsChecklist){
            if(!itemWrapper.isHeader){
                itemWrapper.isMarkedForSaving = tempBool;
                tempBool = !tempBool;
            }
        }
        Test.stopTest();

    }
}