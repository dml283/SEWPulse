/*
    Type:       Controller Extension
    Purpose:    Controller to validate and process Suspend Recovery requests

    Used By:    SuspendRecovery_Validate, SuspendRecovery_Process
    ---------------------------------------------------------------
    History:

    17-Aug-2011 J.Pe (Davanti) Created

*/
public class SuspendRecovery_View_Extension {


    /* PUBLIC GETTERS/SETTERS */
    public Case currentCase {
        get{
            if(stdCon == null) return null;
            else return (Case) stdCon.getRecord();
        }
    }
    
    /* PRIVATE GETTERS/SETTERS */
    private ApexPages.StandardController stdCon {get;set;}
    private String currentUserProfileName  {get;set;}
    private boolean isSEWCreditUserProfile{
        get{
            return SEW_CREDIT_USER_PROFILE_NAME.equals(currentUserProfileName);
        }
    }
    
    /* CONSTANTS */
    private static final string OPERATION_VALIDATE = 'validate';
    private static final string OPERATION_PERFORM = 'perform';
    private static final string SEW_CREDIT_USER_PROFILE_NAME = 'SEW Credit User';

    /* CONSTRUCTORS */
    public SuspendRecovery_View_Extension(ApexPages.StandardController controller) {
        stdCon = controller;
        Profile currentUserProfile = [SELECT Name FROM Profile WHERE Id = :Userinfo.getProfileId()];
        currentUserProfileName = currentUserProfile.Name;
    }

    /* PUBLIC METHODS */
    public PageReference validate() {
        try {
            resetInfoAndAlerts();
            currentCase.Is_Suspend_Recovery_Validated__c = isSuspendRecoveryValid();
            // if not validated, update case, return, else proceed
            if(!currentCase.Is_Suspend_Recovery_Validated__c){
                update currentCase;
            }else{
                if(Date.today().daysbetween(currentCase.Suspend_To_Date__c)>14){
                    currentCase.Information_Int_Long__c += 'Suspend to date is over 14 days - please check with team leader for approval before performing suspend recovery.\n';
                }
                //if(currentCase.Billing_Account__r.Recovery_Next_Action__c != null){
                    //currentCase.Information_Int_Long__c += 'Next Recovery Action: '+currentCase.Billing_Account__r.Recovery_Next_Action__c+' - to be sent on '+currentCase.Billing_Account__r.Recovery_Next_Action_Date__c+'\n';
                //}
                WSUtil_SuspendRecovery.SuspendRecoveryResponse response = WSUtil_SuspendRecovery.validateSuspendRecovery(currentCase.Billing_Account__r.Name);
                processValidateResponse(response);
            }
        } catch (WSUtil.MultipleWebServiceBusinessException e){
            processExceptions(e, 'validate');
        } catch (Exception e) {
            ApexPages.addMessages(e);
            return null;
        }
        return new PageReference('/' + currentCase.id);
    }    
    
    public PageReference perform() {
        try {
            resetInfoAndAlerts();
            if(!currentCase.Is_Suspend_Recovery_Validated__c){
                currentCase.Alerts_Int_Long__c = 'ERROR - Request has not been validated.\n';            
            }else{
                currentCase.Is_Suspend_Recovery_Validated__c = currentCase.Is_Suspend_Recovery_Validated__c && isSuspendRecoveryValid();
            }
            if(!currentCase.Is_Suspend_Recovery_Validated__c){
                update currentCase;
            }else{
                WSUtil_SuspendRecovery.SuspendRecoveryResponse response = WSUtil_SuspendRecovery.performSuspendRecovery(currentCase.Billing_Account__r.Name, currentCase.Suspend_To_Date__c);
                processPerformResponse(response);
            }
        } catch (WSUtil.MultipleWebServiceBusinessException e){
            processExceptions(e, 'perform');
        } catch (Exception e) {
            ApexPages.addMessages(e);
            return null;
        }
        
        return new PageReference('/' + currentCase.id);
    }

    public PageReference back(){
        return new PageReference('/' + currentCase.Id);
    }

    /* PRIVATE METHOD */
    private boolean isSuspendRecoveryValid(){
        // check validation
        boolean hasCCCAndIsNotSEWCreditUser = hasCreditManagementClassification() && !isSEWCreditUserProfile;
        if(hasCCCAndIsNotSEWCreditUser ){
            currentCase.Alerts_Int_Long__c += 'ERROR - Customer has \"Credit Management\" classification. Only SEW Credit Users can perform Suspend Recovery on this account.\n';
        }
        if(currentCase.Billing_Account__r.Direct_Debit__c){
            currentCase.Alerts_Int_Long__c += 'ERROR - Billing Account cannot be suspended because it is on direct debit. Please refer customer to Direct Debit team.';
            if(currentCase.Billing_Account__r.Is_Payment_Plan__c){
                currentCase.Alerts_Int_Long__c += ' Please remember to mention that the billing account has a payment plan.';
            }
            currentCase.Alerts_Int_Long__c += '\n';
        }
        if(currentCase.Suspend_To_Date__c == null){
            currentCase.Alerts_Int_Long__c += 'ERROR - Suspend to date is not specified.';
        }
        return !hasCCCAndIsNotSEWCreditUser && !currentCase.Billing_Account__r.Direct_Debit__c && currentCase.Suspend_To_Date__c != null;
    }
    private void processExceptions(WSUtil.MultipleWebServiceBusinessException e, String operationName){
        currentCase.Alerts_Int_Long__c = 'ERROR - Suspend Recovery - '+operationName+' operation FAILED\n';
        // display any error messages
        if(e.multiEx.size()>0){
            for(WSUtil.SingleWebServiceBusinessException childEx: e.multiEx){
                currentCase.Alerts_Int_Long__c += childEx.getMessage()+'\n';
            }
        }
        // add case comment
        /*
        CaseComment comment = new CaseComment(ParentId = currentCase.id);
        comment.CommentBody = currentCase.Alerts_Int_Long__c;
        update currentCase;
        insert comment; */
    }
    
    private boolean hasCreditManagementClassification(){
        // check validation
        List<Customer_Classification__c> classifications = [Select id from Customer_Classification__c where Customer__c = :currentCase.Billing_Account__r.Customer__c and Is_Active__c = true and Classification__r.Name = 'CF'];
        return classifications.size()>0;
    }
    private  void processValidateResponse(WSUtil_SuspendRecovery.SuspendRecoveryResponse response){
        processResponse(response, OPERATION_VALIDATE);
    }
    private  void processPerformResponse(WSUtil_SuspendRecovery.SuspendRecoveryResponse response){
        processResponse(response, OPERATION_PERFORM);
    }
    
    private void resetInfoAndAlerts(){
        currentCase.Information_Int_Long__c = '';
        currentCase.Alerts_Int_Long__c = '';
    }
    
    private void processResponse(WSUtil_SuspendRecovery.SuspendRecoveryResponse response, String operationName){
        // display information
        if(response.isDirectDebit){
            currentCase.Information_Int_Long__c += 'Billing Account '+currentCase.Billing_Account__r.Name+' has a Direct Debit arrangement.\n';
        }
        if(response.LastRecoveryAction != null){
            currentCase.Information_Int_Long__c += 'Last Recovery Action: '+response.LastRecoveryAction+((response.LastRecoveryDate==null)?(''):(' - sent on '+response.LastRecoveryDate.format()))+'. Amount: '+response.LastRecoveryAmount+'\n';
        }
        if(response.LastNormalBillDate != null){
            currentCase.Information_Int_Long__c += 'Last Normal Bill Date: '+response.LastNormalBillDate.format() +'\n';
        }
        if(response.NextBillDate != null){
            currentCase.Information_Int_Long__c += 'Next Bill Date: '+response.NextBillDate.format() +'\n';
            if(Date.today().daysbetween(response.NextBillDate)<0){
                currentCase.Information_Int_Long__c += 'Next Bill Date has already been passed.\n';
            }
        }
        // display any alerts
        if(response.messages.size()>0){
            for(String msg: response.messages){
                currentCase.Alerts_Int_Long__c += msg+'\n';
            }
        }
        // update billing account
        Billing_Account__c bacct = [Select id, Recovery_Suspended_Date__c, Recovery_Next_Action_Date__c from Billing_Account__c where id =:currentCase.Billing_Account__c];
        bacct.Recovery_Suspended_Date__c = response.suspendDate;
        // add case comment
        //CaseComment comment = new CaseComment(ParentId = currentCase.id);
        //comment.CommentBody = '';
        if(OPERATION_VALIDATE.equals(operationName)){
            //comment.CommentBody += 'Validate Suspend Recovery - request results:\n\n';
            currentCase.status = 'In Progress';
            if(!response.isPassed){// BRE worked
                currentCase.Is_Suspend_Recovery_Validated__c = false;
                currentCase.Alerts_Int_Long__c = 'WARNING - Suspend Recovery validate operation FAILED\n'+currentCase.Alerts_Int_Long__c;
            }
        }else if (OPERATION_PERFORM.equals(operationName)){
            //comment.CommentBody += 'Perform Suspend Recovery - request results:\n\n';
            if(response.isPassed){// BRE worked
                currentCase.status = 'Completed';
                currentCase.Is_Suspend_Recovery_Performed__c = true;
                if(response.isDirectDebit){
                    currentCase.Is_Suspend_Recovery_Direct_Debit__c = true;
                }
            }else{
                currentCase.Alerts_Int_Long__c = 'ERROR - Suspend Recovery perform operation FAILED\n'+currentCase.Alerts_Int_Long__c;
            }
            // update suspend date
            currentCase.Suspend_To_Date__c = response.suspendDate;
        }
        /*
        if(!''.equals(currentCase.Alerts_Int_Long__c)){
            comment.CommentBody += 'Alerts:\n'+currentCase.Alerts_Int_Long__c + '\n';
        }
        if(!''.equals(currentCase.Information_Int_Long__c)){
            comment.CommentBody += 'Information:\n'+currentCase.Information_Int_Long__c + '\n';
        }
        */
                
        update currentCase;
        update bacct;
        //insert comment;
    }
    
    /* TEST METHOD */
    public static testmethod void test_SuspendRecovery_View_Extension(){
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
        
        billAcc = new Billing_Account__c();
        billAcc.Name = 'asetwetwrt';
        billAcc.Customer__c = account.id;
        billAcc.Property__c = prop.id;
        insert billAcc;
        
        Case suspendRecoveryCase = new Case();
        suspendRecoveryCase.AccountId = account.id;
        suspendRecoveryCase.Billing_Account__c = billAcc.id;
        insert suspendRecoveryCase;
        ApexPages.StandardController stdCon = new ApexPages.StandardController(suspendRecoveryCase);
        SuspendRecovery_View_Extension excon = new SuspendRecovery_View_Extension(stdCon);
        Test.startTest();
        // perform b4 validate
        excon.perform();
        
        // validate without date
        excon.validate();
        
        // validate with date > 14 days
        suspendRecoveryCase.Suspend_To_Date__c = System.today().addDays(15);
        excon.validate();

        // validate < 14 days
        suspendRecoveryCase.Suspend_To_Date__c = System.today();
        excon.validate();
        excon.perform();
        
        excon.back();
        
        TibcoSuspendRecovery_MessageTypes.ErrorStatus_element err = new TibcoSuspendRecovery_MessageTypes.ErrorStatus_element();
         
    }
}