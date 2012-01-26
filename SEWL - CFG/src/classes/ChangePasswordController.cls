/*
    Type:      ChangePasswordController Class
    Purpose:   An apex page controller that exposes the change password functionality

    Used By:   ChangePassword VF page
    ---------------------------------------------------------------
    History:
                      Dennis Thong   Created
        08-Nov-2011 - Ji Zhang(Coretec Solutions) Mondified
*/ 
public with sharing class ChangePasswordController {
    public String oldPassword {get; set;}
    public String newPassword {get; set;}
    public String verifyNewPassword {get; set;}    
    public String secretAnswer{get;set;}
    public String secretQuestion{get;set;} 
    public String retURL {
    	get {
    		return ApexPages.currentPage().getParameters().get('retURL');
    	}	
    }
     
    private User u;
    public User getU(){
        return u;
    }
    
    public void setU(User myUser){
        this.u = myUser;
    }  
    
    public Boolean secretNotSet{
        get {
            if (u.Secret_Question__c != NULL && u.Secret_Answer__c != NULL)
                return false;
            return true;
        }
        set;
    }
    
    public Boolean isFirstTime{
        get {
            if (u.Require_Portal_Password_Reset__c)
                return true;
            return false;
        }
        set;
    } 

    public List<SelectOption> getQuestions()
    {
        List<SelectOption> options = new List<SelectOption>();
        
        Schema.DescribeFieldResult fieldResult = User.Secret_Question__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
                
        for(Schema.PicklistEntry f : ple)
        {
           options.add(new SelectOption(f.getLabel(), f.getValue()));
        }       
        return options;
    }
    
    public PageReference changePassword() {
        System.PageReference retURL = Site.changePassword(newPassword, verifyNewPassword, oldpassword);
        if(retURL != NULL){ 
            updateUserInfo();                   
	        // prevent double loop to change password
	        if (retURL.getURL().contains('ChangePassword'))
	        	retURL = new PageReference('/home/home.jsp');

        }
        

           
        return retURL;   
    }     
    
    public void updateUserInfo(){
        if(u.Require_Portal_Password_Reset__c)u.Require_Portal_Password_Reset__c = false;
        if(u.Secret_Question__c == NULL)u.Secret_Question__c = secretQuestion;
        if(u.Secret_Answer__c == NULL)u.Secret_Answer__c = secretAnswer;
        try{
            update u;  
        }catch(Exception e){}
    }
    
    public ChangePasswordController() {
        this.u = [Select Require_Portal_Password_Reset__c, Secret_Question__c, Secret_Answer__c
                  From  User
                  Where Id = :UserInfo.getUserId() LIMIT 1];
    }
    
    public static testMethod void testChangePasswordController() {
        // Instantiate a new controller with all parameters in the page
        ChangePasswordController controller = new ChangePasswordController();
        controller.getQuestions();
        System.assertEquals(controller.isFirstTime, false);
        System.assertEquals(controller.secretNotSet, true);
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
        User previousUser = controller.getU();
        controller.setU(testUser);
        System.debug('*** user ***' + controller.u.Secret_Question__c);
        System.assertEquals(controller.isFirstTime, true);
        System.assertEquals(controller.secretNotSet, false);
        controller.updateUserInfo();
        controller.oldPassword = '12345678';
        controller.newPassword = 'qwerty123'; 
        controller.verifyNewPassword = 'qwerty123';                       
        System.assertEquals(controller.changePassword(),null);   
        
        String url = controller.retURL;                        
    }    
}