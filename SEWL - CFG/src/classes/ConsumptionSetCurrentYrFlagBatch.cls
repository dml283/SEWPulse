global class ConsumptionSetCurrentYrFlagBatch implements Database.Batchable<sObject> {

/*
    Type:       Batch class
    Purpose:    Updates the current year flag on consumption based
                the Reports__c.year__c custom setting

    Used By:
    ---------------------------------------------------------------
    History:

    08-Aug-2011 D.Thong (Salesforce)    Created

*/

    public String year;

    global database.querylocator start(Database.BatchableContext BC) {

        if (year == null)
            if (SystemSettings__c.getInstance() != null)
                year = SystemSettings__c.getInstance().financial_year__c; // current fin year
            else
                year = '2010/11';

        String query = 'Select c.Is_Current_Year__c, c.Financial_Year__c From Consumption_and_Charge__c c ';
        query +=        'where (financial_year__c = \'' + year + '\' and is_current_year__c = false) or ';
        query +=        '(financial_year__c != \'' + year + '\' and is_current_year__c = true)';

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){
        List <Consumption_and_Charge__c> cons = new List<Consumption_and_Charge__c>();
        for (sObject s : scope) {
            Consumption_and_Charge__c c = (Consumption_and_Charge__c ) s;
            if (c.financial_year__c != year && c.is_current_year__c)
                // flag set but should not be
                c.is_current_year__c = false;
            else
                c.is_current_year__c = true;

            cons.add(c);
        }

        update cons;
    }

    global void finish(Database.BatchableContext BC){

    }

    private static testmethod void TestMe() {
		SystemSettings__c rep;

		try {
	        rep = [select id, financial_year__c from systemSettings__c];
		} catch (Exception e) {
						
		}	

        if (rep == null) {
            rep = new SystemSettings__c ();
            insert rep;
        }
        System.debug(rep);

        rep.financial_year__c = '2010/11';
        update rep;

        // create account
        Account a = new Account(name='ABC');
        insert a;

        // create property
        Property__c p = new Property__c();
        p.Universal_Id_c__c = 'test';
        insert p;

        // create billing account
        Billing_Account__c ba = new Billing_Account__c();
        ba.Customer__c = a.id;
        ba.Property__c = p.id;
        insert ba;

        List <Consumption_and_Charge__c> cons = new List<Consumption_and_Charge__c>();
        for (integer i=0; i<100; i++) {
            Consumption_and_Charge__c  c1 = new Consumption_and_Charge__c();
            c1.Billing_Account__c = ba.id;
            c1.Financial_Year__c = '2010/11';
            c1.Is_Current_Year__c = false;
            cons.add(c1);
            Consumption_and_Charge__c  c2 = new Consumption_and_Charge__c();
            c2.Billing_Account__c = ba.id;
            c2.Financial_Year__c = '2009/10';
            c2.Is_Current_Year__c = true;
            cons.add(c2);
        }

        insert cons;

        test.starttest();
        database.executeBatch(new ConsumptionSetCurrentYrFlagBatch());
        test.stoptest();

        system.assertequals(database.countquery('SELECT count() FROM Consumption_and_Charge__c WHERE billing_account__c = \''+ ba.id+'\''), 200);


    }

}