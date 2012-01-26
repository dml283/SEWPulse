trigger PersonTrigger on Contact (before update) {
    /**************************************************************************/
    /*  Description:
    /*      (1) Prevent contacts from having their email address and/or mobile
    /*			removed when they are registered for eBilling against at least
    /*			1 billing account
    /*		
	/*
    /*  Change History:
    /*      M.Watson    29-11-2011     Created
    /**************************************************************************/

    if (!SystemSettings__c.getInstance().Disable_Triggers__c) {
	
        if(trigger.isBefore && trigger.isUpdate) {
        	
        	Map <Id, Contact> oldContacts = new Map<Id, Contact>(trigger.old);
        	Map <Id, Contact> emailAddrRemovals = new Map<Id, Contact>();
        	Map <Id, Contact> mobileNumRemovals = new Map<Id, Contact>();
        	
        	for (Contact c : trigger.new) {
        		if(c.Email == null && oldContacts.get(c.id).Email != null) {
        			// store contacts where Email has been removed
        			emailAddrRemovals.put(c.id, c);
        		}
        		if(c.MobilePhone == null && oldContacts.get(c.id).MobilePhone != null) {
        			// store contacts where Mobile has been removed
        			mobileNumRemovals.put(c.id, c);
        		}
        	}
        	// call the PersonUtil class method to perform the validation
        	PersonUtil.CheckEmaileBills(emailAddrRemovals);
        	PersonUtil.CheckSMSReminders(mobileNumRemovals);
        }    	
    }
}