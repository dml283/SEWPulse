global class CopyGroupBillingAddressScheduler implements Schedulable{

/*
    Type:       Scheduler Class
    Purpose:    Schedules Billing Address Copy nightly job

    Used By:    
    ---------------------------------------------------------------
    History:


*/

    global void execute(SchedulableContext SC) {
        List<Billing_Account__c> groupBillingAccounts = [   SELECT    Id
                                                                    , Street_Address__c
                                                                    , City__c
                                                                    , State__c
                                                                    , Country__c
                                                                    , Postal_Code__c
                                                                    , Attention__c
                                                                    , Care_Of__c
                                                                    , Billing_Address_Same_As__c
                                                                    , Update_Sub_Account_Addresses__c
                                                                    , DPID__c
                                                            FROM    Billing_Account__c
                                                            WHERE   Update_Sub_Account_Addresses__c = TRUE];

        CopyGroupBillingAddress_BATCH copyGroupBillingAddress = new CopyGroupBillingAddress_BATCH(groupBillingAccounts);
        ID batchProcessId = Database.executeBatch( copyGroupBillingAddress);
    }

    static testmethod void Test() {
        Test.startTest();

        // Schedule the test job
        String jobId = System.schedule('CopyGroupBillingAddressScheduler',
                                '0 0 0 3 9 ? 2050',
                                new CopyGroupBillingAddressScheduler());
        // Get the information from the CronTrigger API object


        CronTrigger ct = [SELECT id, CronExpression, TimesTriggered,
                            NextFireTime
                            FROM CronTrigger WHERE id = :jobId];

        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);

        Test.stopTest();
    }
}