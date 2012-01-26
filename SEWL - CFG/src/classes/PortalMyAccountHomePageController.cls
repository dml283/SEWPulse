public with sharing virtual class PortalMyAccountHomePageController {

/*
    Type:       Controller
    Purpose:    Controller to display the list of current WaterMAPs

    Used By:    PortalMyAccountHomePage VF Page
    ---------------------------------------------------------------
    History:

    04-Nov-2011 D.Thong (Salesforce)    Created

*/

    /* PUBLIC PROPERTIES */
    // Standard Set Controller for accounts to control pagination
    public ApexPages.StandardSetController accountsSetCon { 
    	get {
    		if (accountsSetCon == null && user != null) {
    		    // Build Database Query Locator
        		Database.QueryLocator queryLocator = Database.getQueryLocator(
        				[select Id, Status__c, HiAF_Account_Number_Check_Digit__c, Property_Address__c, 
        							Balance__c, CIS_Property_Id__c, Property__r.Street_Address__c, 
        							Property__r.Suburb__c
                        from Billing_Account__c
                        where Status__c != 'Pending'
                        and Role__c not in ('Group', 'Ad-Hoc')
                        and (Customer__c = :user.AccountId or
                                Customer__r.ParentId = :user.AccountId)
                        ORDER BY HiAF_Account_Number_Check_Digit__c]);
	
	        	accountsSetCon = new ApexPages.StandardSetController(queryLocator );
	        	accountsSetCon.setPageSize(5); // set size to 5
    		}
    		return accountsSetCon; 
    	} 
    	
    	private set; 
    } // SSC for all related accounts

    public List<Billing_Account__c> accounts { 
        get {
            // return the current page set in the Std Set Controller
            if (accountsSetCon != null)
                return accountsSetCon.getRecords();
            
            return null;
        } 
        set; 
    }
    
    public List<Billing_Account__c> allAccounts {
    	get {
    		if (allAccounts == null && user != null) {
    			allAccounts = [select Id, Status__c, HiAF_Account_Number_Check_Digit__c, Property_Address__c, 
    							Balance__c, CIS_Property_Id__c, Property__r.Street_Address__c, 
        						Property__r.Suburb__c
                        from Billing_Account__c
                        where Status__c != 'Pending'
                        and Role__c not in ('Group', 'Ad-Hoc')
                        and (Customer__c = :user.AccountId or
                                Customer__r.ParentId = :user.AccountId)
                        ORDER BY HiAF_Account_Number_Check_Digit__c];
    		}
    		return allAccounts;
    	}
    	private set;
    }

	// The user's customer Id
    /*
    public Id customerId { 
    	get {
    		if (user != null)
    			return user.accountId;

    		return null;	
    	} 
    }*/

    public Integer nbrOfAccounts {
        get {
            Integer count=0;

            if (accounts != null)
                count = accounts.size();

            return count;
        }
    }
    
    public Long totalNoOfPages {
        get{
            if (accountsSetCon == null) return -1;
            return Integer.valueOf(Math.ceil(Double.valueOf(accountsSetCon.getResultSize())/Double.valueOf(accountsSetCon.getPageSize())));
        }
    }


    /* PRIVATE PROPERTIES */
    private User user {
 		get {   	
	       // assume that the user is always there!
			if (user == null) {
		        user = [Select ContactId, AccountId
	                        From  User
	                        Where Id = :UserInfo.getUserId() LIMIT 1];
			}
			return user;
 		}
 		private set;

    }
 
    /* CONSTRUCTOR */
    public PortalMyAccountHomePageController () {
                    
    }


    /* TESTER */
    private static testmethod void testme () {

        Test.StartTest();
        PortalMyAccountHomePageController pc = new PortalMyAccountHomePageController();
        Integer i = pc.nbrOfAccounts;
        List <Billing_Account__c> all = pc.allAccounts;
        Test.StopTest();
    }

}