/*
    Type:       Custom Controller
    Purpose:    Add, Amend, Remove direct debit account information for billing account(s)
                and control VF page
                
    Used By:    DirectDebit, DirectDebitAmend, DirectDebitFeedback
    ---------------------------------------------------------------
    History:
    
    21-11-2011 Ji Zhang (Coretec Solutions)     Created
    05-12-2011 Ji Zhang (Coretec Solutions)     Added Webservice
    07-12-2011 Matthew Watson (Salesforce)      Added validation for recovery dates & CL classifications
*/

public class DirectDebitController {
    
    // VARIABLES  
    public List<Task> newTaskList{
        get {
            if (newTaskList == null)
                newTaskList = new List<Task>();
            return newTaskList;
        }
        set;
    }   
    public Boolean submitting{get;set;}
    public Boolean notCompleted{get;set;}
    
    // this is the property to tell whether user is 
    // cancel or add/amend direct debit account
    public String actionType{get;set;}
    
    public Boolean agreedTerms{get;set;}
    public Boolean gatewayStatus{get;set;}
    private Task taskRec{get;set;}
    private Set<Id> taskIdSet{get;set;}
    public Boolean redirect{get;set;}
    public Boolean timeOut{get;set;}
    public Integer timesPolled{get;set;}
    private String paymentMsg{get;set;}
    private String ccFirstFourDigits{get;set;}
    private String ccLastThreeDigits{get;set;}
    private String paymentType{get;set;}    
    public Boolean hasDirectDebitAcc{get;set;}
    private Id customerId{get;set;}
    public Id billAcctId{get;set;}
    public Boolean budgetsFlag {get; set;}

    private Map<Id, String> whatIdNameMap{
        get{
            if(this.whatIdNameMap == null){
                this.whatIdNameMap = new Map<Id, String>();
            }
            return this.whatIdNameMap;
        }
        set;
    }
    
    private Map<Id, String> whatIdHiAFMap{
        get{
            if(this.whatIdHiAFMap == null){
                this.whatIdHiAFMap = new Map<Id, String>();
            }
            return this.whatIdHiAFMap;
        }
        set;
    }
    
    private static final Integer CONST_MAX_TIMES_POLLED = 48;   
    private boolean errorsExist = false;  

    // User Input Fields per Billing Account        
    public Credit_Card_Proxy__c userInputFields{
        get{
            if(userInputFields == null){
                userInputFields = new Credit_Card_Proxy__c();
                
            }

            return userInputFields;
        }set;
     }
 
    // List of Billing Accounts for the customer (if page is invoked from Customer record)   
     public List<BillingAccWrap> billingAccList{
        get {
            if(this.billingAccList == null){
                this.billingAccList = new List<BillingAccWrap>();
                if(this.customerId != null){ // this check is important
                
                    List<Billing_Account__c> baList = [SELECT id, Name, Balance__c,Direct_Debit__c, 
                                             Direct_Debit_Commencement_Date__c,Is_Payment_Plan__c,
                                             Direct_Debit_Details__c, Direct_Debit_Type__c, 
                                             Property_Address__c, HiAF_Account_Number__c,
                                             Recovery_Last_Action_Date__c, Recovery_Next_Action_Date__c, 
                                             (select Class_Code__c from 
                                                 Customer_Classifications__r where (Class_Code__c = 'AX' OR 
                                                 Class_Code__c = 'PI' OR Class_Code__c = 'CL') AND Is_Active__c = true)
                                             FROM Billing_Account__c 
                                             WHERE Customer__c = : this.customerId
                                             AND (Status__c = 'Active' OR Status__c = 'Pending')];
                    
                    if(!baList.isEmpty()){
                        for(Integer i = 0; i < baList.size(); i++){
                            BillingAccWrap baWrapRecord = new BillingAccWrap(baList[i]);
                            if(userInputFields.Billing_Account__c == baList[i].Id){
                                baWrapRecord.isSelected = true;
                            }
                            this.billingAccList.add(baWrapRecord);
                        }
                    }
                }
            }
            return this.billingAccList;
        }
        set;
     }
     
     public List<TaskWrap> taskList{
        get{
            this.taskList = new List<TaskWrap>();
            for(Integer i = 0; i < newTaskList.size(); i++){
                TaskWrap tWrapRecord = new TaskWrap(newTaskList[i]);
                tWrapRecord.setTaskAction(actionType);
                tWrapRecord.setBillingAccName(whatIdNameMap.get(tWrapRecord.newTask.WhatId));
                taskList.add(tWrapRecord);
            }
            return taskList;        
        }
        set;
     }

    // List to store selected Billing Accounts     
     public List<BillingAccWrap> selectedBillingAccList{
        get{
            if(selectedBillingAccList == null)
                this.selectedBillingAccList = new List<BillingAccWrap>();
            return selectedBillingAccList;  
        }
        set;
     }
 
     // METHODS
     
     // Controller instanstiation method
     public DirectDebitController(){
        Map<String, String> param = Apexpages.currentPage().getParameters();
        customerId = ((ID)param.get('customerId'));
        billAcctId = ((ID)param.get('billAcctId'));
        actionType = param.get('actionType');
        
        // Set the budgets flag to true if it came from manage payment plans
        String budgets = param.get('budgets');
        
        if (budgets == 'true') 
            budgetsFlag = true;
        else
            budgetsFlag = false;
        
        if(customerId!= null)userInputFields.Customer_Account__c = customerId;
        if(billAcctId!= null) userInputFields.Billing_Account__c = billAcctId;      
        if(param.get('contactId')!= null) userInputFields.Person__c = ((ID)param.get('contactId'));      
        
        // Only run where page is invoked from Manage Payment Plans
        if(billAcctId != null){
            List<Billing_Account__c> baList = [SELECT id, Name, Balance__c,Direct_Debit__c, 
                                                 Direct_Debit_Commencement_Date__c,Is_Payment_Plan__c,
                                                 Direct_Debit_Details__c, Direct_Debit_Type__c, Property_Address__c,
                                                 HiAF_Account_Number__c, Recovery_Last_Action_Date__c, 
                                                 Recovery_Next_Action_Date__c, (select Class_Code__c from 
                                                 Customer_Classifications__r where (Class_Code__c = 'AX' OR 
                                                 Class_Code__c = 'PI' OR Class_Code__c = 'CL') AND Is_Active__c = true)
                                                 FROM Billing_Account__c 
                                                 WHERE Id =: billAcctId];
                                                 
            if(!baList.isEmpty()){
                BillingAccWrap baWrapRecord = new BillingAccWrap(baList[0]);
                baWrapRecord.isSelected = true;
                selectedBillingAccList.add(baWrapRecord);
            }
        }
               
        submitting = false;
        redirect = false;
        timeOut = false;
        timesPolled = 0;
        notCompleted = true;
        agreedTerms = false;
        
        // check gateway status
        WSUtil_Payment ws = new WSUtil_Payment();
        gateWayStatus = false;
        try{
            if(ws.getStatus() == 'Ok'){
                gateWayStatus = true;
            }else{
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'IP payment gateway service is down. Please try it again later.'));
            }
        }catch(WSUtil.MultipleWebServiceBusinessException multiEx){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'IP payment gateway service is down. Please try it again later.'));
        }catch (Exception ex){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'IP payment gateway service is down. Please try it again later.'));
        }
     }
 
     public PageReference submit(){ 
        if(!actionType.equalsIgnoreCase('Cancel')){
            if(!isValidData())return null;
        }
        if(!createTask()) return null;
   
        submitting = true;
//        return Page.DirectDebitFeedback;
        return null;
     }

    // amend() - amend direct debit payment details for 1 or more selected Billing Accounts
    // Includes checks to ensure:
    //      (1) Selected billing accounts do not have a Recovery Last or Next Action Date of today
    //      (2) Selected billing accounts do not have a CL classifcation attached (centrelink)
    //      (3) At least one billing account is selected
     public PageReference amend(){
         selectedBillingAccList = new List<BillingAccWrap>();
         List<BillingAccWrap> recoveryTodayAccList = new List<BillingAccWrap>();
         List<BillingAccWrap> CLBillingAccList = new List<BillingAccWrap>();        
        actionType = 'Add/Amend';
        // identify which Billing Accounts are selected 
        for(Integer i = 0; i < billingAccList.size(); i++){
                if(billingAccList[i].isSelected){
                    selectedBillingAccList.add(billingAccList[i]);
                    // check whether a selected account has a recovery date of today
                    if(billingAccList[i].billingAccount.Recovery_Last_Action_Date__c == System.today()
                    || billingAccList[i].billingAccount.Recovery_Next_Action_Date__c == System.today()
                    ) {
                        recoveryTodayAccList.add(billingAccList[i]);
                    }
                    // check whether a selected account has a CL classification
                    if(billingAccList[i].hasCL == true) {
                        CLBillingAccList.add(billingAccList[i]);
                    }
                }
        }
        
        // Error - selected billing accounts cannot have a recovery action today
        if(!recoveryTodayAccList.isEmpty()){
            String errMsg = 'The following Billing Account(s) have a Recovery Action scheduled for today ' + System.today().format();
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, errMsg));
            for(BillingAccWrap b : recoveryTodayAccList){
                errMsg = 'Billing Account # ' + b.billingAccount.Name;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, errMsg));
            }
            return null;
        }

        // Error - selected billing accounts have a CL classification
        if(!CLBillingAccList.isEmpty()) {
            String errMsg = 'The following Billing Account(s) have a Classification Code of CL which is Active. They cannot be setup for Direct Debit.';
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, errMsg));
            for(BillingAccWrap b : CLBillingAccList){
                errMsg = 'Billing Account # ' + b.billingAccount.Name;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, errMsg));
            }
            return null;
        }                  

        // Success - proceed to Amend page        
        if(!selectedBillingAccList.isEmpty()){   
            userInputFields.DD_Account_Type__c = 'Bank Account';
            
            return Page.DirectDebitAmend;
        }

        // Error - no billing accounts selected!    
        else {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please select one billing account at least.'));
            return null;
        }
     }

    // remove() - remove a direct debit payment from 1 or more selected Billing Accounts
    // Includes checks to ensure:
    //      (1) selected BAs actually have a direct debit to remove
    //      (2) selected BAs don't have an active PI or AX classification
    //          (unless user is an SEW Administrator/Integration user or in the Direct Debit Team queue)    
     public PageReference remove(){ 
        selectedBillingAccList = new List<BillingAccWrap>();
        List<BillingAccWrap> AXorPIBillingAccList = new List<BillingAccWrap>();
        Boolean isValid = true;
        Boolean hasAXorPIPermission = false;
        if(billingAccList != null){
            for(Integer i = 0; i < billingAccList.size(); i++){
                if(billingAccList[i].isSelected){
                    if(billingAccList[i].billingAccount.Direct_Debit__c){
                        selectedBillingAccList.add(billingAccList[i]);
                        if(billingAccList[i].hasAXorPI){
                            AXorPIBillingAccList.add(billingAccList[i]);
                        }
                    }else{
                        isValid = false;
                        i = billingAccList.size();
                    }
                }
            }       
        }   
        
        // Error - users can only select billing accounts that alredy have a direct debit
        if(selectedBillingAccList.isEmpty() || !isValid){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please select the billing account(s) which has existing direct debit.'));
            return null;
        } 
        
        // check profile - is user an SEW Administrator or Integration user?
        List<Profile> profileList = [SELECT Name FROM Profile WHERE Name = 'SEW Administrator' OR Name = 'SEW Integration'];
        Id userProfileId = UserInfo.getProfileId();
        for(Profile p : ProfileList){
            if(userProfileId == p.Id){
                hasAXorPIPermission = true;
            }
        }
        
        // not in the profile then check queue - is the user part of the Direct Debit team?
        if(!hasAXorPIPermission){
            List<GroupMember> userList = [SELECT UserOrGroupId FROM GroupMember WHERE GroupId in:[SELECT Id FROM Group WHERE type='Queue' AND Name='Direct Debit Team']];   
            Id userId = UserInfo.getUserId(); 
            for(GroupMember g : userList){
                if(userId == g.UserOrGroupId){
                    hasAXorPIPermission = true;
                }
            }
        }
       
       // Error - cannot remove Direct Debit from billing accounts with AX or PI classifications
       // (unless user passed permission/group checks above)         
        if(!hasAXorPIPermission && !AXorPIBillingAccList.isEmpty()){
            String errMsg = 'The following Billing Account(s) have Classification Codes of AX or PI which is Active. Please refer to the Commercial Sales team.';
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, errMsg));
            for(BillingAccWrap b : AXorPIBillingAccList){
                errMsg = 'Billing Account # ' + b.billingAccount.Name;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, errMsg));
            }
            return null;
        }   
 
        actionType = 'Cancel';  
        return Page.DirectDebitAmend;
     }
     
     // register - deregister direct debit
     public PageReference registerDeregisterCustomer(){
        
        if(newTaskList == null) return null;
        
        WSUtil_Payment ws = new WSUtil_Payment();
 
        WSUtil_Payment.RegisterDeregesterCustomer rdc;
        List< WSUtil_Payment.RegisterDeregesterCustomer> rdcList = new List< WSUtil_Payment.RegisterDeregesterCustomer>();
        
        // get the person
        userInputFields.Person__r = [SELECT id, FirstName, LastName FROM Contact 
                                             WHERE id =: userInputFields.Person__c];
        
        for(Task t : newTaskList){
            rdc = new WSUtil_Payment.RegisterDeregesterCustomer();
            rdc.TaskID = t.id;
            
            // form map billing account id(key) with HiAF account no(value) 
            rdc.BillingAccountNumber = whatIdHiAFMap.get(t.whatId);
            
            // Did it come from Manage Payment Plans?
            rdc.DDBudgetFlag = budgetsFlag;

            // Not used at the moment
            rdc.DDStartDate = null;
            rdc.InclBalanceFlag = false;
            
            // Customer                          
            rdc.FirstName = userInputFields.Person__r.FirstName;
            rdc.LastName = userInputFields.Person__r.LastName;
                
            if(actionType.equalsIgnoreCase('Cancel')){
                rdc.Action = 'Deregister';              
            } else{
                if(t.Hidden_DD_Action_Type__c.equalsIgnoreCase('Add')){
                    rdc.Action = 'Register';
                }else{
                    rdc.Action = 'Amend';
                }
                if((userInputFields.DD_Account_Type__c).equalsIgnoreCase('Credit Card')){
                    rdc.CardNumber = userInputFields.Credit_Card_Number_1__c + userInputFields.Credit_Card_Number_2__c + userInputFields.Credit_Card_Number_3__c + userInputFields.Credit_Card_Number_4__c;
                    rdc.CardExpiryMonth = userInputFields.Expiration_Date_Month__c;
                    rdc.CardExpiryYear = userInputFields.Expiration_Date_Year__c;
                    rdc.CVN = userInputFields.CVN__c;
                    rdc.CardHolderName = userInputFields.Name_on_Card__c;
                }else {
                    rdc.AccountNumber = userInputFields.DD_Account_No__c;
                    rdc.AccountTitle = userInputFields.DD_Account_Name__c;
                    rdc.AccountBSB = userInputFields.DD_BSB_No__c;
                    rdc.BankName = userInputFields.DD_Financial_Institution__c;
                    rdc.BankState = '';
                    rdc.BankSuburb = '';
                }
            }
            rdcList.add(rdc);
        }

        try{
            ws.registerDeregisterCustomer(rdcList,userInputFields.DD_Account_Type__c);
        }catch(WSUtil.MultipleWebServiceBusinessException multiEx){
            for(WSUtil.SingleWebServiceBusinessException ex : multiEx.multiEx){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Credit Card Payment Web Service error: '+ex.getMessage()));
            }
            return null;
        }catch (Exception ex){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Unknown error: '+ex.getMessage()));
            return null;
        }
        return Page.DirectDebitFeedback;
     }
     
     public PageReference goBack(){
        selectedBillingAccList = new List<BillingAccWrap>();
        return Page.DirectDebit;    
     }
     
     public PageReference checkStatus(){ 
        newTaskList = [SELECT WhatId, Subject, Type, Status, Hidden_DD_Details__c, Hidden_Messages__c, Hidden_DD_Action_Type__c FROM Task WHERE id in: taskIdSet];
        notCompleted = false;
        errorsExist = false;
        for(Task t : newTaskList){
            if((t.Status).equalsIgnoreCase('In Progress')){
                notCompleted = true;
            }
            if((t.Status).equalsIgnoreCase('Failed')){
                errorsExist = true;
            }
        }
        
        if(!notCompleted) submitting = false;
        
        if(timesPolled < CONST_MAX_TIMES_POLLED){
            timesPolled++;
        }else{
            timeOut = true;
        }    
        return null;
     }
     
     public PageReference Redirect() {
         redirect=false;
         submitting=false;
        
        //stop polling when all complete
        if(!notCompleted){
            submitting = false;
            if (!errorsExist)
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'All direct debit requests have been processed successfully.'));
            else
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'All direct debit requests have been processed with errors. Please check the individual requests for errors.'));
        }
        
        return null;
     }
     
     public PageReference Timeout() {
        if(timeOut){
            timeOut = false;
            submitting = false;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'The process timed out while processing the request. Please contact the administrator.'));
        }
        return null;        
    }
     
     private Boolean isValidData(){
        boolean isValid = true;
        paymentType = userInputFields.DD_Account_Type__c;
        if(!agreedTerms){ isValid = false; ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please check the Customer Agreement.'));}
        if(paymentType.equalsIgnoreCase('Credit Card')){
            if(userInputFields.Credit_Card_Number_1__c == null || !isNumberic(userInputFields.Credit_Card_Number_1__c) 
               || (userInputFields.Credit_Card_Number_1__c).length()!= 4){
                userInputFields.Credit_Card_Number__c.addError('Not a Valid Credit Card Number.');
                isValid = false;
            }
            if(userInputFields.Credit_Card_Number_2__c == null || !isNumberic(userInputFields.Credit_Card_Number_2__c) 
               || (userInputFields.Credit_Card_Number_2__c).length()!= 4){
                userInputFields.Credit_Card_Number__c.addError('Not a Valid Credit Card Number.');
                isValid = false;
            }
            if(userInputFields.Credit_Card_Number_3__c == null || !isNumberic(userInputFields.Credit_Card_Number_3__c) 
               || (userInputFields.Credit_Card_Number_3__c).length()!= 4){
                userInputFields.Credit_Card_Number__c.addError('Not a Valid Credit Card Number.');
                isValid = false;
            }
            if(userInputFields.Credit_Card_Number_4__c == null || !isNumberic(userInputFields.Credit_Card_Number_4__c) 
               || (userInputFields.Credit_Card_Number_4__c).length()!= 4){
                userInputFields.Credit_Card_Number__c.addError('Not a Valid Credit Card Number.');
                isValid = false;
            }
        }else{
            if(userInputFields.DD_BSB_No__c == null || !isNumberic(userInputFields.DD_BSB_No__c)
               || (userInputFields.DD_BSB_No__c).length()!= 6){
                userInputFields.DD_BSB_No__c.addError('Not a Valid BSB Number');
                isValid = false;
            }
            if(userInputFields.DD_Account_No__c == null || !isNumberic(userInputFields.DD_Account_No__c) 
               || (userInputFields.DD_Account_No__c).length() < 3){
                userInputFields.DD_Account_No__c.addError('Not a Valid Account Number');
                isValid = false;
            }
        } 
        return isValid;
     }
     
     // valid number only
     private boolean isNumberic(String str){
        Pattern p = Pattern.compile('^[0-9]+$');
        Matcher MyMatcher = p.matcher(str);
        return MyMatcher.matches();
     }
     
     // create a list task based on selectedBillingAccount
     private Boolean createTask(){
        
        Id recordTypeId = [SELECT name FROM RecordType WHERE name = 'Read Only Tasks' LIMIT 1].Id;
        
        
        if(selectedBillingAccList != null){
            whatIdHiAFMap = new Map<Id, String>();
            for(Integer i = 0; i < selectedBillingAccList.size(); i++){
                // create task
                taskRec = new Task();
                taskRec.Subject = 'Direct Debit - ' + actionType;
                taskRec.Hidden_Direct_Debit__c = true;
                if(actionType.equalsIgnoreCase('Cancel')){
                    taskRec.Hidden_Direct_Debit__c = false;
                    taskRec.Hidden_DD_Action_Type__c = 'Cancel';
                }
                taskRec.ActivityDate = date.today();
                taskRec.Type = 'Direct Debit';
                taskRec.WhatId = selectedBillingAccList[i].billingAccount.Id;
                // put in map for registerDeregisterCustomer
                whatIdHiAFMap.put(selectedBillingAccList[i].billingAccount.Id,selectedBillingAccList[i].billingAccount.HiAF_Account_Number__c);
                // put in map for wrap class
  
                whatIdNameMap.put(selectedBillingAccList[i].billingAccount.Id,selectedBillingAccList[i].billingAccount.Name);      
                taskRec.WhoId = userInputFields.Person__c;
                taskRec.Status = 'In Progress';
                taskRec.RecordTypeId = recordTypeId;

		        if(!'Standard'.equals(UserInfo.getUserType())){
		            taskRec.ownerId = PortalSettings__c.getInstance().Portal_Task_Default_User__c;
		        }

                if(!actionType.equalsIgnoreCase('Cancel')){
                    //default make as add
                    taskRec.Hidden_DD_Action_Type__c = 'Add';
                    taskRec.Group__c = 'Billing & Accounts';
                    taskRec.Category_Level_1__c = 'Account Payment & Collections';
                    taskRec.Category_Level_2__c = 'Payments';
                    taskRec.Category_Level_3__c = 'New Direct Debit';
                    taskRec.Mode__c = 'Query';
                    
                    //action is amend
                    if(selectedBillingAccList[i].billingAccount.Direct_Debit__c){
                        taskRec.Hidden_DD_Action_Type__c = 'Amend';
                        taskRec.Category_Level_3__c = 'Amend Direct Debit';
                    }
                    taskRec.Hidden_DD_Commencement_Date__c = userInputFields.DD_Commence_Date__c;
                    taskRec.Hidden_DD_Type__c = paymentType;           
                    if(paymentType.equalsIgnoreCase('Credit Card')){
                        ccLastThreeDigits = (userInputFields.Credit_Card_Number_4__c).subString(1,4);
                        ccFirstFourDigits = userInputFields.Credit_Card_Number_1__c; 
                        //taskRec.Hidden_CC_Amount__c = userInputFields.Amount__c;
                        taskRec.Hidden_CC_Number__c = ccFirstFourDigits +' **** **** *' + ccLastThreeDigits;
                        taskRec.Hidden_DD_Details__c = ccFirstFourDigits +' **** **** *' + ccLastThreeDigits + ' Expiry Date:' +
                                                       userInputFields.Expiration_Date_Month__c + '/' + userInputFields.Expiration_Date_Year__c;
                    }else{
                        taskRec.Hidden_DD_Details__c = userInputFields.DD_Financial_Institution__c + ' - ' + 
                                                       userInputFields.DD_BSB_No__c + '/***' + (userInputFields.DD_Account_No__c).subString(0,3) +
                                                       ' - ' + userInputFields.DD_Account_Name__c;      
                    }
                }else{
                    taskRec.Category_Level_1__c = 'Account Payment & Collections';
                    taskRec.Category_Level_2__c = 'Payments';
                    taskRec.Category_Level_3__c = 'Withdraw Direct Debit';
                    taskRec.Mode__c = 'Action';
                }
                newTaskList.add(taskRec);
            }
        }
        try{
            upsert newTaskList;
            taskIdSet = new Set<Id>();
            for(Integer i = 0; i < newTaskList.size(); i++){
                taskIdSet.add(newTaskList[i].Id);   
            }
            
            return true;
        }catch (DmlException e){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Task Creation Failed.');
        }
        return false;
     }
     
     // for credit card expiration year
     public List<SelectOption> getItems() {
        Integer currentYear = date.today().year(); 
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', '--None--'));
        for (Integer i = 0; i < 5; i++){
            Integer yearOption = currentYear + i;
            options.add(new SelectOption(yearOption+'', yearOption+''));
        }
        return options;
    }
    
    // inner 'wrapper' class for Billing Account 
    public class BillingAccWrap{
        
        public Billing_Account__c billingAccount{get;set;}
        
        public BillingAccWrap(Billing_Account__c ba){
            this.billingAccount = ba;
        }
        
        public boolean isSelected{
            get{
                if(isSelected == null){
                    isSelected = false;
                } return isSelected;
            }set;
        }
        
        // does the billing account have an AX or PI classification?
        public boolean hasAXorPI{
            get{
                if (hasAXorPI == null) { // ensures getter method only called once
                    List<Customer_Classification__c> custClasses = billingAccount.Customer_Classifications__r;

                    if(custClasses != null) {
                        for(Customer_Classification__c c : custClasses) {
                            if(c.Class_Code__c == 'AX' || c.Class_Code__c == 'PI') {
                                hasAXorPI = true;
                            }
                        }
                    }
                    if(hasAXorPI == null) {
                        hasAXorPI = false;
                    }
                }
                return hasAXorPI;
            }
            set;
        }
        
        // does the billing account have a CL classification? (centrelink)
        public boolean hasCL {
            get{
                if (hasCL == null) { // ensures getter method only called once
                    List<Customer_Classification__c> custClasses = billingAccount.Customer_Classifications__r;
                    
                    if(custClasses != null) {
                        for(Customer_Classification__c c : custClasses) {
                            if(c.Class_Code__c == 'CL') {
                                hasCL = true;
                            }
                        }
                    }
                    if(hasCL == null) {
                        hasCL = false;
                    }                                       
                }               
                return hasCL;           
            }
            set;
        }
    }

    // inner 'wrapper' class for tasks    
    public class TaskWrap{
        
        public Task newTask{get;set;}
        
        public TaskWrap(Task t){
            this.newTask = t;
        }
        
        public String taskAction;
        public String billingAccName;
        public String HiAFNo{get;set;}
        
        public String getTaskAction(){
            return taskAction;
        }
        
        public void setTaskAction(String ta){
            taskAction = ta;
        }
        
        public String getBillingAccName(){
            return billingAccName;
        }
        
        public void setBillingAccName(String name){
            billingAccName = name;
        }
    }
    
    public void selectAllRecords(){
        //setSelectOnAllRecords(true);
        for(BillingAccWrap ba: billingAccList){
            ba.isSelected = true;
        }
    }
    public void unselectAllRecords(){
        //setSelectOnAllRecords(false);
        for(BillingAccWrap ba: billingAccList){
            ba.isSelected = false;
        }
    }


    // Test method    
    public static testmethod void testDirectDebitController(){
        
        Account testAcc = new Account(name = 'Test Account');
        Database.insert(testAcc);
        
        // for testing class-code 'CL'
        Account testAcc1 = new Account(name = 'Test Account1');
        Database.insert(testAcc1);
        
        Billing_Account__c ba = new Billing_Account__c(name = 'Test Billing Account', Customer__c = testAcc.id, Direct_Debit__c = true, Recovery_Last_Action_Date__c = system.today()-5);
        Database.insert(ba);
        
        Billing_Account__c baAX = new Billing_Account__c(name = 'Test Billing Account AX', Customer__c = testAcc.id, Direct_Debit__c = true);
        Database.insert(baAX);
        
        Classification_Code__c code;
        Classification_Code__c code1;
        
        try {
            code = [SELECT name, Is_Active__c, Short_Description__c FROM Classification_Code__c WHERE name = 'AX'];
        } catch (QueryException e) {
            code = new Classification_Code__c();
            code.Name = 'AX';
            code.Is_Active__c = true;
            code.Short_Description__c = 'Foo';          
            insert code;
        }
        
        try {
            code1 = [SELECT name, Is_Active__c, Short_Description__c FROM Classification_Code__c WHERE name = 'CL'];
        } catch (QueryException e) {
            code1 = new Classification_Code__c();
            code1.Name = 'CL';
            code1.Is_Active__c = true;
            code1.Short_Description__c = 'Foo';         
            insert code1;
        }
               
        Customer_Classification__c customer_class = new Customer_Classification__c(Customer__c = testAcc.id, Billing_Account__c = baAX.id, Classification__c = code.Id);
        Database.insert(customer_class);
        
        Customer_Classification__c customer_class1 = new Customer_Classification__c(Customer__c = testAcc1.id, Billing_Account__c = ba.id, Classification__c = code1.Id);
        Database.insert(customer_class1);
         
        Credit_Card_Proxy__c testInput = new Credit_Card_Proxy__c();
        
        Contact person = new Contact(firstname='test', lastname='user');
        Database.insert(person);
       
        PageReference pageRef = Page.DirectDebit;
        Test.setCurrentPage(pageRef);
        System.currentPageReference().getParameters().put('customerId',testAcc.Id);
        System.currentPageReference().getParameters().put('billAcctId',baAX.Id);
        System.currentPageReference().getParameters().put('budgets', 'true');
        DirectDebitController controller = new DirectDebitController();
        System.currentPageReference().getParameters().put('budgets', 'false');
        controller = new DirectDebitController();
        
        controller.getItems();
        controller.goBack();
        
        testInput.Billing_Account__c = ba.Id;
        // add/amend (bad credit card)
        // credit card / visa bad 
        testInput.DD_Account_Type__c = 'Credit Card';
        testInput.Credit_Card_Type__c = 'Visa';
        testInput.Credit_Card_Number_1__c = 'bad number';
        testInput.Credit_Card_Number_2__c = 'bad number';
        testInput.Credit_Card_Number_3__c = 'bad number';
        testInput.Credit_Card_Number_4__c = 'bad number';
        testInput.Expiration_Date_Year__c = '2013';
        testInput.Expiration_Date_Month__c = '06';
        testInput.Name_on_Card__c = 'Tester';
        //testInput.Amount__c = 100;
        testInput.CVN__c = 'bad CVN';
        testinput.person__c = person.Id;
        
        controller.userInputFields = testInput;
        controller.agreedTerms = true;
        System.assertEquals(controller.isValidData(), false);
        
        controller.amend();
        testInput.DD_Account_Type__c = 'Credit Card';
        controller.submit();
        
        // bad (bank account)
        testInput.DD_Account_Type__c = 'Bank Account';
        testInput.DD_BSB_No__c = '12';
        testInput.DD_Account_No__c = '88';
        testInput.DD_Account_Name__c = 'SEW';
        testInput.DD_Financial_Institution__c = 'ANZ';
        testinput.person__c = person.Id;
        controller.userInputFields = testInput;
        
        System.assertEquals(controller.isValidData(),false);
        
        
        // add/amend (bank account)
        testInput.DD_Account_Type__c = 'Bank Account';
        testInput.DD_BSB_No__c = '123456';
        testInput.DD_Account_No__c = '8888888888';
        testInput.DD_Account_Name__c = 'SEW';
        testInput.DD_Financial_Institution__c = 'ANZ';
        testinput.person__c = person.Id;
        controller.userInputFields = testInput;
        
        controller.amend();

        testInput.DD_Account_Type__c = 'Bank Account';
        controller.submit();
        controller.registerDeregisterCustomer();
        
        // add/amend (good credit card)
        testInput.DD_Account_Type__c = 'Credit Card';
        testInput.Credit_Card_Type__c = 'Visa';
        testInput.Credit_Card_Number_1__c = '4005';
        testInput.Credit_Card_Number_2__c = '5500';
        testInput.Credit_Card_Number_3__c = '0000';
        testInput.Credit_Card_Number_4__c = '0001';
        testInput.CVN__c = '888';
        testinput.Amount__c = 100;
        testinput.person__c = person.Id;
        
        controller.userInputFields = testInput;
        controller.agreedTerms = true;
        System.assertEquals(controller.isValidData(), true);
        
        controller.amend();
        testInput.DD_Account_Type__c = 'Credit Card';
        controller.submit();        
        controller.registerDeregisterCustomer();
        
        
        for(Integer i = 0; i < (controller.billingAccList).size(); i++){
            (controller.billingAccList[i]).isSelected = true;
        }
        controller.unselectAllRecords();
        controller.selectAllRecords();      
        
        controller.actionType = 'Add';
        controller.createTask();
        controller.checkStatus();
        controller.redirect = true;
        
        System.assert(controller.taskList != null);     
        controller.registerDeregisterCustomer();    
        
        controller.actionType = 'Amend';
        controller.createTask();
        controller.checkStatus();
        controller.redirect = true;
        
        System.assert(controller.taskList != null);     
        controller.registerDeregisterCustomer(); 
        
        // remove
        controller.actionType = 'Cancel';
        controller.createTask();
        controller.remove();
        controller.redirect = true;
        controller.notCompleted = false;
        controller.Redirect();
        controller.registerDeregisterCustomer();
        controller.timeOut = true;
        controller.timeOut();
        
    
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];        
        //create a user
        User testUser = new User(LastName = 'test',
                                 Email = 'test@salesforce.com',
                                 Alias = 'tu',
                                 LocaleSidKey = 'en_AU',
                                 EmailEncodingKey = 'UTF-8',
                                 LanguageLocaleKey = 'en_US',
                                 TimeZoneSidKey = 'Australia/Sydney',       
                                 username = 'test@portal.sewl.com.au.cfg',
                                 Secret_Question__c = 'What is the name of your favorite pet?',
                                 Secret_Answer__c = 'dog',
                                 ProfileId = p.Id,
                                 Require_Portal_Password_Reset__c = true);
        insert testUser;
        System.runAs(testUser) {
            controller.remove();
            controller.redirect = true;
            controller.notCompleted = false;
            controller.Redirect();
            testinput.person__c = person.Id;
            controller.userInputFields = testInput;
            //controller.registerDeregisterCustomer();
            controller.timeOut = true;
            controller.timeOut();   
        }
        
        pageRef = Page.DirectDebit;
        Test.setCurrentPage(pageRef);
        System.currentPageReference().getParameters().put('customerId',testAcc1.Id);
        System.currentPageReference().getParameters().put('billAcctId',ba.Id);
        System.currentPageReference().getParameters().put('budgets', 'true');
        controller = new DirectDebitController();

        testInput.DD_Account_Type__c = 'Bank Account';
        testInput.DD_BSB_No__c = '123456';
        testInput.DD_Account_No__c = '8888888888';
        testInput.DD_Account_Name__c = 'SEW';
        testInput.DD_Financial_Institution__c = 'ANZ';
        testinput.person__c = person.Id;
        controller.userInputFields = testInput;
        
        controller.userInputFields = testInput;
        controller.agreedTerms = true;
        System.assertEquals(controller.isValidData(), true);
        
        for(Integer i = 0; i < (controller.billingAccList).size(); i++){
            (controller.billingAccList[i]).isSelected = true;
        }
        
        controller.amend();
        controller.submit();        
        controller.registerDeregisterCustomer();
        
        // coverage
        TIBCOPaymentGateway_MessageTypes.DirectDebit_element  dde = new TIBCOPaymentGateway_MessageTypes.DirectDebit_element();
        TIBCOPaymentGateway_MessageTypes.DebitCardDetails_element   dce = new TIBCOPaymentGateway_MessageTypes.DebitCardDetails_element ();
        TIBCOPaymentGateway_MessageTypes.ErrorStatus_element   ese = new TIBCOPaymentGateway_MessageTypes.ErrorStatus_element ();
         

    }
}