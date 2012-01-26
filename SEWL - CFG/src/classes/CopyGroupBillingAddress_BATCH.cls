/*******************************************************************************************
 
 * <Organization>South East Water Limited</Organization>
 * <ClassName>CopyGroupBillingAddress_BATCH</ClassName>
 * <ApiVersion>22.0</ApiVersion>
 * <CreatedBy>Gareth Knight</CreatedBy>
 * <CreatedDate>Thurs, 08/09/2011</CreatedDate>
 
 * <purpose>
    Sync the Billing addresses of Group Customers, use a Batchable
    Interface as datasets can be quite large and could potentially
    error if the standard API is used.
 * </purpose>
    
*******************************************************************************************/

global class CopyGroupBillingAddress_BATCH implements Database.Batchable<sObject>{
    Map<Id, Map<String, String>> parentBillingAccountIdsToAddresses_MAP = new Map<Id, Map<String, String>>();
    
    static final String STREET = 'Street_Address__c';
    static final String CITY = 'City__c';
    static final String STATE = 'State__c';
    static final String COUNTRY = 'Country__c';
    static final String DPID = 'DPID__c';
    static final String POSTCODE = 'Postal_Code__c';
    static final String ATTENTION = 'Attention__c';
    static final String CAREOF = 'Care_Of__c';
    
    List<Billing_Account__c> groupAccsToReset = new List<Billing_Account__c>();
    
    String query = 'SELECT Id, Street_Address__c, City__c, State__c, Country__c, DPID__c, Postal_Code__c, Group_Billing_Account__c  ' +
                        'FROM Billing_Account__c ' +
                        'WHERE Group_Billing_Account__c IN (';
                                    
        
    global CopyGroupBillingAddress_BATCH(List<Billing_Account__c> groupBillingAccounts){
    	System.debug('###foo');
        groupAccsToReset.addAll(groupBillingAccounts);
        List<Id> groupAccIds_LIST = new List<Id>();
        for (Billing_Account__c a : groupBillingAccounts){
            Map<String, String> temp_MAP = new Map<String, String>();
            temp_MAP.put(STREET, a.Street_Address__c);
            temp_MAP.put(CITY, a.City__c);
            temp_MAP.put(STATE, a.State__c);
            temp_MAP.put(COUNTRY, a.Country__c);
            temp_MAP.put(DPID, a.DPID__c);
            temp_MAP.put(POSTCODE, a.Postal_Code__c);
            temp_MAP.put(ATTENTION, a.Attention__c);
            temp_MAP.put(CAREOF, a.Care_Of__c);
            parentBillingAccountIdsToAddresses_MAP.put(a.Id, temp_MAP);
        }
        groupAccIds_LIST.addAll(parentBillingAccountIdsToAddresses_MAP.keySet());
        if (groupBillingAccounts.size() > 0) {
	        for (Integer i = 0; i < groupAccIds_LIST.size(); i++ ){
	            query = query + '\'' + String.valueof(groupAccIds_LIST[i]) + '\'';
	            if (i < (groupAccIds_LIST.size()-1)){
	                query = query + ', ';
	            } else {
	                query = query + ')';
	            }
	        }
        } else {
        	query += 'null) and id=null';	
        }
        system.debug('### The Query is: ' + query);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        system.debug('### The Query is: ' + query);
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> billingAccounts ) {
        for (sObject s : billingAccounts){
            Billing_Account__c a = (Billing_Account__c)s;
            Map<String, String> address = parentBillingAccountIdsToAddresses_MAP.get(a.Group_Billing_Account__c);
            a.Street_Address__c = address.get(STREET);
            a.City__c = address.get(CITY);
            a.State__c = address.get(STATE);
            a.Country__c = address.get(COUNTRY);
            a.DPID__c = address.get(DPID);
            a.Postal_Code__c = address.get(POSTCODE);
            a.Attention__c = address.get(ATTENTION);
            a.Care_Of__c = address.get(CAREOF);
        }
        
        update billingAccounts;
        
    }
    
    global void finish(Database.BatchableContext BC) {
        
        //Reset the Update Sub Account Addresses Flag for the Parent Accounts
        for (Billing_Account__c a : groupAccsToReset){
            a.Update_Sub_Account_Addresses__c = FALSE;
        }
        update groupAccsToReset;
        
        /*
        // Get the ID of the AsyncApexJob representing this batch job from Database.BatchableContext.  
        // Query the AsyncApexJob object to retrieve the current job's information.  
        AsyncApexJob a = [Select Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
                        from AsyncApexJob
                        where Id = :BC.getJobId()];
        
        // Send an email to the Apex job's submitter notifying of job completion.  
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {a.CreatedBy.Email};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Copy Group Billing Account Address Batch - Processing - ' + a.Status);
        mail.setPlainTextBody ('The batch Apex job processed ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        */
        
    }

}