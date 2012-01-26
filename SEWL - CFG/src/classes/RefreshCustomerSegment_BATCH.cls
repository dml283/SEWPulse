/*
    Type:       Batch Class
    Purpose:    (1) Populates the segment usage quartile for customers
                (2) Populates the age bracket for residential customers
                
    Used By:    
    ---------------------------------------------------------------
    History:
    
    13-12-2011  J.Pe (Davanti)       Created
*/

global class RefreshCustomerSegment_BATCH implements Database.Batchable<sObject>{

    public List<Account> testCustomers {get;set;}
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        List<Question__c> questionList = [Select id, API_Field__c from Question__c where API_Field__c <> null];
        Set<String> questionAPIFieldNames = new Set<String>();
        for(Question__c qRec: questionList ){
            questionAPIFieldNames.add(qRec.API_Field__c );
        }
        questionAPIFieldNames.add('Name');
        questionAPIFieldNames.add('RecordType.DeveloperName');
        questionAPIFieldNames.add('Segment_Usage_Quartile__c');
        questionAPIFieldNames.add('Segment_Usage_Last_Updated__c');
        questionAPIFieldNames.add('Segment_Profile_Last_Updated__c');
        questionAPIFieldNames.add('Segment_Profile_Next_Review_Date__c');
        questionAPIFieldNames.add('Account.Q3_What_is_your_age__c');
        questionAPIFieldNames.add('Account.Segment__c');
        
        String apiFieldNameQueryPart = '';
        for(String apiFieldName: questionAPIFieldNames){
            apiFieldNameQueryPart += ', '+apiFieldName;
        }
        String query = 'Select id';
        if(!questionAPIFieldNames.isEmpty()){
            query += apiFieldNameQueryPart;
        }
        query += ' from Account';
        if (testCustomers != null && !testCustomers.isEmpty()){
            query +=' where id in (';
            for(Account testRec: testCustomers){
                query += '\''+testRec.id+'\',';
            }
            query = query.substring(0,query.length()-1);
            query +=') ';
        }
        system.debug('### The Query is: ' + query);
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> customers) {
        Map<Id, Account> custsUpdatedMap = new Map<Id, Account>();
        SegmentationAllocator alloc = new SegmentationAllocator();
        custsUpdatedMap.putAll(SegmentUtil.PopulateUsageQuartiles(customers));
        custsUpdatedMap.putAll(SegmentUtil.PopulateAgeBrackets(customers));
        custsUpdatedMap.putAll(alloc.Allocate(customers));
        update custsUpdatedMap.values();
    }
    
    global void finish(Database.BatchableContext BC) {     
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
        mail.setSubject('Refresh Customer Segment Batch - Processing - ' + a.Status);
        mail.setPlainTextBody ('The batch Apex job processed ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        */
        
    }
}