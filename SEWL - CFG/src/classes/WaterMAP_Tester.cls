@isTest
private class WaterMAP_Tester {

    static testMethod void WaterMAP_Triggers_Tester() {
        // create account
        Account a = new Account(name='ABC');
        insert a;

        // create contacts
        Contact c1 = new Contact(LastName = '1', AccountId = a.id);
        Contact c2 = new Contact(LastName = '2', AccountId = a.id);
        insert c1;
        insert c2;

        // create property
        Property__c p = new Property__c();
        p.Universal_Id_c__c = 'test';
        insert p;

        // create billing account
        Billing_Account__c ba = new Billing_Account__c();
        ba.Customer__c = a.id;
        ba.Property__c = p.id;
        insert ba;

        // create watermap
        WaterMap__c wmap = new WaterMap__c();
        wmap.Customer__c = a.id;
        wmap.Billing_Account__c = ba.id;
        wmap.Primary_Contact__c = c1.id;
        wmap.Secondary_Contact__c = c2.id;
        wmap.Site_Manager__c = c1.id;
        Test.StartTest();
        insert wmap;

        // create the submission
        WaterMAP_Submission__c wmsub = new WaterMAP_Submission__c();
        wmsub.Watermap__c = wmap.id;
        insert wmsub;

        List <WaterMAP_Submission__c> wmsubs = new List <WaterMAP_Submission__c>();

        Test.StopTest();

        // customer on the submission equals the overall customer
        system.assertEquals([select customer__c from WaterMAP_Submission__c where id=:wmsub.id][0].customer__c, a.id);

        wmsubs = [select id from WaterMAP_Submission__c where customer__c = :a.id];

        // check that the primary consolidated acct record is created
        system.assertEquals([select billing_account__c from WaterMAP_Consolidated_Accounts__c where WaterMAP__c = :wmap.id and Primary__c = true][0].billing_account__c, ba.id);

        // check that the bacct is updated with the new watermap
        system.assertEquals([select WaterMap__c from Billing_Account__c where Id = :ba.id][0].WaterMap__c, wmap.id);

        // 3 contact roles are created
        system.assertEquals([select id from AccountContactRole where AccountId = :a.id].size(), 3);

        // create new billing account
        Billing_Account__c ba2 = new Billing_Account__c();
        ba2.Customer__c = a.id;
        ba2.Property__c = p.id;
        insert ba2;

        // delete all the subs
        delete wmsubs;

        // update the wmap
        wmap.Billing_Account__c = ba2.id;
        wmap.Secondary_Contact__c = null;
        wmap.Site_Manager__c = null;
        wmap.Status__c = 'Active';
        update wmap;

        // check that the primary consolidated acct record is updated
        system.assertEquals([select billing_account__c from WaterMAP_Consolidated_Accounts__c where WaterMAP__c = :wmap.id and Primary__c = true][0].billing_account__c, ba2.id);
        // check that the old bacct's wmap is not cleared
        system.assertEquals([select WaterMap__c from Billing_Account__c where Id = :ba.id][0].WaterMap__c, wmap.id);
        // check that the new bacct's wmap is set
        system.assertEquals([select WaterMap__c from Billing_Account__c where Id = :ba2.id][0].WaterMap__c, wmap.id);
        // 1 contact role remains
        system.assertEquals([select id from AccountContactRole where AccountId = :a.id].size(), 1);
        // 1 Not Started submission
        system.assertEquals([select id from WaterMap_Submission__c where WaterMAP__c = :wmap.id and Status__c = 'Not Started'].size(), 1);

        wmsub = [select id from WaterMap_Submission__c where WaterMAP__c = :wmap.id and Status__c = 'Not Started'][0];

        // complete the review
        wmsub.Status__c = 'Review Completed';
        update wmsub;

        system.assertEquals([select id from WaterMap_Submission__c where WaterMAP__c = :wmap.id and Status__c = 'Not Started'].size(), 1);

        // inactivate the watermap
        wmap.Status__c = 'Inactive';
        update wmap;
        system.assertEquals([select id from WaterMap_Submission__c where WaterMAP__c = :wmap.id and Status__c = 'Cancelled'].size(), 1);

    }
}