/*
    Type:       Utility Class
    Purpose:    (1) Prevent contacts from having their email address and/or mobile
    			removed when they are registered for eBilling against at least
    			1 billing account 
                
    Used By:    PersonTrigger
    ---------------------------------------------------------------
    History:
    
    29-Nov-2011	M.Watson (Salesforce)		Created
*/

public with sharing class PersonUtil {
	
	// Checks all contacts with removed email addresses to see if
	// they are registered for eBilling against any Billing Account
	public static void CheckEmaileBills (Map<Id,Contact> contactMap) {

		List<Contact> eBillContacts = [Select Id, 
		(Select id From eBill_Recipients__r where eBill_Method__c='Email' LIMIT 1)
                                            From Contact 
                                            where (Id in :contactMap.keySet())];
                                            
        for (Contact c : eBillContacts) {
        	if(contactMap.containsKey(c.id) && !c.eBill_Recipients__r.isEmpty()) {      		
        		contactMap.get(c.id).email.addError(' Cannot remove Email, person is registered for eBilling');
        	}
        }                                  		
	}
	
	// Checks all contact with removed mobile numbers to see if
	// they are registered for SMS Reminders against any Billing Account
	public static void CheckSMSReminders (Map<Id,Contact> contactMap) {

		List<Contact> SMSContacts = [Select Id, 
		(Select id From eBill_Recipients__r where Reminder_Method__c='SMS' LIMIT 1)
                                            From Contact 
                                            where (Id in :contactMap.keySet())];	
 
        for (Contact c : SMSContacts) {
        	if(contactMap.containsKey(c.id) && !c.eBill_Recipients__r.isEmpty()) {      		
        		contactMap.get(c.id).mobilephone.addError(' Cannot remove Mobile, person is registered for SMS Reminders');
        	}
        }    		
	}
	
	// test method
	static testMethod void testCheck()	{
		test.startTest();
		
        Account acc = new Account(name='test account');
        insert acc;
        
        Contact con = new Contact(accountid=acc.id, lastname='test', mobilephone='0411222333', email='test@test.com');
        insert con;		

        Billing_Account__c billAcc = new Billing_Account__c(
                                            name='test', customer__c=acc.id,
                                            eBill_Method__c = 'Email', eBill_Recipient__c=con.id,
                                            reminder_method__c = 'SMS'
                                            );
        insert billAcc;
        
        // test removal of email address
        con.email = null;
        try {
        	update con;      
        }
        catch (DmlException ex1) { 
        	// do nothing
        }
        Contact conOld1 = [Select Id, Email from Contact where Id=:con.id LIMIT 1];
        System.assert(conOld1.email != null);
        
        // test removal of mobile phone
        con.MobilePhone = null;
        try {
        	update con;      
        }
        catch (DmlException ex2) { 
        	// do nothing 
        }
        Contact conOld2 = [Select Id, MobilePhone from Contact where id=:con.id LIMIT 1];
        System.assert(conOld2.MobilePhone != null);
         		
		test.stopTest();
	} 

}