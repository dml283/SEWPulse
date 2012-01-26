trigger CustomerClassificationTrigger on Customer_Classification__c (after insert, after update) {
    /**************************************************************************/
    /*  Description:
    /*      (1) For all customers with IC class, set Bill Receipt preference
    /*		to 'BPAY'
	/*
    /*  Change History:
    /*      M.Watson    28-11-2011     Created
    /**************************************************************************/

    if (!SystemSettings__c.getInstance().Disable_Triggers__c) {
   
        if(trigger.isAfter && (trigger.isInsert || trigger.isUpdate)) {
        	
        	List <Customer_Classification__c> ActiveICs = new List<Customer_Classification__c>();
         	List <Customer_Classification__c> InactiveICs = new List<Customer_Classification__c>();
        	        	
        	for(Customer_Classification__c classEntry : trigger.new) {
        		// check for IC record
        		if (classEntry.Class_Code__c == 'IC') {       		
        			// check for active/inactive and add to appropriate list
        			if(classEntry.Is_Active__c) {
        				ActiveICs.add(classEntry);
        			}
        			else {
        				InactiveICs.add(classEntry);
        			} 		
        		}
        	}
        if (!ActiveICs.isEmpty())
	        BillingAccountUtil.UpdateBAcctEBillMethod(ActiveICs, 'Active');
		if (!InactiveICs.isEmpty())
	        BillingAccountUtil.UpdateBAcctEBillMethod(InactiveICs, 'Inactive');        
        }

	}

}