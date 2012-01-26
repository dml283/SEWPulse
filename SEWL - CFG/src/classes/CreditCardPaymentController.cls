/*
    Type:       Custom Controller
    Purpose:    Capture Credit Card Payment information and control VF page
                
    Used By:    CreditCardPayment, CreditCardPaymentFeedback
    ---------------------------------------------------------------
    History:
     
    14-11-2011 Ji Zhang (Coretec Solutions)   Created
    05-12-2011 Ji Zhang (Coretec Solutions)   Added Webservice
*/

public class CreditCardPaymentController {
        
    public Task taskRec{get;set;}
    public Boolean submitting{get;set;}
    public Boolean paymentSucceeded{get;set;}
    public Boolean redirect{get;set;}
    public Id taskId{get;set;}
    public Boolean gatewayStatus{get;set;}
    public Boolean timeOut{get;set;}

    // Fields for holding VF page elements
    public Credit_Card_Proxy__c userInputFields{
        get{
            if(userInputFields == null){
                userInputFields = new Credit_Card_Proxy__c();
            }
            return userInputFields;
        }set;
    }
    
    private Integer timesPolled{get;set;}
    private String paymentMsg{get;set;}
    private String ccFirstFourDigits{get;set;}
    private String ccLastThreeDigits{get;set;}
    private Boolean isPortal{
        get {
            if(UserInfo.getUserType()=='Standard') 
                return true;
            else
                return false;
        }
        set;
    }

    private static final Integer CONST_MAX_TIMES_POLLED = 48;
    
    public CreditCardPaymentController(){
        Map<String, String> param = Apexpages.currentPage().getParameters();
        isPortal = false;
        if(param.get('customerId')!= null) userInputFields.Customer_Account__c = ((ID)param.get('customerId'));
        if(param.get('billAcctId')!= null) userInputFields.Billing_Account__c = ((ID)param.get('billAcctId'));
        if(param.get('Id')!= null)
        {
             userInputFields.Billing_Account__c = ((ID)param.get('Id'));
             User user = [Select ContactId, AccountId
                          From  User
                          Where Id = :UserInfo.getUserId() LIMIT 1];
             userInputFields.Customer_Account__c = user.AccountId;
             
        }
        submitting = false;
        redirect = false;
        timeOut = false;
        timesPolled = 0;
        
        // Set initial billing account and balance
        if(userInputFields.Billing_Account__c != null && userInputFields.Amount__c == null){
            userInputFields.Billing_Account__r = [Select id, Name, Balance__c, HiAF_Account_Number_Check_Digit__c, Property_Address__c from Billing_Account__c where id = :userInputFields.Billing_Account__c];
            userInputFields.Amount__c = userInputFields.Billing_Account__r.Balance__c;
        }    
        
        //check gateway status
        WSUtil_Payment ws = new WSUtil_Payment();
        gatewayStatus = false;
        String errMsg = 'IP payment gateway service is down. Please try it again later.';
        // portal user display portal error message
        if(UserInfo.getUserType() != 'Standard') errMsg = PortalErrorMessages__c.getValues('IPPaymentGatewayOffline').Portal_Error_Msg__c;
        try{
            if(ws.getStatus() == 'Ok'){
                gatewayStatus = true;
            }else{
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, errMsg));
            }
        }catch(WSUtil.MultipleWebServiceBusinessException multiEx){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, errMsg));
        }catch (Exception ex){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, errMsg));
        }
    }
    
    public PageReference getAmount(){   
        if(userInputFields.Billing_Account__c != null){
            userInputFields.Billing_Account__r = [Select id, Name, Balance__c, HiAF_Account_Number_Check_Digit__c, Property_Address__c from Billing_Account__c where id = :userInputFields.Billing_Account__c];
            userInputFields.Amount__c = userInputFields.Billing_Account__r.Balance__c;     
        }    
        return null;
    }
    
    /* VF Submit button function */      
    public PageReference submit(){ 
        
        taskRec = null;
        
        if(!isValidData())return null;
        if(!createTask())return null;
        
        // reset for next time re-submitting
        timesPolled = 0;
        submitting = true;
        return null;
    }
    
    /* Submit payment to webservice */  
    public PageReference submitPayment(){
        
        if (taskRec == null) return null;
        
        // submit for webservice
        WSUtil_Payment ws = new WSUtil_Payment();
        WSUtil_Payment.PaymentDetails p = new WSUtil_Payment.PaymentDetails();
        
        
        p.TaskID = (String)taskRec.Id;
        p.TransactionType = '1';         
        p.BillingAccountNumber = userInputFields.Billing_Account__r.HiAF_Account_Number_Check_Digit__c;
        
        // format amount
        p.PaymentAmount = String.valueOf((userInputFields.Amount__c * 100).intValue());
        
        p.TransactionRef = p.TaskID;
        
        p.CardNumber = userInputFields.Credit_Card_Number_1__c + userInputFields.Credit_Card_Number_2__c + userInputFields.Credit_Card_Number_3__c + userInputFields.Credit_Card_Number_4__c;
        p.CardExpiryMonth = userInputFields.Expiration_Date_Month__c;
        p.CardExpiryYear = userInputFields.Expiration_Date_Year__c;
        p.CVN = userInputFields.CVN__c;
        p.CardHolderName = userInputFields.Name_on_Card__c;

        try{
            ws.submitPayment(p);
        }catch(WSUtil.MultipleWebServiceBusinessException multiEx){
            for(WSUtil.SingleWebServiceBusinessException ex : multiEx.multiEx){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Credit Card Payment Web Service error: '+ex.getMessage()));
            }
        }catch (Exception ex){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Unknown error: '+ex.getMessage()));

        }
        return null;
    }
    
    // pay another bill button
    public PageReference payBill(){  
        userInputFields.Billing_Account__c = null;
        userInputFields.Amount__c = null;
        return Page.CreditCardPayment;
    }
    
    // data validation
    private Boolean isValidData(){
        boolean isValid = true;
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
        if(!isNumberic(userInputFields.CVN__c)|| (userInputFields.CVN__c).length()!= 3){
            userInputFields.CVN__c.addError('Not a Valid CVN Number.');
            isValid = false;
        }
        if(userInputFields.Amount__c < 1 || userInputFields.Amount__c > 5000){
            userInputFields.Amount__c.addError('The valid payment amount must be between $1 and $5000');
            isValid = false;
        }
        return isValid;
    }
     
    public PageReference checkStatus(){
        taskRec = [SELECT Status, Description, Hidden_Messages__c FROM Task WHERE Id =: taskId];   
        if(taskRec != NULL){
             if(taskRec.Status=='Completed'){
                 paymentMsg = 'Credit Card Payment Successful';
                 paymentSucceeded = true;
                 redirect = true;                
             }
             // check if failed
             if(taskRec.Status=='Failed'){
                 paymentMsg = 'Credit Card Payment was not successful - ' + taskRec.Hidden_Messages__c;
                 paymentSucceeded = false;
                 redirect = true;
             }
        } 
        
        if(timesPolled < CONST_MAX_TIMES_POLLED){
            timesPolled++;
        }else{
            timeOut = true;
        }    
        return null;
    } 
     
    public PageReference Redirect() {
        if (redirect) {
          redirect=false;
          submitting=false;
          if (paymentSucceeded)
              ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, paymentMsg));
          else
              ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, paymentMsg));
          
          if(!isPortal){    
            return Page.CreditCardPaymentFeedback;
          }
          return Page.PortalCCPaymentFeedback;
        }
        return null;
    }
    
    public PageReference Timeout() {
        if(timeOut){
            timeOut = false;
            submitting = false;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'The process timed out while processing the payment. Please contact the administrator.'));
        }
        return null;        
    }

    private Boolean createTask(){
        // create task
        taskRec = new Task();
        taskRec.Subject = 'Credit Card Payment';
        taskRec.ActivityDate = date.today();
        taskRec.Type = 'Credit Card Payment';
        taskRec.WhatId = userInputFields.Billing_Account__c;
        taskRec.Status = 'In Progress';
        
        ccLastThreeDigits = (userInputFields.Credit_Card_Number_4__c).subString(1,4);
        ccFirstFourDigits = userInputFields.Credit_Card_Number_1__c;
        
        taskRec.Hidden_CC_Amount__c = userInputFields.Amount__c;
        taskRec.Hidden_CC_Number__c = ccFirstFourDigits +' **** **** *' + ccLastThreeDigits;
        
        Id recordTypeId = [SELECT name FROM RecordType WHERE name = 'Read Only Tasks' LIMIT 1].Id;
        taskRec.RecordTypeId = recordTypeId;
        taskRec.Group__c = 'Billing & Accounts';
        taskRec.Category_Level_1__c = 'Account Payment & Collections';
        taskRec.Category_Level_2__c = 'Payments';
        taskRec.Category_Level_3__c = 'Credit Card Payment';
        taskRec.Mode__c = 'Action';
        
        if(isPortal){
            PortalSettings__c p = PortalSettings__c.getInstance(UserInfo.getProfileId());
            taskRec.OwnerId = p.Portal_Task_Default_User__c;
        }
        
        try{
            upsert taskRec;
            taskId = taskRec.Id;
            return true;
        }catch (DmlException e){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Task Creation Failed.');
        }
        return false;
    }
     
    // valid number only
    private boolean isNumberic(String str){
        Pattern p = Pattern.compile('^[0-9]+$');
        Matcher MyMatcher = p.matcher(str);
        return MyMatcher.matches();
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
    
    //Test Method
    public static testmethod void testCreditCardPaymentController(){
        Account testAcc = new Account(name = 'Test Account');
        Database.insert(testAcc);
        
        Billing_Account__c ba = new Billing_Account__c(name = 'Test Billing Account', Customer__c = testAcc.id);
        Database.insert(ba);
        
        Credit_Card_Proxy__c testInput = new Credit_Card_Proxy__c();
        testInput.Credit_Card_Type__c = 'Visa';
        testInput.Credit_Card_Number_1__c = 'bad number';
        testInput.Credit_Card_Number_2__c = 'bad number';
        testInput.Credit_Card_Number_3__c = 'bad number';
        testInput.Credit_Card_Number_4__c = 'bad number';
        testInput.Expiration_Date_Year__c = '2012';
        testInput.Expiration_Date_Month__c = '06';
        testInput.Amount__c = 5000;
        testInput.Name_on_Card__c = 'Tester';
        testInput.Amount__c = 10000;
        testInput.CVN__c = 'bad CVN';
        
        PageReference pageRef = Page.CreditCardPayment;
        Test.setCurrentPage(pageRef);
        System.currentPageReference().getParameters().put('customerId',testAcc.Id);
        System.currentPageReference().getParameters().put('billAcctId',ba.Id);
        System.currentPageReference().getParameters().put('Id',ba.Id);
        CreditCardPaymentController controller = new CreditCardPaymentController();
        controller.userInputFields = testInput;
        controller.isValidData();
        testInput.Credit_Card_Number_1__c = '1234';
        testInput.Credit_Card_Number_2__c = '5678';
        testInput.Credit_Card_Number_3__c = '9012';
        testInput.Credit_Card_Number_4__c = '3456';
        testInput.CVN__c = '888';
        testInput.Billing_Account__c = ba.id;   
        controller.userInputFields = testInput;
        controller.getAmount();
        testInput.Amount__c = 100;
        controller.userInputFields = testInput; 
        controller.redirect = null;
        controller.getItems();
       
        controller.submit();
        controller.paymentSucceeded = true;
        controller.paymentMsg = 'Credit Card Payment Successful';
        controller.checkStatus();
        controller.redirect = true;
        controller.Redirect();
        System.assertEquals(controller.redirect, false);
        
        controller.paymentSucceeded = false;
        controller.redirect = false;
        
        Task t = new Task();
        t.Subject = 'Credit Card Payment';
        t.ActivityDate = date.today();
        t.Type = 'Credit Card Payment';
        t.WhatId = ba.Id;
        t.Status = 'Completed';
        Database.insert(t);
        controller.taskRec = t;
        controller.taskId = t.id;
        controller.checkStatus();
        t.Status = 'Failed';
        Database.update(t);
        controller.taskId = t.id;
        controller.submitPayment();
        controller.checkStatus();
        controller.timeOut = true;
        controller.timeOut();
        controller.userInputFields = testInput;
        // test for time out
        for(Integer i = 0; i < 12; i++){ controller.checkStatus(); }
        controller.Redirect();
        controller.payBill();
    }
}