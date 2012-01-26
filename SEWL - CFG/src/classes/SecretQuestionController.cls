/*
    Type:      SecretQuestionController Class
    Purpose:   An apex page controller that exposes the set secret question functionality

    Used By:   SecretQuestion VF page
    ---------------------------------------------------------------
    History:   09-Nov-2011 - Ji Zhang(Coretec Solutions) Created
*/ 
public with sharing class SecretQuestionController {
	private User user;
    
    public User getUser() {
        return user;
    }
    
    public SecretQuestionController() {
        user = queryUserInfo();
    }
    
    private User queryUserInfo(){
        return [SELECT id, email, username, usertype, communitynickname, timezonesidkey, languagelocalekey, firstname, lastname, phone, title,
                street, city, country, postalcode, state, localesidkey, mobilephone, extension, fax, contact.email, User.Secret_Question__c, User.Secret_Answer__c
                FROM User
                WHERE id = :UserInfo.getUserId()];
    }   
    
    public PageReference save() {
		if(!isValidData()) return null;
		
		try{
			update user;
		}catch(DmlException e) {
			ApexPages.addMessages(e);
		}   
		return new PageReference (Site.getPrefix() + '/home/home.jsp');	 	
    }
    
    private boolean isValidData(){
	    boolean isValid = true;
	    if(user.Secret_Question__c == null || ''.equals(user.Secret_Question__c.trim())){
	        user.Secret_Question__c.addError('Please Select a Secret Question.');
	        isValid = false;
	    }
	    if(user.Secret_Answer__c == null || ''.equals(user.Secret_Answer__c.trim())){
	        user.Secret_Answer__c.addError('Answer to Secret Question is required.');
	        isValid = false;
	    }
	    return isValid;
	}
	
	static testMethod void testSave() {
		User testUser;  
        // Modify the test to query for a portal user that exists in your org
        List<User> existingPortalUsers = [SELECT id, profileId, userRoleId, userType FROM User WHERE UserRoleId <> null AND UserType='CustomerSuccess'];

        if (existingPortalUsers.isEmpty()) {
            testUser = [select id, title, firstname, lastname, email, phone, mobilephone, fax, street, city, state, postalcode, country, userType
                                FROM User WHERE id =: UserInfo.getUserId()];
		} else {
            testUser = existingPortalUsers[0];
        }
        System.runAs(testUser) {
            SecretQuestionController controller = new SecretQuestionController(); 
            User myUser = controller.getUser();         
            controller.save();          
            myUser.Secret_Question__c = 'What is your favorite pet?';
            myUser.Secret_Answer__c = 'dog';
            controller.save();           
        }
	}
}