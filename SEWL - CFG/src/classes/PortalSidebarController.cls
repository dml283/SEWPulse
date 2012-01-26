public with sharing class PortalSidebarController {

/*
    Type:       Component Controller
    Purpose:    Controller to display the sidebar of the portal

    Used By:    PortalSidebar Component
    ---------------------------------------------------------------
    History:

    13-Dec-2011 J.Pe (Davanti)    Created

*/
    /* PRIVATE PROPERTIES */
    private PortalMyAccountHomePageController portalMyAccountHPCon{
        get{
            if(portalMyAccountHPCon==null){
                portalMyAccountHPCon = new PortalMyAccountHomePageController();
            }
            return portalMyAccountHPCon;
        }set;
    }

    /* PUBLIC PROPERTIES */
    public String groupName{ get; set; }
    public String currentDevName{ get; set; }
    public String currentAccRecordType{ get; set; }
    public Id selectedBillAcctId{get;set;}
    public String currentUserProfileName{
        get{
            if(currentUserProfileName == null){
                currentUserProfileName = [Select Name from Profile where id = : UserInfo.getProfileId()].Name;
            }return currentUserProfileName;
        }private set;
    }
    
    public List<PortalSidebarItemWrapper> portalSidebarItemWrappers{
        get{
            if(portalSidebarItemWrappers == null){
                List<PortalSidebarItems__c > psiRecList = [Select id, Name, Order__c, Is_VF_Page__c,
                        Group_Name__c, Item_Label__c, Link_or_VF_Page__c, Is_Pass_Parameters__c,
                        Visible_Profiles__c, Visible_Account_Record_Types__c, Is_Active__c
                        from PortalSidebarItems__c where Group_Name__c = :groupName 
                        order by Order__c ASC];
                if(psiRecList == null || psiRecList.isEmpty()) return null;
                portalSidebarItemWrappers = new List<PortalSidebarItemWrapper>();
                for(PortalSidebarItems__c psiRec: psiRecList){
                    portalSidebarItemWrappers.add(new PortalSidebarItemWrapper(psiRec));
                }
            }
            return portalSidebarItemWrappers;
        }private set;
    }
    
    public List<PortalSidebarItemWrapper> filteredPortalSidebarItemWrappers{
        get{
            List<PortalSidebarItemWrapper> filteredPortalSidebarItemWrappers = new List<PortalSidebarItemWrapper>();
            for(PortalSidebarItemWrapper psiWrapper: portalSidebarItemWrappers){
                if(isVisiblePSIWrapperItem(psiWrapper)){
                    filteredPortalSidebarItemWrappers.add(psiWrapper);
                }
            }
            return filteredPortalSidebarItemWrappers;
        }
    }
    
    public PortalSidebarItemWrapper currentChosenItem{
        get{
            for(PortalSidebarItemWrapper psiWrapper: portalSidebarItemWrappers){
                if(psiWrapper.name.equals(currentDevName)){
                    return psiWrapper;
                }
            }
            return null;
        }
    }
    
    public List<SelectOption> billAcctOptions{
        get{
            if(billAcctOptions==null){
                billAcctOptions = new List<SelectOption>();
                List<Billing_Account__c> bilLAccts = portalMyAccountHPCon.allAccounts;
                billAcctOptions.add(new SelectOption('', '-- None --'));
                for(Billing_Account__c bAcctRec: bilLAccts ){
                    billAcctOptions.add(new SelectOption(bAcctRec.id, bAcctRec.HiAF_Account_Number_Check_Digit__c+' - '+bAcctRec.Property__r.Street_Address__c+', '+bAcctRec.Property__r.Suburb__c));
                }
            }
            return billAcctOptions;
        }private set;
    }
    
    /* PRIVATE METHOD */
    private boolean isVisiblePSIWrapperItem(PortalSidebarItemWrapper psiWrapper){
        if(!psiWrapper.isActive) return false;
        boolean isVisibleProfile = false;
        if(psiWrapper.visibleProfileNames != null) {
            for(String visibleProfileName: psiWrapper.visibleProfileNames){
                if(currentUserProfileName.trim().equals(visibleProfileName.trim())){
                    isVisibleProfile = true;
                }
            }
        }else{
            isVisibleProfile = true;
        }
        if(!isVisibleProfile) return false;

        boolean isVisibleAccountRecordTypes = false;
        if(currentAccRecordType == null || ''.equals(currentAccRecordType.trim())) isVisibleAccountRecordTypes = true;
        else if(psiWrapper.visibleAccountRecordTypes!= null) {
            for(String visibleAccountRecordType: psiWrapper.visibleAccountRecordTypes){
                if(currentAccRecordType.trim().equals(visibleAccountRecordType.trim())){
                    isVisibleAccountRecordTypes = true;
                }
            }
        }else{
            isVisibleAccountRecordTypes = true;
        }
        if(!isVisibleAccountRecordTypes) return false;
        
        return true;
    }
    
    
    /* PUBLIC METHODS */
    public PageReference peformOperationOnSelectedBillAcct(){
        if(selectedBillAcctId==null) return null;
        PageReference pageRef = currentChosenItem.pageReference;
        pageRef.getParameters().clear();
        pageRef.getParameters().put('id',selectedBillAcctId);
        pageRef.setRedirect(true);
        return pageRef;
    }
    
    /* INNER CLASSES */
    public class PortalSidebarItemWrapper{
        public PortalSidebarItems__c psiRec {get;set;}
        public PageReference pageReference {
            get{
                String urlPrefix = '';
                String siteName = Site.getName();
                if(siteName == null || ''.equals(siteName)){
                    if(psiRec.Is_VF_Page__c){
                        urlPrefix = '/apex/';
                    }else{
                        urlPrefix = '/';
                    }
                }else{
                    String sitePrefix = Site.getPrefix();
                    if (sitePrefix == null || sitePrefix == ''){
                        urlPrefix = '/';
                    }
                    else {
                        urlPrefix = sitePrefix + '/';
                    }
                }
                PageReference pageRef = new PageReference(urlPrefix+psiRec.Link_or_VF_Page__c);
                if(psiRec.Is_Pass_Parameters__c){
                    //pageRef.getParameters().putAll(Apexpages.currentPage().getParameters());
                    Id recordId = Apexpages.currentPage().getParameters().get('id');
                    if(recordId !=null){
                        pageRef.getParameters().put('id',recordId);
                    }
                }
                return pageRef;
            }
        }
        public String linkURL{
            get{
                return pageReference.getURL();
            }
        }
        public String label {
            get{
                return psiRec.Item_Label__c;
            }
        }
        public String name{
            get{
                return psiRec.Name;
            }
        }
        public boolean isActive{
            get{
                return psiRec.Is_Active__c;
            }
        }
        public PortalSidebarItemWrapper(PortalSidebarItems__c psiRec){
            this.psiRec = psiRec;
        }
        public List<String> visibleProfileNames{
            get{
                if(psiRec.Visible_Profiles__c == null || ''.equals(psiRec.Visible_Profiles__c.trim())) return null;
                return psiRec.Visible_Profiles__c.split(',');
            }
        }
        public List<String> visibleAccountRecordTypes{
            get{
                if(psiRec.Visible_Account_Record_Types__c == null || ''.equals(psiRec.Visible_Account_Record_Types__c.trim())) return null;
                return psiRec.Visible_Account_Record_Types__c.split(',');
            }
        }
    }
    
    /* TEST METHOD */
    public static testmethod void test_ToolBarSelectRecord(){
        delete [Select id from PortalSidebarItems__c];
        PortalSidebarItems__c item1 = new PortalSidebarItems__c(Name = 'Test1', Order__c = 10, Is_VF_Page__c = true,
                        Group_Name__c = 'testgroup1', Item_Label__c = 'Test 1', Link_or_VF_Page__c = 'Test1', Is_Pass_Parameters__c = true, 
                        Visible_Profiles__c = 'SEW Portal User', Is_Active__c = true);
        insert item1;
        Account a;
        Contact c;
        Id uid = UserInfo.getUserId();
        a = new Account(name = 'TEST ACCOUNT');
        Database.insert(a);
        c = new Contact(AccountId = a.id, lastname = 'lastname');
        Database.insert(c);
        Billing_Account__c bAcct = new Billing_Account__c(Customer__c = a.id, Status__c = 'Active');
        Database.insert(bAcct);
        String testemail = 'puser000@amamama.com';
        Profile p = [select id from profile where name = 'SEW Portal User'];
        User pu = new User(profileId = p.id, username = testemail, email = testemail,
                           emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                           languagelocalekey = 'en_US', timezonesidkey = 'America/Los_Angeles',
                           alias='cspu', lastname='lastname', contactId = c.id);

        Database.insert(pu);
        System.runAs(pu) {
            PortalSidebarController con = new PortalSidebarController();
            con.groupName = 'testgroup1';
            con.currentDevName = 'Test1';
            con.selectedBillAcctId = item1.id;
            System.assertEquals(item1.Name, con.filteredPortalSidebarItemWrappers[0].name);
            System.assertEquals(item1.Name, con.currentChosenItem.name);
            System.assertEquals(item1.Item_Label__c , con.currentChosenItem.label);
            String tempStr = con.currentChosenItem.linkURL;
            List<SelectOption> tempSO = con.billAcctOptions;
            con.peformOperationOnSelectedBillAcct();
        }
    }

}