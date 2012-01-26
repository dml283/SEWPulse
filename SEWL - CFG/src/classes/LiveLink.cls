public with sharing class LiveLink {

/*
    Type:       Utility Class
    Purpose:    DefaultFieldsFromBAcct ()
                - default the property and customer from bacct

    Used By:    LiveLinkTrigger
    ---------------------------------------------------------------
    History:
        27-Sep-2011 - D.Thong (SFDC)    Created
*/

    // Default the customer from the billing account
    public static void DefaultFieldsFromBAcct(List<LiveLink__c> lls) {
        Set<Id> bAcctIds = new Set<Id>();
        Map<Id, Billing_Account__c> bAcctIdMap = new Map<Id, Billing_Account__c>();

        // get a set of unique billing account its from the Livelink records
        for (LiveLink__c ll : lls) {
            if (ll.Billing_Account__c != null)
                bAcctIds.add(ll.Billing_Account__c);
        }

        // generate a map of bacct id to customer id
        for (Billing_Account__c ba : [select customer__c, property__c from billing_account__c where id in :bAcctIds]) {
            bAcctIdMap.put(ba.id, ba);
        }

        // update the case to the new customer
        for (LiveLink__c ll : lls) {
            if (ll.Billing_Account__c != null) {
                if (ll.Customer__c == null)
                    ll.Customer__c = bAcctIdMap.get(ll.Billing_Account__c).customer__c;
                if (ll.Property__c == null)
                    ll.Property__c = bAcctIdMap.get(ll.Billing_Account__c).Property__c;
            }
        }
    }

    private static TestMethod void TestMe() {
        Profile profile = [select id from profile where name='SEW CSO (Customer Service Officer)'];
       User u = new User(alias = 'fgjdf', email='dfjdfh@dfhxfgh.com',
          emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
          localesidkey='en_US', profileid = profile.Id,
          timezonesidkey='America/Los_Angeles', username='djgf@hjgfhj.com');
       insert u;

       System.runAs(u) {

            Account a = SObjectCreator.createAccountNonResidentialCompany();
            insert a;
            Property__c p = SObjectCreator.createProperty();
            insert p;

            // create billing account
            Billing_Account__c ba = new Billing_Account__c();
            ba.Customer__c = a.id;
            ba.Property__c = p.id;
            insert ba;

            // create the livelink object
            Livelink__c ll = new LiveLink__c(name='x', billing_account__c=ba.id);
            insert ll;

            system.assert([select customer__c from livelink__c where id = :ll.id].customer__c == a.id);
            system.assert([select property__c from livelink__c where id = :ll.id].property__c == p.id);

       }

    }

}