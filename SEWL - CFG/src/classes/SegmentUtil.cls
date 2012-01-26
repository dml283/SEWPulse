/*
    Type:       Utility Class
    Purpose:    (1) Populates the segment usage quartile for customers
                (2) Populates the age bracket for residential customers
                
    Used By:    CustomerSegmentEntryController
    ---------------------------------------------------------------
    History:
    
    08-12-2011  M.Watson (Salesforce)       Created
*/
public with sharing class SegmentUtil {

    // retrieve Custom Setting values, for use in pattern matching later
    private final static List<Segment_Usage_Quartile__c> segmentQuartileRange= Segment_Usage_Quartile__c.getAll().values();
    private final static List<Segment_Age_Ranges__c> segmentAgeRanges = Segment_Age_Ranges__c.getAll().values();
    private final static Integer MIN_NO_OF_DAYS_FOR_UPDATE = 180;

    public static Map<Id, Account> PopulateUsageQuartiles(List<Account> customers) {
        Map<Id, Account> custsUpdatedMap = new Map<Id, Account>();
        Map<Id, AggregateResult> usageResults = new Map<Id, AggregateResult>();
        Set<Id> tradeWasteCustomerIds = new Set<Id>();

        // aggregate the usage by customer
        for (AggregateResult ur :  [Select customer__c, RecordType.DeveloperName, sum(b.Total_Water_Usage_KL__c) totalUsage, 
                                                    sum(b.Total_Consumption_Days__c) totalDays
                                            From Billing_Account__c b 
                                            where  customer__c in :customers
                                            group by customer__c, RecordType.DeveloperName ]) {
            usageResults.put((Id) ur.get('customer__c'), ur);                                       
        }
        
        // create a set to determine if the customer has any TW accounts
        // A TW customer is where the Role = Other, Status = Active and there exists at least one tariff with TW%
        for(Billing_Account__c b : [select id, customer__c, (select id from services__r 
                                                    where tariff__c like 'TW%'
                                                    LIMIT 1) 
                                    from Billing_Account__c 
                                    where Role__c = 'Other' 
                                    and Status__c = 'Active'
                                    and customer__c in :customers]) {
            tradeWasteCustomerIds.add(b.customer__c);                                   
        }   
        
        for(Account customer : customers) { 
            AggregateResult custUsage = usageResults.get(customer.id);

            if (tradeWasteCustomerIds.contains(customer.id)) {
                // it is a trade waste
                if(customer.Segment_Usage_Quartile__c != '9 - Trade Waste'){
                    customer.Segment_Usage_Quartile__c = '9 - Trade Waste';
                    custsUpdatedMap.put(customer.id, customer);
                }
            } else if(custUsage != null ) {
                // not a trade waste but we do have some usage

                Decimal totalUsage = 0;
                Decimal totalDays = 0;
                Decimal averageUsage = 0;   
                Decimal avgDailyUsage;
                String  usageQuartile;
                String  questionType; 
                
                if(customer.RecordType != null) {
                    if (customer.RecordType.DeveloperName.startsWith('Residential')) {
                        questionType = 'Residential';
                    }
                    else questionType = 'Business';
                }
                
                /* STEP 1 - Calculate Average Daily Usage */
                try {
                    totalUsage = (Decimal) custUsage.get('totalUsage');
                } catch (TypeException e) {}
        
                try {
                    totalDays = (Decimal) custUsage.get('totalDays');
                } catch (TypeException e) {}
                
                // must be > 180 days of usage
                if (totalDays != null && totalDays >= MIN_NO_OF_DAYS_FOR_UPDATE ) {
                    averageUsage = (totalUsage / totaldays).setScale(3);
                
                    avgDailyUsage = averageUsage;                       
    
                    /* STEP 2 - Get the segment quartile */             
                    // prevent divide by 0
                    if (averageUsage > 0) {
                        for (Segment_Usage_Quartile__c q : segmentQuartileRange) {
                            if (questionType == q.Type__c &&
                                    averageUsage >= q.Lower_Bound_KL_day__c &&
                                    averageUsage <= q.Upper_Bound_KL_day__c) {
                                usageQuartile = q.Quartile__c;                                  
                            }
                        }
                    }   
    
                    /* STEP 3 - Populate the segment quartile */
                    if (usageQuartile != null && customer.Segment_Usage_Quartile__c != usageQuartile) {
                        customer.Segment_Usage_Quartile__c = usageQuartile;
                        customer.Segment_Usage_Last_Updated__c = Datetime.now();
                        custsUpdatedMap.put(customer.id, customer);
                    }  
                           
                }  
            }                           
            // if no usage and not populated, then 5 - No Usage
            if (customer.Segment_Usage_Quartile__c == null) {
                customer.Segment_Usage_Quartile__c = '5 - No Usage';
                custsUpdatedMap.put(customer.id, customer);
            }
        }
        return custsUpdatedMap;
    }

    public static Map<Id, Account> PopulateAgeBrackets(List<Account> customers) {
        Map<Id, Account> custsUpdatedMap = new Map<Id, Account>();
        /* STEP 1 - Retrieve primary persons who have birthdates */     
        // Get a map of all accounts (customers) with their FIRST primary contact
        Map<Id, Account> allCustPrimary = new Map<Id, Account>([Select Id, 
                                    (Select Id, Birthdate from Contacts
                                    where Primary_Secondary_Contact__c = 'Primary Contact'
                                    and Birthdate != null
                                    order by createddate desc
                                    limit 1)
                                from Account
                                where Id in :customers]);

        /* STEP 2 - Calculate age & figure appropriate bracket */   
        for(Account customer : customers) { // for each customer
            Account custWithPrimary = allCustPrimary.get(customer.id);
            
            if(custWithPrimary != null && custWithPrimary.Contacts != null
                && !custWithPrimary.Contacts.isEmpty()) {
                    
                Integer daysOld;
                Integer agePerson;
                String  ageRange;           
                
                // calculate the age of the primary contact
                daysOld = custWithPrimary.Contacts[0].Birthdate.daysBetween(System.today());
                agePerson = daysOld / 365;
                
                System.debug('##AGE');
                System.debug(agePerson);
                
                // find appropriate age bracket
                for(Segment_Age_Ranges__c a : segmentAgeRanges) {
                    if(agePerson >= a.Lower_Bound__c && agePerson <= a.Upper_Bound__c) {
                        ageRange = a.Name;
                    }
                }
                
                /* STEP 3 - Populate the age range */
                if (ageRange != null && customer.Q3_What_is_your_age__c != ageRange) {
                    customer.Q3_What_is_your_age__c = ageRange;
                    custsUpdatedMap.put(customer.id, customer);
                }               
            }           
        }
        return custsUpdatedMap;
    }
    
}