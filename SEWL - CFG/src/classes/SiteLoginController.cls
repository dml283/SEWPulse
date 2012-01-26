/*
    Type:      ChangePasswordController Class
    Purpose:   An apex page controller that exposes the site login functionality

    Used By:   Component: SiteLogin, VF:SiteLogin
    ---------------------------------------------------------------
    History:
                      Dennis Thong   Created
        09-Nov-2011 - Ji Zhang(Coretec Solutions) Mondified
*/ 
global with sharing class SiteLoginController {
    global String username {get; set;}
    global String password {get; set;}
    global String sitename {get; set;}
    
    private User user;

    global PageReference login() {
        String startUrl = System.currentPageReference().getParameters().get('startURL');
        if (startUrl == null || startUrl == '') {
            String sitePrefix = Site.getPrefix();

            /*if (sitePrefix == null || sitePrefix == '')
                startUrl = '/home/home.jsp';
            else
                startUrl = Site.getPrefix() + '/home/home.jsp';*/
        }

        String newusername = convertUserName(username); 
        setLoginUser(newusername);  
        // check if this is the first time that user logins in
        // if this is the first time redirect to change password page
        if(isFirstTime()){
            startUrl = '/ChangePassword';
            
        }else if(notSetSecretQuestion()){
            startUrl = '/SecretQuestion';   
        }
        return Site.login(newusername, password, startUrl);
    }
    
    public String convertUserName(String name){
        String newusername = name;
        // append site prefix + .sewl.com.au if no @ in the username
        if (!newusername.contains('@')) {
            String prefix = Site.getPrefix();
            if (prefix != null) {
                prefix=prefix.replace('/', '');
                newusername = newusername + '@' + prefix + '.sewl.com.au';
            } else {
                newusername = newusername + '@sewl.com.au';
            }

            // append the sandbox name if any
            String sandbox = PortalSettings__c.getInstance().Sandbox_Name__c;
            if (sandbox != null && sandbox != '')
                newusername += '.' + sandbox;
        }
        return newusername;
    }
    
    public Boolean isFirstTime(){
        if (user != NULL){
            if(user.Require_Portal_Password_Reset__c){
                return true;
            }
        }
        return false;
    }
    
    public Boolean notSetSecretQuestion(){
        if (user != NULL){
            if(user.Secret_Question__c != NULL && user.Secret_Answer__c != NULL){
                return false;
            }
        }
        return true;
    }
    
    public void setLoginUser(String loginUserName){
    	this.user = null;
        for (User user : [Select Require_Portal_Password_Reset__c, Secret_Question__c, Secret_Answer__c
                From  User
                Where username = :loginUserName LIMIT 1]) {
        	this.user = user;        
        }
    }
    
    global PageReference ForgotPwd() {
        return Page.ForgotPassword;
    }
    
    global PageReference ForgotUsername() {
        return Page.ForgotUsername;
    }

    global SiteLoginController () {
        sitename = PortalSettings__c.getInstance().Sandbox_Name__c;
    }

    global static testMethod void testSiteLoginController () {
        // Instantiate a new controller with all parameters in the page
        SiteLoginController controller = new SiteLoginController ();
        controller.username = 'test@salesforce.com';
        controller.password = '123456';
        
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
        System.debug('***testUser***' + testUser);
        
        User firstTimeUser = [SELECT username from User where Require_Portal_Password_Reset__c = true LIMIT 1];
        if(firstTimeUser!=Null){
            controller.username = firstTimeUser.username;
            controller.setLoginUser(firstTimeUser.username);
            controller.isFirstTime();
            System.assertEquals(controller.login(),null);
        }
        
        User normalUser = [SELECT username from User where Require_Portal_Password_Reset__c = false LIMIT 1];
        if(normalUser!=Null){
            controller.username = normalUser.username;
            controller.setLoginUser(normalUser.username);
            controller.isFirstTime();
            System.assertEquals(controller.login(),null);   
        }
        
        controller.username = 'test';
        controller.password = '123456';
        String name = 'test';
        controller.username = controller.convertUserName(name);
        controller.ForgotPwd();
        controller.ForgotUsername();
    }
}