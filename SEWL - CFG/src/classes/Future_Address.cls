public with sharing class Future_Address {

/*
    Type:       Utility Class
    Purpose:    ProcessFutureAddress () - updates future address on customer

    Used By:    Future_Address.trigger
    ---------------------------------------------------------------
    History:
        22-Sep-2011 - D.Thong (SFDC)    Created
*/

    public static void ProcessFutureAddress(List<Id> futureAddressIds) {
        // 1. select future addresses sorted by account and applicable date
        // 2. update the customer's address
        // 3. Set done flag = 'Y' and process_flag = 'N'

        Map<Id, Account> accounts = new Map<Id, Account>();
        Map<Id, Future_Address__c> faMap = new Map<Id, Future_Address__c>();

        for (Future_Address__c fa : [select id, account__c, street_address__c, city__c, state__c, postal_code__c, country__c, dpid__c, process__c, done__c
                                        from Future_Address__c
                                        where id in :futureAddressIds
                                        and Process__c = true
                                        order by account__c, applicable_date__c]) {
            Account acct = new Account(id=fa.account__c,
                                        BillingStreet=fa.street_address__c,
                                        BillingCity=fa.City__c,
                                        BillingState=fa.State__c,
                                        BillingPostalCode=fa.Postal_Code__c,
                                        BillingCountry=fa.Country__c,
                                        Billing_Address_DPID__c=fa.DPID__c);

            accounts.put(fa.id, acct);

            fa.Done__c = true;
            fa.Process__c = false;

            faMap.put(fa.id, fa);
        }

        Savepoint sp = Database.setSavepoint();

        try {
            if (!accounts.isEmpty()) {
                update accounts.values();
            }

            if (!faMap.isEmpty()) {
                update faMap.values();
            }

        } catch (Exception e) {
            Database.rollback(sp);
            throw(e);
        }

    }

    private static TestMethod void TestMe() {
        Profile p = [select id from profile where name='SEW CSO (Customer Service Officer)'];
                        User u = new User(alias = 'fgjdf', email='dfjdfh@dfhxfgh.com',
        emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
        localesidkey='en_US', profileid = p.Id,
        timezonesidkey='America/Los_Angeles', username='djgf@hjgfhj.com');
        insert u;

        System.runAs(u) {
            Account a = new Account(name='ABC');
            insert a;

            Future_Address__c fa = new Future_Address__c(account__c = a.id,
                                                            Street_Address__c = '100 ABC ST',
                                                            City__c = 'ABCVILLE',
                                                            State__c = 'ABC',
                                                            Postal_Code__c = '1234',
                                                            Country__c = 'ABCLAND',
                                                            DPID__c = '12345',
                                                            Applicable_date__c = system.today().addDays(2));
            insert fa;

            fa.Process__c = true;
            update fa;

            a = [select id, BillingStreet, BillingState, BillingPostalCode, BillingCity, Billing_Address_DPID__c, BillingCountry
                            from Account
                            where id = :a.id][0];
            system.assertequals(a.BillingStreet, fa.street_address__c);
            system.assertequals(a.BillingState, fa.State__c);
            system.assertequals(a.BillingPostalCode, fa.Postal_Code__c);
            system.assertequals(a.BillingCity, fa.City__c);
        }
    }
}