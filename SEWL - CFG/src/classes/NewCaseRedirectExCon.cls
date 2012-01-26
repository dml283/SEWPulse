public class NewCaseRedirectExCon {

    public NewCaseRedirectExCon(ApexPages.StandardController controller) {
        
    }
    
    public PageReference redirectToNewCaseWithNewParameters(){
        PageReference pageRef = new PageReference('/'+Case.SObjectType.getDescribe().getKeyPrefix()+'/e');
        addCurrentPageParamIfNotNull(pageRef, 'retURL');
        addCurrentPageParamIfNotNull(pageRef, 'RecordType');
        addCurrentPageParamIfNotNull(pageRef, 'ent');
        pageRef.getParameters().put('nooverride','1');
        pageRef.getParameters().put('cas5',CaseDefault__c.getInstance().Group_Type__c);
        pageRef.setRedirect(true);
        
        //ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, pageRef.getUrl()));
        
        //return null;
        return pageRef;
    }
    
    private void addCurrentPageParamIfNotNull(PageReference pageRef, String parameter){
        if(Apexpages.currentPage().getParameters().get(parameter)!=null){
            pageRef.getParameters().put(parameter,Apexpages.currentPage().getParameters().get(parameter));
        }
    }
    
    public static testmethod void test_NewCaseRedirectExCon(){ 
        PageReference pageRef = new PageReference('/'+Case.SObjectType.getDescribe().getKeyPrefix()+'/e');
        pageRef.getParameters().put('retURL', 'XXX');
        pageRef.getParameters().put('RecordType', 'YYY');
        pageRef.getParameters().put('ent', 'ZZZ');
        Test.setCurrentPage(pageRef);
        NewCaseRedirectExCon exCon = new NewCaseRedirectExCon(new ApexPages.StandardController(new Case()));
        PageReference testPageRef = exCon.redirectToNewCaseWithNewParameters();
        System.assertEquals(true, testPageRef.getParameters().containsKey('nooverride'));
        System.assertEquals(true, testPageRef.getParameters().containsKey('cas5'));
    }

}