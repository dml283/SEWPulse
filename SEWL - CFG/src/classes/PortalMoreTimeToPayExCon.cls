/*
    Type:       Extension Controller
    Purpose:    Portal page to call manage concession

    Used By:    BillingAccountRefresh
    ---------------------------------------------------------------
    History:
    14-Dec-11 J.Pe (Davanti) created

*/
public class PortalMoreTimeToPayExCon {

    private ApexPages.StandardController stdCon;
    private SuspendRecovery_View_Extension suspendExCon;
    private Billing_Account__c currentBillAcct {
        get{
            return (Billing_Account__c)stdCon.getRecord();
        }
    }
    private User currentPortalUser{
        get{
            if(currentPortalUser==null){
                currentPortalUser = [Select id, ContactId, Contact.Name from User where id = :UserInfo.getUserId()];
            }
            return currentPortalUser;
        }set;
    }
    
    public Case currentCase{
        get{
            return suspendExCon.currentCase ;
        }    
    }
    
    public String isAccHolder{
        get;set;
    }
    
    public boolean isSubmitSuccessful{
        get{
            return false;//concessionExCon.isSubmitSuccessful;
        }
    }
    public void next(){
        /*
        if(isRemoveConcession){
            concessionExCon.deleteConcession();
        }else{
            checkIsAccountHolder();
            if(isAccHolder!=null && Boolean.valueOf(isAccHolder)){
                if(currentCase.Privacy_Statement__c && isValidConcessionCardDetails()){
                    concessionExCon.submitConcession();
                }
            }
        }
        */
    }
    
    public PageReference returnToAccountDetailsPage(){
        PageReference pageRef = Page.PortalAccountDetailPage;
        pageRef.getParameters().put('id',currentBillAcct.id);
        pageRef.setRedirect(true);
        return pageRef;
    }
    

    public PortalMoreTimeToPayExCon(ApexPages.StandardController controller) {
        this.stdCon = controller;
        this.suspendExCon = new SuspendRecovery_View_Extension(new ApexPages.StandardController(new Case()));
        currentCase.Billing_Account__c = currentBillAcct.Id;
        currentCase.Billing_Account__r = currentBillAcct;
        currentCase.AccountId = currentBillAcct.Customer__c;
        currentCase.Account = currentBillAcct.Customer__r;
        currentCase.ContactId = currentPortalUser.ContactId;
        currentCase.Contact = currentPortalUser.Contact;
    }
        
    public static testmethod void test_PortalMoreTimeToPayExCon(){
        Account acc = new Account(name='test parent');
        insert acc;
        Billing_Account__c ba = new Billing_Account__c(name='test', customer__c=acc.Id, HiAF_Account_Number__c='1234');
        insert ba;
        
        PortalMoreTimeToPayExCon excon = new PortalMoreTimeToPayExCon(new ApexPages.StandardController(ba));
        /*
        excon.next();
        excon.isAccHolder = 'false';
        excon.next();
        excon.isAccHolder = 'true';
        excon.next();
        excon.next();
        excon.currentCase.Privacy_Statement__c = true;
        excon.next();
        excon.currentCase.Concession_Card_Type__c = 'Test';
        excon.currentCase.Concession_Card_Number__c = 'Test';
        excon.currentCase.Concession_Card_Firstname__c = 'Test';
        excon.currentCase.Concession_Card_Lastname__c = 'Test';
        excon.next();
        */
        excon.returnToAccountDetailsPage();
        
        /*
        ba.Valid_Concession__c = true;
        update ba;
        excon = new PortalMoreTimeToPayExCon(new ApexPages.StandardController(ba));
        excon.next();
        */
    }
}