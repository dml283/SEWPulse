/*
    Type:       Extension Controller
    Purpose:    Calls TIBCO to refresh the account

    Used By:    BillingAccountRefresh
    ---------------------------------------------------------------
    History:

*/
public class BillingAccountRefreshExCon {

    private ApexPages.StandardController stdcon;
    
    private Billing_Account__c currentBillAcct{
        get{
            return (Billing_Account__c)stdcon.getRecord();
        }
    }

    /* Constructor*/
    public BillingAccountRefreshExCon(ApexPages.StandardController controller) {
        stdcon = controller;
    }
    
    /* Public Methods */
    // method to refresh the account
    public PageReference RefreshBillingAccount(){
        try{
            new WSUtil_BillingAccountRefresh().refreshBillingAccount(currentBillAcct);
            return back();
        }
        catch(Exception e){
            ApexPages.addMessages(e);
            return null;
        }
    }
    
    // goes back to the previous page
    public PageReference Back(){
        return new PageReference('/' + currentBillAcct.Id);
    }
    
     //test method
    public static testmethod void TestBillingAccountRefreshExCon (){

        //create account
        Account ca=new Account();
        ca.Name='test CA';
        ca.Billing_Address_DPID__c='123';
        ca.BillingStreet='1 Collins St';
        ca.BillingCity='Melbourne';
        ca.BillingState='VIC';
        ca.BillingPostalCode='3000';
        ca.BillingCountry='Australia';
        insert ca;

        //insert property
        Property__c prop=new Property__c();
        prop.Name='test property';
        prop.Universal_Id_c__c='101010';
        insert prop;

        //create billing account
        Billing_Account__c ba1=new Billing_Account__c();
        ba1.Name='test BA1';
        ba1.Customer__c=ca.Id;
        ba1.Street_Address__c=ca.BillingStreet;
        ba1.City__c=ca.BillingCity;
        ba1.State__c=ca.BillingState;
        ba1.Country__c=ca.BillingCountry;
        ba1.Property__c=prop.id;
        ba1.HiAf_Account_Number__c = 'Test BA1';
        insert ba1;

        Test.startTest();

        PageReference pageRef = Page.BillingAccountRefresh;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('retURL','/'+ba1.id);
        pageRef.getParameters().put('id','/'+ba1.id);
        ApexPages.StandardController sc = new ApexPages.StandardController(ba1);
        BillingAccountRefreshExCon excon = new BillingAccountRefreshExCon(sc);

        excon.refreshBillingAccount();
        excon.back();
        Test.stopTest();
        
        TibcoBillingAccountRefresh_MessageTypes.ErrorStatus_element ese = new TibcoBillingAccountRefresh_MessageTypes.ErrorStatus_element();
    }

}