/*
    Type:       Controller Extension
    Purpose:    Controls the mass Billing Account Address Flag Update

    Used By:    AccountMassBAcctAddressFlagUpdate
    ---------------------------------------------------------------
    History:

    09-Aug-2011 J.Pe (Davanti Consulting)    Created

*/
public class AccountMassBAcctAddressFlagUpdateExCon {

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
    public AccountMassBAcctAddressFlagUpdateExCon(ApexPages.StandardController controller) {
        stdCon = controller;
    }

    /* Public Methods */
    public PageReference saveBillingAccounts(){
        try{
            update customer.Billing_Account__r;
        }catch(Exception e){
                ApexPages.addmessages(e);
                        return null;
        }
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'Billing Account address details updated.'));
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

        account = [Select id, Name, (Select id, Name, Billing_Address_Same_As__c, Bill_To_Parent__c from Billing_Account__r) from Account where id = :account.id][0];

        Test.startTest();
        PageReference pageRef = Page.AccountMassBAcctAddressFlagUpdate;
        ApexPages.StandardController sc = new ApexPages.StandardController(account);
        Test.setCurrentPage(pageRef);
        AccountMassBAcctAddressFlagUpdateExCon excon = new AccountMassBAcctAddressFlagUpdateExCon(sc);
        pageRef.getParameters().put('retURL','/'+account.id);
        account.Billing_Account__r[0].Billing_Address_Same_As__c = null;
        account.Billing_Account__r[0].Bill_To_Parent__c = true;
        excon.saveBillingAccounts();
        account.Billing_Account__r[0].Billing_Address_Same_As__c = 'Same as Primary';
        account.Billing_Account__r[0].Bill_To_Parent__c = true;
        excon.saveBillingAccounts();
    }

}