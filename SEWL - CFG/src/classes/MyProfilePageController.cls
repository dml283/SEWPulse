/**
 * An apex class that keeps updates of a portal user in sync with its corresponding contact.
   Guest users are never able to access this page.
 */
public with sharing class MyProfilePageController {

    private User user;
    private boolean isEdit = false;
    
    public User getUser() {
        return user;
    }

    public MyProfilePageController() {
        user = queryUserInfo();
        // guest users should never be able to access this page
        if (user.usertype == 'GUEST') {
            throw new NoAccessException();
        }
    }
    
    public Boolean getIsEdit() {
        return isEdit;
    }
    
    public void edit() {
        isEdit=true;
    }    
    
    public void save() {
        if(!validateEntry()) return;
        user.username = PortalUtil.convertUserName(user.username);
        if (user.contact != null) {              
            setContactFields(user.contact, user);
        }
        
        try {
            update user;
            if (user.contact != null) { 
                update user.contact;
            }
            isEdit=false;
        } catch(DmlException e) {
            ApexPages.addMessages(e);
        }
    }
    
    public PageReference changePassword() {
        return Page.ChangePassword;
    }
    
    public void cancel() {
        isEdit=false;
        user = queryUserInfo();
    }
    
    private boolean validateEntry(){
        boolean isValid = true;
        if(user.userName == null || ''.equals(user.userName.trim())){
            user.userName.addError('Username is mandatory');
            isValid = false;
        }
        if(user.email == null || ''.equals(user.email.trim())){
            user.email.addError('E-mail is mandatory');
            isValid = false;
        }
        if(user.Secret_Question__c == null || ''.equals(user.Secret_Question__c.trim())){
            user.Secret_Question__c.addError('Secret Question is mandatory');
            isValid = false;
        }
        if(user.Secret_Answer__c == null || ''.equals(user.Secret_Answer__c.trim())){
            user.Secret_Answer__c.addError('Secret Answer is mandatory');
            isValid = false;
        }
        if(user.timezonesidkey == null || ''.equals(user.timezonesidkey.trim())){
            user.timezonesidkey.addError('Time Zone is mandatory');
            isValid = false;
        }
        return isValid;
    }
    
    private static void setContactFields(Contact c, User u) {
        c.email = u.email;
        //c.title = u.title;
        //c.firstname = u.firstname;
        //c.lastname = u.lastname;
        //c.phone = u.phone;
        //c.mobilephone = u.mobilephone;
        //c.fax = u.fax;
        //c.mailingstreet = u.street;
        //c.mailingcity = u.city;
        //c.mailingstate = u.state;
        //c.mailingpostalcode = u.postalcode;
        //c.mailingcountry = u.country;
    }
    
    private User queryUserInfo(){
        return [SELECT id, email, username, usertype, communitynickname, timezonesidkey, languagelocalekey, firstname, lastname, phone, title,
                street, city, country, postalcode, state, localesidkey, mobilephone, extension, fax, contact.email, User.Secret_Question__c, User.Secret_Answer__c
                FROM User
                WHERE id = :UserInfo.getUserId()];
    }

    static testMethod void testSave() {       
        User testUser;  
        // Modify the test to query for a portal user that exists in your org
        List<User> existingPortalUsers = [SELECT id, profileId, userRoleId FROM User WHERE UserRoleId <> null AND UserType='CustomerSuccess'];

        if (existingPortalUsers.isEmpty()) {
            testUser = [select id, title, firstname, lastname, email, phone, mobilephone, fax, street, city, state, postalcode, country
                                FROM User WHERE id =: UserInfo.getUserId()];
            /*MyProfilePageController controller = new MyProfilePageController();
            System.assertEquals(currentUser.Id, controller.getUser().Id, 'Did not successfully load the current user');
            System.assert(controller.isEdit == false, 'isEdit should default to false');
            controller.edit();
            System.assert(controller.isEdit == true);
            controller.cancel();
            System.assert(controller.isEdit == false);
            
            Contact c = new Contact();
            c.LastName = 'TestContact';
            insert c;
            
            setContactFields(c, currentUser);
            controller.save();
            System.assert(Page.ChangePassword.getUrl().equals(controller.changePassword().getUrl()));*/
        } else {
            testUser = existingPortalUsers[0];
        }
        System.runAs(testUser) {
                MyProfilePageController controller = new MyProfilePageController();
                System.assertEquals(testUser.Id, controller.getUser().Id, 'Did not successfully load the current user');
                System.assert(controller.getIsEdit() == false, 'isEdit should default to false');
                
                controller.edit();
                System.assert(controller.isEdit == true);
                
                controller.cancel();
                System.assert(controller.isEdit == false);
                
                String tempUsername = controller.getUser().username;
                controller.getUser().username = null;
                String tempEmail = controller.getUser().Email ;
                controller.getUser().Email = null;
                String tempTZKID = controller.getUser().timezonesidkey ;
                controller.getUser().timezonesidkey = null;
                controller.save();
                controller.getUser().username = tempUsername ;
                controller.getUser().Email = tempEmail ;
                controller.getUser().timezonesidkey = tempTZKID ;
                controller.getUser().Secret_Question__c = 'dfswdf';
                controller.getUser().Secret_Answer__c = 'dfswdf';
                Contact c = new Contact();
                setContactFields(c, testUser);
                controller.save();
                System.assert(controller.isEdit == false);
            }
    }

}