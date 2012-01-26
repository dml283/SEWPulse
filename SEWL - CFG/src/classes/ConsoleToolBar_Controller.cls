public with sharing class ConsoleToolBar_Controller {

/*
    Type:       Controller Extension
    Purpose:    Controls what gets displayed in the console toolbar 

    Used By:    ConsoleToolBar component
    ---------------------------------------------------------------
    History:

    09-Aug-2011 J.Pe (Davanti Consulting)    Created

*/

    public Id recordId {
        get ;set;
    }
    public Account customer {
        get {
            if (recordId == null) return null;
            if (customer == null){
                if(Account.sObjectType.getDescribe().getName().equals(objectType)) {
                    customer = [Select id, name from Account where id = :recordId];
                }
                if(Billing_Account__c.sObjectType.getDescribe().getName().equals(objectType)){
                    Billing_Account__c billAcct = [Select id, Customer__c, Customer__r.id, Customer__r.Name from Billing_Account__c where id = :recordId];
                    customer = billAcct.Customer__r;
                }
            }return customer ;
        }
        set;
    }
    public Billing_Account__c billAcct {
        get {
            if (recordId == null) return null;
            if (billAcct == null){
                if(Billing_Account__c.sObjectType.getDescribe().getName().equals(objectType)) {
                    billAcct = [Select id, name from Billing_Account__c where id = :recordId];
                }
            }return billAcct ;
        }
        set;
    }
    public Property__c property {
        get {
            if (recordId == null) return null;
            if (property == null){
                if(Property__c.sObjectType.getDescribe().getName().equals(objectType)){
                    property = [Select id, name from Property__c where id = :recordId];
                }
                if(Billing_Account__c.sObjectType.getDescribe().getName().equals(objectType)){
                    Billing_Account__c billAcct = [Select id, Property__c, Property__r.id, Property__r.Name from Billing_Account__c where id = :recordId];
                    property = billAcct.Property__r;
                }
            }return property ;
        }
        set;
    }

    public String objectType {
        get {
            if (recordId != null && objectType == null) {
                if (((String)recordId).startsWith(Billing_Account__c.sObjectType.getDescribe().getKeyPrefix())) {
                    objectType = Billing_Account__c.sObjectType.getDescribe().getName();
                }
                if (((String)recordId).startsWith(Account.sObjectType.getDescribe().getKeyPrefix())) {
                    objectType = Account.sObjectType.getDescribe().getName();
                }
                if (((String)recordId).startsWith(Property__c.sObjectType.getDescribe().getKeyPrefix())) {
                    objectType = Property__c.sObjectType.getDescribe().getName();
                }
            }
            return objectType;
        }
        set;
    }
    
    public String quickCaseURLPrefix{
        get{
            if(quickCaseURLPrefix==null){
                PageReference pageRef = new PageReference('/500/e');
                pageRef.getParameters().put('isdtp','vw');
                pageRef.getParameters().put('retURL','/'+recordId);
                if(customer!=null){
                    pageRef.getParameters().put('def_account_id',customer.Id);
                }
                if(property!=null){
                    pageRef.getParameters().put('CF'+casePropertyFieldId+'_lkid',property.Id);
                    pageRef.getParameters().put('CF'+casePropertyFieldId,property.Name);
                }
                if(billAcct!=null){
                    pageRef.getParameters().put('CF'+caseBillAccFieldId +'_lkid',billAcct.Id);
                    pageRef.getParameters().put('CF'+caseBillAccFieldId ,billAcct.Name);
                }
                if(billAcct!=null){
                    pageRef.getParameters().put('CF'+caseBillAccSMRFieldId +'_lkid',billAcct.Id);
                    pageRef.getParameters().put('CF'+caseBillAccSMRFieldId ,billAcct.Name);
                }

                pageRef.getParameters().put('ent',Case.sObjectType.getDescribe().getName());
                pageRef.getParameters().put('cas5',caseDefaultGroupTypeValue );
                pageRef.getParameters().put('nooverride','1');
                quickCaseURLPrefix = pageRef.getURL();
            }return quickCaseURLPrefix;
        }private set;
    }

    public String quickNotesURLPrefix { 
        get{
            if(quickNotesURLPrefix ==null){
                PageReference pageRef = Page.QuickNotes;
                pageRef.getParameters().putAll(urlDefaultParameters);
                quickNotesURLPrefix = pageRef.getURL();
            }return quickNotesURLPrefix ;
        }private set;
    }    
    public String quickCreateCustomerURL{
        get{
            if (quickCreateCustomerURL==null){
                PageReference pageRef = Page.CreateCustomerAndPersonWizard;
                pageRef.getParameters().putAll(urlDefaultParameters);
                quickCreateCustomerURL = pageRef.getURL();
            } return quickCreateCustomerURL;
        }private set;
    }
    
    public String quickCreateBillAcctURL{
        get{
            if (quickCreateBillAcctURL==null){
                PageReference pageRef = Page.CreateBillingAccountWizard;
                pageRef.getParameters().putAll(urlDefaultParameters);
                quickCreateBillAcctURL= pageRef.getURL();
            } return quickCreateBillAcctURL;
        }private set;
    }
    
    public String urlParameterSuffix{
        get{
            if(urlParameterSuffix==null){
                PageReference pageRef = new PageReference('');
                pageRef.getParameters().putAll(urlDefaultParameters);
                urlParameterSuffix = pageRef.getURL();
                urlParameterSuffix = urlParameterSuffix.substring(urlParameterSuffix.indexOf('?'), urlParameterSuffix.length());
            }return urlParameterSuffix;
        }private set;
    }
    
    private Map<String, String> urlDefaultParameters{
        get{
            if(urlDefaultParameters== null){
                PageReference pageRef = new PageReference('');
                pageRef.getParameters().put('isdtp','vw');
                pageRef.getParameters().put('retURL','/'+recordId);
                if(customer!=null){
                    pageRef.getParameters().put('customerId',customer.Id);
                }
                if(billAcct!=null){
                    pageRef.getParameters().put('billAcctId',billAcct.Id);
                }
                if(property!=null){
                    pageRef.getParameters().put('propertyId',property.Id);
                }
                urlDefaultParameters = pageRef.getParameters();
            } return urlDefaultParameters;
        }private set;
    }
    
    public List<SelectOption> createCaseSelectOptions{
        get{
            if (createCaseSelectOptions==null){
                createCaseSelectOptions = convertCaseTypeListToSelectOption(CaseTypeSettingUtil.getCreateCaseType());
            }return createCaseSelectOptions;
        }private set;
    }
    
    public List<SelectOption> processSelectOptions{
        get{
            if (processSelectOptions==null){
                processSelectOptions= convertCaseTypeListToSelectOption(CaseTypeSettingUtil.getProcessCaseType());
            }return processSelectOptions;
        }private set;
    }
    
    public String casePropertyFieldId{
        get{
            String temp = SystemSettings__c.getInstance().CasePropertyFieldId__c;
            return ((temp!=null)?(temp ):('NULL'));
        }
    }
    public String caseBillAccFieldId {
        get{
            String temp = SystemSettings__c.getInstance().CaseBillingAccountFieldId__c;
            return ((temp!=null)?(temp ):('NULL'));
        }
    }
    public String caseBillAccSMRFieldId {
        get{
            String temp = SystemSettings__c.getInstance().CaseBillingAccountSMRFieldId__c;
            return ((temp!=null)?(temp ):('NULL'));
        }
    }
    public static String caseDefaultGroupTypeValue {
        get{
            String temp = CaseDefault__c.getInstance().Group_Type__c;
            return ((temp!=null)?(temp ):('NULL'));
        }
    }
    private List<SelectOption> convertCaseTypeListToSelectOption(List<RecordType> caseRecTypes){
        List<SelectOption> temp = new List<SelectOption>();
        temp.add(new SelectOption('', 'Select One...'));
        for(RecordType crt: caseRecTypes){
            if(crt.id!=null){
                temp.add(new SelectOption(crt.id, crt.Name));
            }else{
                temp.add(new SelectOption(crt.DeveloperName, crt.Name));
            }
        }
        return temp;
    }
    public static testmethod void test_ConsoleToolBar_Controller(){
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

        Billing_Account__c billAcc1 = new Billing_Account__c();
        billAcc1.Name = 'TBD';
        billAcc1.Customer__c = account.id;
        billAcc1.Property__c = prop.id;
        billAcc1.Role__c = 'Tenant';
        billAcc1.Status__c = 'Pending';
        billAcc1.HiAF_Account_Number__c = 'dfvtserb';
        insert billAcc1; 
        
        ConsoleToolBar_Controller con1 = new ConsoleToolBar_Controller();
        con1.recordId = account.id;
        List<SelectOption> tempSelectOptList = con1.createCaseSelectOptions;
        tempSelectOptList = con1.processSelectOptions;
        System.assertEquals(account.id,con1.recordId);
        System.assertEquals(account.id,con1.customer.id);
        System.assertEquals(null,con1.property);
        System.assertEquals(null,con1.billAcct);
        System.assertEquals('Account',con1.objectType);
        PageReference casePageRef = new PageReference('/500/e');
        casePageRef.getParameters().put('isdtp','vw');
        casePageRef.getParameters().put('retURL','/'+account.id);
        casePageRef.getParameters().put('def_account_id',account.Id);
        casePageRef.getParameters().put('ent',Case.sObjectType.getDescribe().getName());
        casePageRef.getParameters().put('cas5',caseDefaultGroupTypeValue );
        casePageRef.getParameters().put('nooverride','1');
        System.assertEquals(casePageRef.getURL(),con1.quickCaseURLPrefix);
        
        PageReference customerPageRef = Page.CreateCustomerAndPersonWizard;
        customerPageRef.getParameters().put('isdtp','vw');
        customerPageRef.getParameters().put('retURL','/'+account.id);
        customerPageRef.getParameters().put('customerId',account.Id);
        System.assertEquals(customerPageRef.getURL(),con1.quickCreateCustomerURL);
        PageReference billAcctPageRef = Page.CreateBillingAccountWizard;
        billAcctPageRef.getParameters().put('isdtp','vw');
        billAcctPageRef.getParameters().put('retURL','/'+account.id);
        billAcctPageRef.getParameters().put('customerId',account.Id);
        System.assertEquals(billAcctPageRef.getURL(),con1.quickCreateBillAcctURL);
        
        ConsoleToolBar_Controller con2 = new ConsoleToolBar_Controller();
        con2.recordId =  prop.id;
        System.assertEquals(prop.id,con2.recordId);
        System.assertEquals(prop.id,con2.property.id);
        System.assertEquals(null,con2.customer);
        System.assertEquals(null,con2.billAcct);
        System.assertEquals('Property__c',con2.objectType);
        PageReference casePageRef2 = new PageReference('/500/e');
        casePageRef2.getParameters().put('isdtp','vw');
        casePageRef2.getParameters().put('retURL','/'+prop.id);
        casePageRef2.getParameters().put('CF'+con2.casePropertyFieldId+'_lkid',prop.Id);
        casePageRef2.getParameters().put('CF'+con2.casePropertyFieldId,prop.Name);
        casePageRef2.getParameters().put('ent',Case.sObjectType.getDescribe().getName());
        casePageRef2.getParameters().put('cas5',caseDefaultGroupTypeValue );
        casePageRef2.getParameters().put('nooverride','1');
        System.assertEquals(casePageRef2.getURL(),con2.quickCaseURLPrefix);
        PageReference customerPageRef2 = Page.CreateCustomerAndPersonWizard;
        customerPageRef2.getParameters().put('isdtp','vw');
        customerPageRef2.getParameters().put('retURL','/'+prop.id);
        customerPageRef2.getParameters().put('propertyId',prop.Id);
        System.assertEquals(customerPageRef2.getURL(),con2.quickCreateCustomerURL);
        PageReference billAcctPageRef2 = Page.CreateBillingAccountWizard;
        billAcctPageRef2.getParameters().put('isdtp','vw');
        billAcctPageRef2.getParameters().put('retURL','/'+prop.id);
        billAcctPageRef2.getParameters().put('propertyId',prop.Id);
        System.assertEquals(billAcctPageRef2.getURL(),con2.quickCreateBillAcctURL);
        
        ConsoleToolBar_Controller con3 = new ConsoleToolBar_Controller();
        con3.recordId = billAcc1.id;
        System.assertEquals(billAcc1.id,con3.recordId);
        System.assertEquals(billAcc1.id,con3.billAcct.id);
        System.assertEquals(billAcc1.Customer__c,con3.customer.id);
        System.assertEquals(billAcc1.Property__c,con3.property.id);
        System.assertEquals('Billing_Account__c',con3.objectType);
        PageReference casePageRef3 = new PageReference('/500/e');
        casePageRef3.getParameters().put('isdtp','vw');
        casePageRef3.getParameters().put('retURL','/'+billAcc1.id);
        casePageRef3.getParameters().put('def_account_id',account.Id);
        casePageRef3.getParameters().put('CF'+con3.casePropertyFieldId+'_lkid',prop.Id);
        casePageRef3.getParameters().put('CF'+con3.casePropertyFieldId,prop.Name);
        casePageRef3.getParameters().put('CF'+con3.caseBillAccFieldId+'_lkid',billAcc1.Id);
        casePageRef3.getParameters().put('CF'+con3.caseBillAccFieldId,billAcc1.HiAF_Account_Number__c);
        casePageRef3.getParameters().put('CF'+con3.caseBillAccSMRFieldId+'_lkid',billAcc1.Id);
        casePageRef3.getParameters().put('CF'+con3.caseBillAccSMRFieldId,billAcc1.HiAF_Account_Number__c);
        casePageRef3.getParameters().put('ent',Case.sObjectType.getDescribe().getName());
        casePageRef3.getParameters().put('cas5',caseDefaultGroupTypeValue );
        casePageRef3.getParameters().put('nooverride','1');
        System.assertEquals(casePageRef3.getURL(),con3.quickCaseURLPrefix);
        PageReference customerPageRef3 = Page.CreateCustomerAndPersonWizard;
        customerPageRef3.getParameters().put('isdtp','vw');
        customerPageRef3.getParameters().put('retURL','/'+billAcc1.id);
        customerPageRef3.getParameters().put('propertyId',prop.Id);
        customerPageRef3.getParameters().put('customerId',account.Id);
        customerPageRef3.getParameters().put('billAcctId',billAcc1.id);
        System.assertEquals(customerPageRef3.getURL(),con3.quickCreateCustomerURL);
        PageReference billAcctPageRef3 = Page.CreateBillingAccountWizard;
        billAcctPageRef3.getParameters().put('isdtp','vw');
        billAcctPageRef3.getParameters().put('retURL','/'+billAcc1.id);
        billAcctPageRef3.getParameters().put('propertyId',prop.Id);
        billAcctPageRef3.getParameters().put('customerId',account.Id);
        billAcctPageRef3.getParameters().put('billAcctId',billAcc1.id);
        System.assertEquals(billAcctPageRef3.getURL(),con3.quickCreateBillAcctURL);
        PageReference quickNotePageRef = Page.QuickNotes;
        quickNotePageRef.getParameters().put('isdtp','vw');
        quickNotePageRef.getParameters().put('retURL','/'+billAcc1.id);
        quickNotePageRef.getParameters().put('propertyId',prop.Id);
        quickNotePageRef.getParameters().put('customerId',account.Id);
        quickNotePageRef.getParameters().put('billAcctId',billAcc1.id);
        System.assertEquals(quickNotePageRef.getURL(),con3.quickNotesURLPrefix );
        String temp = con3.urlParameterSuffix;
        
        CaseTypeSettingUtil.getAutoSuspendCaseType();
        CaseTypeSettingUtil.getQuickNotesCaseType();
        
    }
}