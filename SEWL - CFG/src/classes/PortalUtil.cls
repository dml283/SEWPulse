/*
    Type:       Utilities
    Purpose:    Web service for new portal user registration controller to call to register user

    Used By:    SiteNewPortalUserRegistrationController
    ---------------------------------------------------------------
    History:

    17-Aug-2011 J.Pe (Davanti) Created

*/
global without sharing class PortalUtil{
    
    /* PRIVATE VARIABLE */
    private static final Id PORTAL_PROFILE_ID;
    
    /* STATIC METHOD */
    static {
        PORTAL_PROFILE_ID = [Select id from Profile where Name = 'SEW Portal User' and UserType = 'CSPLitePortal'].id;
    }

    /* WEBSERVICE METHOD */
    webservice static PortalUtilResponse newUserRegistration(Id contactId, String userName, String password, String email, String secretQtn, String secretAns, Boolean isMarketingOpIn){
            List<Contact> personRecs = [Select id, FirstName, LastName, Marketing_Opt_In__c from Contact where id = : contactId];
            if(personRecs ==null || personRecs.size()==0) {
                PortalUtilResponse response = new PortalUtilResponse();
                response.isSuccessful = false;
                response.errorMessage = 'Contact Record not found for id '+contactId;
                return response;
            }
            Contact personRec = personRecs[0];
            User newUser = new User();
            newUser.username = convertUserName(username);
            newUser.email = email;
            newUser.firstname = personRec.FirstName;
            newUser.lastname = personRec.LastName;
            newUser.Secret_Question__c = secretQtn;
            newUser.Secret_Answer__c = secretAns;
            newUser.contactid = contactId;
            newUser.CommunityNickname = String.valueof(System.now())+((newUser.username.length()>10)?(newUser.username.substring(0,10)):(newUser.username));
            newUser.alias = 'standt';
            newUser.emailencodingkey='UTF-8';
            newUser.languagelocalekey='en_US';
            newUser.localesidkey='en_AU';
            newUser.profileid = PORTAL_PROFILE_ID;
            newUser.timezonesidkey='Australia/Sydney';
            newUser.Require_Portal_Password_Reset__c = false;
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.EmailHeader.triggerUserEmail = false;
            newUser.setOptions(dmo);
            personRec.Email = newUser.email;
            personRec.Marketing_Opt_In__c = isMarketingOpIn;
            Savepoint sp = Database.setSavepoint();
            try{
                insert newUser;
                System.setPassword(newUser.id, password);
                personRec.HIDDEN_Is_Send_Portal_Registration_Email__c = true;
                personRec.HIDDEN_Portal_Username__c = newUser.username;
                update personRec;
                PortalUtilResponse response = new PortalUtilResponse();
                response.isSuccessful = true;
                return response;
            }catch(Exception e){
                Database.rollback(sp);
                PortalUtilResponse response = new PortalUtilResponse();
                response.isSuccessful = false;
                response.errorMessage = e.getMessage();
                return response;
            }
    }

    /* PUBLIC METHOD */
    public static String convertUserName(String newusername){
        // append site prefix + .sewl.com.au if no @ in the username
        if (!newusername.contains('@')) {
//            String prefix = Site.getPrefix();
//            if (prefix != null) {
//                prefix=prefix.replace('/', '');
//                newusername = newusername + '@' + prefix + 'portal.sewl.com.au';
//            } else {
                newusername = newusername + '@portal.sewl.com.au';
//            }

            // append the sandbox name if any
            String sandbox = PortalSettings__c.getInstance().Sandbox_Name__c;
            if (sandbox != null && sandbox != '')
              newusername += '.' + sandbox;
        }
        return newusername;
    }
    
    /* INNER CLASS */
    global class PortalUtilException extends Exception{}
    global class PortalUtilResponse{
        webservice boolean isSuccessful;
        webservice String errorMessage;
    }

    /* TEST METHOD */
    public static testmethod void test_PortalUtil(){
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
        PortalUtilResponse response = PortalUtil.newUserRegistration(account.id, 'sdgsdg', 'sdfse3fgdf4', 'sdfsd@wertwer.com','edfwefw','wefwf',true);
        System.assertEquals(false, response.isSuccessful);
        response = PortalUtil.newUserRegistration(contact.id, 'sdgsdg', 'sf4', 'sdfsd@wertwer.com','edfwefw','wefwf',true);
        System.assertEquals(false, response.isSuccessful);
        response = PortalUtil.newUserRegistration(contact.id, 'sdgsdg', 'sdfse3fgdf4', 'sdfsd@wertwer.com','edfwefw','wefwf',true);
        contact = [Select id, Email, HIDDEN_Portal_Username__c from Contact where id = :contact.id];
        String testUsername = 'sdgsdg@portal.sewl.com.au';
            String sandbox = PortalSettings__c.getInstance().Sandbox_Name__c;
            if (sandbox != null && sandbox != '')
              testUsername += '.' + sandbox;
        System.assertEquals(testUsername , contact.HIDDEN_Portal_Username__c);
        System.assertEquals('sdfsd@wertwer.com', contact.Email);
    }
}