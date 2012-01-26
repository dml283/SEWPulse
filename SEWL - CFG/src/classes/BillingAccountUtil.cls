/*
    Type:       Utility Class
    Purpose:    (1) Update Billing Accounts' address with Customer (or Parent Customer) 
                Mailing Address or Customer Primary Address
                (2) Set eBilling Method based on presence of IC Customer Classification 
                
    Used By:    CustomerTrigger & CustomerClassificationTrigger
    ---------------------------------------------------------------
    History:
    
    09-Aug-2011 L.Tan (Coretec Solutions)   Created
    09-Sep-2011 D.Enojas (Salesforce)       Added method to handle Customer to BA name updates
    28-Nov-2011	M.Watson (Salesforce)		Added method to handed eBill field update for IC class (BPAY View)
*/
public with sharing class BillingAccountUtil {

    public static void UpdateBAcctAddress (Map<id,Account> accMap, String sameAs){
        
        List<Billing_Account__c> billingAccsToUpdate = new List<Billing_Account__c>();
        
        // get child billing accounts and grandchild billing accounts where Bill_To_Parent is TRUE 
        List<Billing_Account__c> billingAccs = [Select Customer__c, Customer__r.ParentId, Bill_To_Parent__c, Street_Address__c, State__c, Postal_Code__c, DPID__c, Country__c, City__c 
                                            From Billing_Account__c 
                                            where ((Customer__c in :accMap.keySet() and Bill_To_Parent__c = FALSE) or (Customer__r.ParentId in :accMap.keySet() and Bill_To_Parent__c=TRUE))
                                            and Billing_Address_Same_As__c = :sameAs];
                
        if (sameAs == 'Customer Mailing') {
            // update with account billing address
            for (Billing_Account__c ba: billingAccs) {
                if (ba.Bill_To_Parent__c) {
                    ba.Street_Address__c = accMap.get(ba.Customer__r.ParentId).BillingStreet;
                    ba.City__c = accMap.get(ba.Customer__r.ParentId).BillingCity;
                    ba.State__c = accMap.get(ba.Customer__r.ParentId).BillingState;
                    ba.Postal_Code__c = accMap.get(ba.Customer__r.ParentId).BillingPostalCode;
                    ba.Country__c = accMap.get(ba.Customer__r.ParentId).BillingCountry;
                    ba.DPID__c = accMap.get(ba.Customer__r.ParentId).Billing_Address_DPID__c;
                    billingAccsToUpdate.add(ba);                                        
                } else {
                    ba.Street_Address__c = accMap.get(ba.Customer__c).BillingStreet;
                    ba.City__c = accMap.get(ba.Customer__c).BillingCity;
                    ba.State__c = accMap.get(ba.Customer__c).BillingState;
                    ba.Postal_Code__c = accMap.get(ba.Customer__c).BillingPostalCode;
                    ba.Country__c = accMap.get(ba.Customer__c).BillingCountry;
                    ba.DPID__c = accMap.get(ba.Customer__c).Billing_Address_DPID__c;
                    billingAccsToUpdate.add(ba);                    
                }
            }           
        } else if (sameAs == 'Customer Primary'){
            // update with account shipping address
            for (Billing_Account__c ba: billingAccs) {
                if (ba.Bill_To_Parent__c) {
                    ba.Street_Address__c = accMap.get(ba.Customer__r.ParentId).ShippingStreet;
                    ba.City__c = accMap.get(ba.Customer__r.ParentId).ShippingCity;
                    ba.State__c = accMap.get(ba.Customer__r.ParentId).ShippingState;
                    ba.Postal_Code__c = accMap.get(ba.Customer__r.ParentId).ShippingPostalCode;
                    ba.Country__c = accMap.get(ba.Customer__r.ParentId).ShippingCountry;
                    ba.DPID__c = accMap.get(ba.Customer__r.ParentId).Primary_Address_DPID__c;               
                    billingAccsToUpdate.add(ba);                                        
                } else {
                    ba.Street_Address__c = accMap.get(ba.Customer__c).ShippingStreet;
                    ba.City__c = accMap.get(ba.Customer__c).ShippingCity;
                    ba.State__c = accMap.get(ba.Customer__c).ShippingState;
                    ba.Postal_Code__c = accMap.get(ba.Customer__c).ShippingPostalCode;
                    ba.Country__c = accMap.get(ba.Customer__c).ShippingCountry;
                    ba.DPID__c = accMap.get(ba.Customer__c).Primary_Address_DPID__c;                
                    billingAccsToUpdate.add(ba);                    
                }
            }           
        }
        update (billingAccsToUpdate);       
    }
    
    public static void UpdateBAcctName (Map<Id, Account> acctnameMap)
    {
        List<Billing_Account__c> BAsToUpdate = new List<Billing_Account__c>();
        
        List<Billing_Account__c> BAList = [Select Title__c, Account_Name__c, Initials__c, Customer__c 
                                            From Billing_Account__c 
                                            where (Customer__c IN:acctnameMap.keySet() and Same_Name_As_Customer__c = true)];
        
        for(Billing_Account__c BAcct : BAList){
            BAcct.Title__c = acctnameMap.get(BAcct.Customer__c).Title__c;
            BAcct.Account_Name__c = acctnameMap.get(BAcct.Customer__c).Account_Name__c;
            BAcct.Initials__c = acctnameMap.get(BAcct.Customer__c).Initials__c;
            BAsToUpdate.add(BAcct);
        }
        
        update (BAsToUpdate);
    }

	// Takes all IC customer classes; sets eBill preference to "BPay View" (Active) or "Mail" (Inactive)
    public static void UpdateBAcctEBillMethod (List<Customer_Classification__c> ICs, String flagInd)
    {
        Set<Id> bAccIds = new Set<Id>();
        List<Billing_Account__c> BAsToUpdate = new List<Billing_Account__c>();
      
        for (Customer_Classification__c c : ICs){
            bAccIds.add(c.Billing_Account__c);
        }     
        
        List<Billing_Account__c> BAList = [Select eBill_Method__c 
                                            From Billing_Account__c 
                                            where (Id IN :bAccIds)];
        
        if(flagInd == 'Active') {
	        for(Billing_Account__c BAcct : BAList){
	            BAcct.eBill_Method__c = 'BPAY View';
	            BAsToUpdate.add(BAcct);
	        }         	
        }
        if(flagInd == 'Inactive') {
	        for(Billing_Account__c BAcct : BAList){
	        	if(BAcct.eBill_Method__c == 'BPAY View') {
		            BAcct.eBill_Method__c = 'Mail';
		            BAsToUpdate.add(BAcct);	        		
	        	}
	        }          	
        }
        update (BAsToUpdate);
    }
    
    static testMethod void testUpdateBAcctAddress() {
        test.startTest();
        
        Account parentAcc = new Account(name='test parent');
        insert parentAcc;
        Account acc = new Account(name='test account', parentid=parentAcc.id);
        insert acc;
        
        Billing_Account__c baMailing = new Billing_Account__c(name='test', customer__c=parentAcc.id,
                                            Billing_Address_Same_As__c='Customer Mailing'
                                            );
        insert baMailing;       
        Billing_Account__c baPrimary = new Billing_Account__c(name='test', customer__c=parentAcc.id,
                                            Billing_Address_Same_As__c='Customer Primary'
                                            );
        insert baPrimary;       
        Billing_Account__c baBill2ParMailing = new Billing_Account__c(
                                            name='test', customer__c=acc.id,
                                            Bill_To_Parent__c=TRUE, Billing_Address_Same_As__c='Customer Mailing'
                                            );
        insert baBill2ParMailing;       
        Billing_Account__c baBill2ParPrimary = new Billing_Account__c(
                                            name='test', customer__c=acc.id,
                                            Bill_To_Parent__c=TRUE, Billing_Address_Same_As__c='Customer Primary'
                                            );
        insert baBill2ParPrimary;       
        
        Billing_Account__c baName = new Billing_Account__c(name='testBAName', customer__c=parentAcc.id,
                                            Same_Name_As_Customer__c=true
                                            );
        insert baName;                                    
                                            
        
        // update
        parentAcc.BillingStreet = 'test';
        parentAcc.ShippingStreet = 'test';
        parentAcc.Title__c = 'Title Test';
        parentAcc.Account_Name__c = 'Name Test';
        parentAcc.Initials__c = 'IT';      
        update parentAcc;       
        
        system.assertEquals('test', [select Street_Address__c from Billing_Account__c where id=:baMailing.id].Street_Address__c);
        system.assertEquals('test', [select Street_Address__c from Billing_Account__c where id=:baBill2ParMailing.id].Street_Address__c);
        system.assertEquals('test', [select Street_Address__c from Billing_Account__c where id=:baPrimary.id].Street_Address__c);
        system.assertEquals('test', [select Street_Address__c from Billing_Account__c where id=:baBill2ParPrimary.id].Street_Address__c);
        system.assertEquals('Title Test', [select Title__c from Billing_Account__c where id=:baName.id].Title__c);
        system.assertEquals('Name Test', [select Account_Name__c from Billing_Account__c where id=:baName.id].Account_Name__c);
        system.assertEquals('IT', [select Initials__c from Billing_Account__c where id=:baName.id].Initials__c);
        test.stopTest();  
    }
    
    // test method for updating eBill preference based on 'IC' classification
    static testMethod void testUpdateBAcctEBillMethod() {
    	test.startTest();

        Account acc = new Account(name='test account');
        insert acc;
        
        Billing_Account__c bill= new Billing_Account__c(name='test', customer__c=acc.id,
                                            eBill_Method__c = null);
        insert bill;
        Classification_Code__c ICcode;
        
        try {
	        ICcode = [select Id, Name from Classification_Code__c where Name = 'IC' LIMIT 1];
        } catch (QueryException e) {
        	ICcode = new Classification_Code__c();
        	ICCode.Name = 'IC';
        	ICCode.Is_Active__c = true;
        	ICCode.Short_Description__c = 'Foo';
	        insert ICCode;
        }
            	
    	Customer_Classification__c testIC = new Customer_Classification__c(Billing_Account__c=bill.id, Customer__c=acc.id, Classification__c=ICcode.id, is_Active__c = true);
    	insert testIC;
    	
    	system.assertEquals('BPAY View', [Select eBill_Method__c from Billing_Account__c where id=:bill.id].eBill_Method__c);
    	
    	testIC.Is_Active__c = false;
    	update testIC;
    	
    	system.assertEquals('Mail', [Select eBill_Method__c from Billing_Account__c where id=:bill.id].eBill_Method__c);
    	
    	test.stopTest();
    }

}