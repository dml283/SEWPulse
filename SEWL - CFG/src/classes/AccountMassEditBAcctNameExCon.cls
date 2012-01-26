public with sharing class AccountMassEditBAcctNameExCon {

/*
    Type:       Controller Extension
    Purpose:    Performs mass update of billing account names

    Used By:    AccountMassEditBAcctName
    ---------------------------------------------------------------
    History:

    09-Sep-2011 Dthong (SFDC)    Created

*/

    /* Public Properties */
    public Integer numBillingAccts {
        get {
            if (customer != null)
                return customer.Billing_Account__r.size();

            return 0;
        }

    }

    /* Private Properties */
    private Account customer{
        get{
            if(stdCon == null){
                return null;
            }
            return (Account) stdCon.getRecord();
        }
    }
    private ApexPages.StandardController stdCon;


    /* Constructors */
    public AccountMassEditBAcctNameExCon(ApexPages.StandardController controller) {
        stdCon = controller;
    }

    /* Public Methods */
    public PageReference saveBillingAccounts(){
        List<Billing_Account__c> bAccts = customer.Billing_Account__r;

        for (Billing_Account__c b : bAccts) {
            // manages the same name as customer flag
            if (b.Account_Name__c == customer.Account_Name__c &&
                b.Title__c == customer.Title__c &&
                b.Initials__c == customer.Initials__c) {

                b.Same_Name_As_Customer__c = true;
            }
        }

        try{
            update customer.Billing_Account__r;
        }catch(Exception e){
            ApexPages.addmessages(e);
            return null;
        }
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'Billing Account name details updated.'));
        if (!Test.isRunningTest())
        	stdCon.reset();
        return null;
    }


    /* TEST METHODS */
    public static testmethod void TestMe() {
        // create test data
        Account account = new Account();
        account.name = 'foo';
        insert account;

        Contact contact = new Contact();
        contact.LastName = 'Foo';
        contact.AccountId = account.id;
        contact.Title = 'x';
        contact.Phone = 'x';
        contact.Email = 'x@x.com';
        insert contact;

        Property__c prop = new Property__c();
        prop.Universal_Id_c__c = 'sdgfsdgf';
        prop.Name = 'Test Property';
        insert prop;

        Billing_Account__c billAcc = new Billing_Account__c();
        billAcc.Name = 'asetwetwrt';
        billAcc.Customer__c = account.id;
        billAcc.Property__c = prop.id;
        insert billAcc;

        billAcc = new Billing_Account__c();
        billAcc.Name = 'asetwetwrt';
        billAcc.Customer__c = account.id;
        billAcc.Property__c = prop.id;
        insert billAcc;

        account = [Select id, Name, Account_Name__c, Title__c, Initials__c, (Select id, Name,  Billing_Address_Same_As__c, Bill_To_Parent__c, Account_Name__c, Title__c, Initials__c from Billing_Account__r) from Account where id = :account.id][0];

        Test.startTest();
        PageReference pageRef = Page.AccountMassEditBAcctName;
        ApexPages.StandardController sc = new ApexPages.StandardController(account);
        Test.setCurrentPage(pageRef);
        AccountMassEditBAcctNameExCon excon = new AccountMassEditBAcctNameExCon(sc);
        pageRef.getParameters().put('retURL','/'+account.id);
        System.assertEquals(excon.numBillingAccts, 2);
        excon.saveBillingAccounts();

        excon = new AccountMassEditBAcctNameExCon(null);
        System.assertEquals(excon.numBillingAccts, 0);

        Test.stopTest();

    }

}