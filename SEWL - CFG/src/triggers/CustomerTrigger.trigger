trigger CustomerTrigger on Account (after insert, after update) {
    /**************************************************************************/
    /*  Description:
    /*      (1) Updates related Billing Accounts' Address

    /*  Change History:
    /*      L.Tan     9-Aug-2011     Created
    /**************************************************************************/

    if (!SystemSettings__c.getInstance().Disable_Triggers__c) {
    
        Map<Id, Account> oldAccs = new Map<Id, Account>();          
    
        if (trigger.isAfter) {
            if (trigger.isUpdate) {
                oldAccs = new Map<Id, Account>(Trigger.old);
                
                Map<Id, Account> billingAddrChanges = new Map<Id, Account>(); 
                Map<Id, Account> shippingAddrChanges = new Map<Id, Account>(); 
                Map<Id, Account> billingNameChanges = new Map<Id, Account>();        
                
                for (Account acc: trigger.new) {                
                    if (acc.BillingStreet != oldAccs.get(acc.id).BillingStreet || 
                        acc.BillingCity != oldAccs.get(acc.id).BillingCity ||
                        acc.BillingState != oldAccs.get(acc.id).BillingState ||
                        acc.BillingPostalCode != oldAccs.get(acc.id).BillingPostalCode ||
                        acc.BillingCountry != oldAccs.get(acc.id).BillingCountry ||
                        acc.Billing_Address_DPID__c != oldAccs.get(acc.id).Billing_Address_DPID__c 
                    ) {
                        // store accounts where billing addr have changed
                        billingAddrChanges.put(acc.id, acc);
                                    
                    }               
                    
                    if (acc.ShippingStreet != oldAccs.get(acc.id).ShippingStreet || 
                        acc.ShippingCity != oldAccs.get(acc.id).ShippingCity ||
                        acc.ShippingState != oldAccs.get(acc.id).ShippingState ||
                        acc.ShippingPostalCode != oldAccs.get(acc.id).ShippingPostalCode ||
                        acc.ShippingCountry != oldAccs.get(acc.id).ShippingCountry ||
                        acc.Primary_Address_DPID__c != oldAccs.get(acc.id).Primary_Address_DPID__c 
                    ) {
                        // store accounts where shipping addr have changed
                        shippingAddrChanges.put(acc.id, acc);
                    }               
                    
                    if (acc.Title__c != oldAccs.get(acc.id).Title__c ||	
                    acc.Account_Name__c != oldAccs.get(acc.id).Account_Name__c ||
                    acc.Initials__c != oldAccs.get(acc.id).Initials__c
                    ) {
                    	// store accounts where name details have changed
                    	billingNameChanges.put(acc.id, acc);
                    }
                }
                
                // udpate Billing Accounts where Same As Customer Mailing
                if (billingAddrChanges.size()>0) 
                    BillingAccountUtil.UpdateBAcctAddress(billingAddrChanges, 'Customer Mailing');
    
                // udpate Billing Accounts where Same As Customer Primary
                if (shippingAddrChanges.size()>0) 
                    BillingAccountUtil.UpdateBAcctAddress(shippingAddrChanges, 'Customer Primary');
                
                // update Billing Accounts where Same As Customer Name is checked    
                if (billingNameChanges.size()>0) 
                    BillingAccountUtil.UpdateBAcctName(billingNameChanges);
                
        	}
        } 
    }
}