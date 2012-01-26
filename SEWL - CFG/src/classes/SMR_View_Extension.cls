/*
    Type:       Controller Extension
    Purpose:    Controller to validate, process and cancel SMR

    Used By:    SMR_Validate, SMR_Perform, SMR_Cancel
    ---------------------------------------------------------------
    History:

    17-Aug-2011 J.Pe (Davanti) Created

*/
public class SMR_View_Extension {

    /* PUBLIC GETTERS/SETTERS */
    public Case currentCase {
        get{
            if(stdCon == null) return null;
            else return (Case) stdCon.getRecord();
        }
    }

    /* PRIVATE GETTERS/SETTERS */
    private ApexPages.StandardController stdCon {get;set;}
    /*
    private String currentUserProfileName  {get;set;}
    private boolean isSEWCreditUserProfile{
        get{
            return SEW_CREDIT_USER_PROFILE_NAME.equals(currentUserProfileName);
        }
    }
    */
    /* CONSTANTS */
    private static final string OPERATION_VALIDATE = 'validate';
    private static final string OPERATION_PERFORM = 'perform';
    private static final string ACTION_CREATE = 'Create';
    private static final string ACTION_AMEND = 'Amend';
    private static final string ACTION_CANCEL = 'Cancel';
    //private static final string SEW_CREDIT_USER_PROFILE_NAME = 'SEW Credit User';
    /* CONSTRUCTORS */
    public SMR_View_Extension(ApexPages.StandardController controller) {
        stdCon = controller;
        if(!Test.isRunningTest()){
            stdCon.addFields(new String[]{'Contact_Type__c', 'Type_of_Read_INTEGRATION__c', 'Contact_Method__c',
                'Tenant_Action__c', 'Move_In_Out_Date__c', 'Reading_Date__c', 'Billing_Account__r.HiAF_Account_Number__c',
                'Street__c', 'City__c', 'State__c',
                'CaseNumber', 'Existing_Reading__c', /*'Private_Extension_Street__c', 'Private_Extension_City__c', 'Private_Exension_Postcode__c',*/ 'Is_Done_at_the_Back_End__c',
                'Amend_Read_Used__c', 'Is_Letter_to_Agent__c', 'Is_Letter_to_Owner__c', 'Tenant_Name__c', 'Agent_Name__c',
                'Agent_Address_1__c', 'Agent_Address_2__c', 'Is_SMR_Create_Validated__c', 'Is_SMR_Create_Performed__c',
                'Is_SMR_Amend_Validated__c', 'Is_SMR_Amend_Performed__c', 'IsClosed', 'Complete__c', /*'Private_Extension_Flag__c',*/ 'Property__r.CIS_Property_Id__c'});
        }
        //Profile currentUserProfile = [SELECT Name FROM Profile WHERE Id = :Userinfo.getProfileId()];
        //currentUserProfileName = currentUserProfile.Name;
    }

    public PageReference validate(){
        String actionName;
        boolean validated = true;
        try {
            resetInfoAndAlerts();
            // 1. Validate
            validated = validateOpPreCheck();
            // 2. Determine action
            if(currentCase.Is_SMR_Create_Validated__c && currentCase.Is_SMR_Create_Performed__c){
                actionName = ACTION_AMEND;
                currentCase.Is_SMR_Amend_Validated__c = false;
                currentCase.Is_SMR_Amend_Performed__c = false;
            }else{
                actionName = ACTION_CREATE;
                currentCase.Is_SMR_Create_Validated__c = false;
                currentCase.Is_SMR_Create_Performed__c = false;
            }
            // 3. Call and process WS
            if(validated){
                WSUtil_SpecialMeterRead.SMRResponse response = WSUtil_SpecialMeterRead.validateSpecialMeterRead(currentCase, actionName);
                processValidateResponse(response, actionName);
            }else{
                update currentCase;
            }
        } catch (WSUtil.MultipleWebServiceBusinessException e){
            processExceptions(e, OPERATION_VALIDATE, actionName);
        } catch (system.Calloutexception ex) { // SOAP Error
            ApexPages.addmessage(
                new ApexPages.message(ApexPages.severity.ERROR,'There was a problem calling the Validate on the Special Meter Read - please contact system administrator. Error message:'+ex.getMessage())
            );
            return null;
        }
        PageReference pageRef = new PageReference('/' + currentCase.id);
        pageRef.setRedirect(true);
        return pageRef;
    }

    public PageReference perform(){
        String actionName;
        boolean validated = true;
        try {
            resetInfoAndAlerts();
            // 1. Validate
            validated = performOpPreCheck();
            System.debug('****** validated = '+validated);
            // 2. Determine action
            if(currentCase.Is_SMR_Create_Validated__c && !currentCase.Is_SMR_Create_Performed__c){
                actionName = ACTION_CREATE;
            }
            else if(currentCase.Is_SMR_Create_Validated__c && currentCase.Is_SMR_Create_Performed__c && currentCase.Is_SMR_Amend_Validated__c && !currentCase.Is_SMR_Amend_Performed__c){
                actionName = ACTION_AMEND;
            } else{
                validated = false;
                currentCase.Alerts_Int_Long__c += 'ERROR - Perform action can only occur after validation\n';
            }
            // 3. Call and process WS
            if(validated){
                WSUtil_SpecialMeterRead.SMRResponse response = WSUtil_SpecialMeterRead.performSpecialMeterRead(currentCase, actionName);
                processPerformResponse(response, actionName);
            }else{
                update currentCase;
            }
        } catch (WSUtil.MultipleWebServiceBusinessException e){
            processExceptions(e, OPERATION_PERFORM, actionName);
        } catch (system.Calloutexception ex) { // SOAP Error
            ApexPages.addmessage(
                new ApexPages.message(ApexPages.severity.ERROR,'There was a problem calling the Perform on the Special Meter Read - please contact system administrator. Error message:'+ex.getMessage())
            );
            return null;
        }        PageReference pageRef = new PageReference('/' + currentCase.id);
        pageRef.setRedirect(true);
        return pageRef;
    }
    public PageReference cancel(){
        boolean validated = true;
        try {
            resetInfoAndAlerts();
            // 1. Validate
            // NO SFDC SIDE VALIDATION
            // 2. Determine action
            if(currentCase.isClosed || !currentCase.Is_SMR_Create_Performed__c){
                validated = false;
                currentCase.Alerts_Int_Long__c += 'ERROR - Cancel action can only occur if the request is created and not closed\n';
            }
            // 3. Call and process WS
            if(validated){
                WSUtil_SpecialMeterRead.SMRResponse response = WSUtil_SpecialMeterRead.validateSpecialMeterRead(currentCase, ACTION_CANCEL);
                if(response.isSuccessful){
                    response = WSUtil_SpecialMeterRead.performSpecialMeterRead(currentCase, ACTION_CANCEL);
                    processPerformResponse(response, ACTION_CANCEL);
                }else{
                    processValidateResponse(response, ACTION_CANCEL);
                }
            }else{
                update currentCase;
            }
        } catch (WSUtil.MultipleWebServiceBusinessException e){
            processExceptions(e, OPERATION_PERFORM, ACTION_CANCEL);
        } catch (system.Calloutexception ex) { // SOAP Error
            ApexPages.addmessage(
                new ApexPages.message(ApexPages.severity.ERROR,'There was a problem calling the Cancel on the Special Meter Read - please contact system administrator. Error message:'+ex.getMessage())
            );
            return null;
        }        PageReference pageRef = new PageReference('/' + currentCase.id);
        pageRef.setRedirect(true);
        return pageRef;
    }

    /* PRIVATE METHOD */
    private void processExceptions(WSUtil.MultipleWebServiceBusinessException e, String operationName, String actionName){
        // display any error messages
        if(e.multiEx.size()>0){
            for(WSUtil.SingleWebServiceBusinessException childEx: e.multiEx){
                currentCase.Alerts_Int_Long__c += childEx.getMessage()+'\n';
            }
        }
        // add case comment
//        CaseComment comment = new CaseComment(ParentId = currentCase.id);
//        comment.CommentBody = currentCase.Alerts_Int_Long__c;
        update currentCase;
//        insert comment;
    }
    private void resetInfoAndAlerts(){
        currentCase.Information_Int_Long__c = '';
        currentCase.Alerts_Int_Long__c = '';
    }
    private  void processValidateResponse(WSUtil_SpecialMeterRead.SMRResponse response, String actionName){
        processResponse(response, OPERATION_VALIDATE, actionName);
    }
    private  void processPerformResponse(WSUtil_SpecialMeterRead.SMRResponse response, String actionName){
        processResponse(response, OPERATION_PERFORM, actionName);
    }
    private void processResponse(WSUtil_SpecialMeterRead.SMRResponse response, String operationName, String actionName){
        // add case comment

        CaseComment comment = new CaseComment(ParentId = currentCase.id);
        comment.CommentBody = '';
        if(OPERATION_VALIDATE.equals(operationName)){
            comment.CommentBody += 'Validate Special Meter Read - '+actionName+' action - request results:\n\n';
            currentCase.status = 'In Progress';
            if(response.isSuccessful){// BRE worked
                if(ACTION_CREATE.equals(actionName)){
                    currentCase.Is_SMR_Create_Validated__c = true;
                }else if(ACTION_AMEND.equals(actionName)){
                    currentCase.Is_SMR_Amend_Validated__c = true;
                }
            }
        }else if (OPERATION_PERFORM.equals(operationName)){
            comment.CommentBody += 'Perform Special Meter Read - '+actionName+' action - request results:\n\n';
            if(response.isSuccessful){// BRE worked
                if (ACTION_CANCEL.equals(actionName)){
                    currentCase.Existing_Reading__c = null;
                    currentCase.Is_SMR_Cancelled__c = true;
                    currentCase.Status = 'Cancelled';
                }else{
                    if(ACTION_CREATE.equals(actionName)){
                        currentCase.Is_SMR_Create_Performed__c = true;
                    }else if(ACTION_AMEND.equals(actionName)){
                        currentCase.Is_SMR_Amend_Performed__c = true;
                    }
                    if(response.isSMRClosed){
                        currentCase.Status = 'Closed';
                        currentCase.Complete__c = true;
                    }else{
                        currentCase.Status = 'Waiting for HiAffinity';
                    }
                }
            }
        }
        update currentCase;
        //insert comment;
    }

    private boolean performOpPreCheck(){
        boolean validated = validateOpPreCheck();

        /*if(currentCase.Private_Extension_Flag__c){
            boolean privateExtensionCheck = true;
            if(currentCase.Private_Extension_Street__c == null || ''.equals(currentCase.Private_Extension_Street__c.trim())){
                privateExtensionCheck = false;
            }
            if(currentCase.Private_Extension_City__c == null || ''.equals(currentCase.Private_Extension_City__c.trim())){
                privateExtensionCheck = false;
            }
            if(currentCase.Private_Exension_Postcode__c == null || ''.equals(currentCase.Private_Exension_Postcode__c.trim())){
                privateExtensionCheck = false;
            }
            if (!privateExtensionCheck){
                validated = false;
                currentCase.Alerts_Int_Long__c += 'ERROR - Address must be specified when there is a private extension\n';
            }
        }*/
        return validated;
    }

    private boolean validateOpPreCheck(){
        boolean validated = allPreCheck();
        if(currentCase.Contact_Type__c != 'B/O Tenant' &&
                        currentCase.Contact_Type__c != 'B/O Sale' && 
                        isLessThanTwoBusinessDaysFromToday(currentCase.Reading_Date__c)){
            validated = false;
            currentCase.Alerts_Int_Long__c += 'ERROR - Reading date must be specified to at least 2 business days after today\n';
        }
        return validated;
    }
    private boolean allPreCheck(){
        boolean validated = true;
        if(currentCase.isClosed){
            validated = false;
            currentCase.Alerts_Int_Long__c += 'ERROR - Closed SMR cases cannot be edited\n';
        }
        return validated ;
    }

    private boolean isLessThanTwoBusinessDaysFromToday(Date checkDate){
        return CaseUtil.isLessThanTwoBusinessDaysFromToday(checkDate);
    }

    public PageReference back(){
        return new PageReference('/' + currentCase.Id);
    }

    public static testmethod void testMe1(){
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

        Case smrCase = new Case();
        smrCase.AccountId = account.id;
        smrCase.Property__c = prop.id;
        smrCase.Billing_Account__c = billAcc.id;
        smrCase.Reading_Date__c = Date.newInstance(2050, 1, 1);



        // Validate then perform
        insert smrCase;
        smrCase = test_QueryCase(smrCase.id);
        ApexPages.StandardController stdCon = new ApexPages.StandardController(smrCase);
        SMR_View_Extension excon = new SMR_View_Extension(stdCon);

        // try to perform first - error
        excon.perform();
        smrCase = test_QueryCase(smrCase.id);
        System.assertEquals('In Progress', smrCase.Status);

        // try to cancel - error
        excon.cancel();
        smrCase = test_QueryCase(smrCase.id);
        System.assertEquals('In Progress', smrCase.Status);

        // CREATE
        // validate
        excon.validate();
        smrCase = test_QueryCase(smrCase.id);
        System.assertEquals('In Progress', smrCase.Status);

        // perform
        excon.perform();
        smrCase = test_QueryCase(smrCase.id);
        System.assertEquals('Closed', smrCase.Status);

        // AMEND
        // validate first
        excon.validate();
        smrCase = test_QueryCase(smrCase.id);
        System.assertEquals('In Progress', smrCase.Status);

        // perform
        excon.perform();
        smrCase = test_QueryCase(smrCase.id);
        System.assertEquals('Closed', smrCase.Status);

        // Cancel
        excon.cancel();
        smrCase = test_QueryCase(smrCase.id);
        System.assertEquals('Cancelled', smrCase.Status);

    }

    public static testmethod void testMe2(){
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

        Case smrCase = new Case();
        smrCase.AccountId = account.id;
        smrCase.Property__c = prop.id;
        smrCase.Billing_Account__c = billAcc.id;
        smrCase.Reading_Date__c = System.today().addDays(-1);

        insert smrCase;
        smrCase = test_QueryCase(smrCase.id);
        ApexPages.StandardController stdCon = new ApexPages.StandardController(smrCase);
        SMR_View_Extension excon = new SMR_View_Extension(stdCon);

        // bad meter read date
        excon.validate();
        smrCase = test_QueryCase(smrCase.id);
        System.assertEquals('In Progress', smrCase.Status);

        // go back
        excon.back();

    }


    private static Case test_QueryCase(Id caseId){
        return [Select id, Status, Contact_Type__c, Type_of_Read_INTEGRATION__c, Contact_Method__c,
                Tenant_Action__c, Move_In_Out_Date__c, Reading_Date__c, Billing_Account__r.HiAF_Account_Number__c,
                CaseNumber, Existing_Reading__c, /*Private_Extension_Street__c, Private_Extension_City__c, Private_Exension_Postcode__c,*/ Is_Done_at_the_Back_End__c,
                Amend_Read_Used__c, Is_Letter_to_Agent__c, Is_Letter_to_Owner__c, Tenant_Name__c, Agent_Name__c,
                Agent_Address_1__c, Agent_Address_2__c, Is_SMR_Create_Validated__c, Is_SMR_Create_Performed__c,
                Is_SMR_Amend_Validated__c, Is_SMR_Amend_Performed__c, IsClosed, Complete__c/*, Private_Extension_Flag__c*/ from Case where id = :caseId];
    }
}