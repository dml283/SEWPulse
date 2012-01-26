/*
    Type:       Controller Extension
    Purpose:    Controls the create billing account wizard VF page

    Used By:    CreateBillingAccountWizard
    ---------------------------------------------------------------
    History:

    12-Sep-2011 J.Pe (Davanti Consulting)    Created

*/
public class CreateBillingAccountWizardExCon {

    /* PRIVATE PROPERTIES, VARIABLES */
    private ApexPages.StandardController stdCon;
    private Billing_Account__c currentBillAcc {
        get{
            return (Billing_Account__c) stdCon.getRecord();
        }
    }
    private String currentBillAccRecTypeDevName{
        get{
            return currentBillAcc.RecordType.DeveloperName;
        }
    }
    
    /* PUBLIC PROPERTIES, VARIABLES */
    public Id createdBillAccId{
        get{
            if(currentBillAcc.id!=null) return currentBillAcc.id;
            return createdBillAccId;
        }
        set;
    }
    public boolean isGroupBillAcc{
        get{
            return 'Group_Billing_Account'.equals(currentBillAccRecTypeDevName);
        }
    }
    public boolean isBillAcc{
        get{
            return 'Billing_Account'.equals(currentBillAccRecTypeDevName);
        }
    }
    public boolean isAdHoc{
        get{
            return 'Ad_Hoc'.equals(currentBillAccRecTypeDevName);
        }
    }
    public boolean isCreateMultipleBillingAccounts{
        get{
            return isBillAcc && noOfBillAccsToCreate > 1;
        }
    }
    public Integer noOfBillAccsToCreate{
        get{
            if(noOfBillAccsToCreate == null){
                String noOfBillAccsToCreateStr = ApexPages.currentPage().getParameters().get('noOfBillAcctCreated');
                if(noOfBillAccsToCreateStr != null ){
                    try{
                        noOfBillAccsToCreate = Integer.valueof(noOfBillAccsToCreateStr);
                    }catch(Exception e){
                        noOfBillAccsToCreate = 1;
                    }
                }    
                else noOfBillAccsToCreate = 1;
            }return noOfBillAccsToCreate;
        }set;
    }
    public boolean isStepTwo{
        get{
            if(isStepTwo == null){
                isStepTwo = false;
            }return isStepTwo;
        }set;
    }
    public List<SelectOption> billAccRecordTypeSelections{
        get{
            if(billAccRecordTypeSelections==null){
                billAccRecordTypeSelections= new List<SelectOption>();
                billAccRecordTypeSelections.add(new SelectOption('','-- None --'));
                Schema.DescribeSObjectResult billAccSObj = Billing_Account__c.SObjectType.getDescribe();
                List<Schema.RecordTypeInfo> recordTypeInfos = billAccSObj.getRecordTypeInfos();
                for(Schema.RecordTypeInfo rti: recordTypeInfos ){
                    if(rti.isAvailable()&&!('Master'.equals(rti.getName()))){
                        billAccRecordTypeSelections.add(new SelectOption(rti.getRecordTypeId(), rti.getName()));
                        if(rti.isDefaultRecordTypeMapping()){
                            currentBillAcc.RecordTypeId = rti.getRecordTypeId();
                        }
                    }
                }
            }return billAccRecordTypeSelections;
        }
        private set;
    }
    public List<SelectOption> billAddressSameAsSelections{
        get{
            if(billAddressSameAsSelections==null){
                billAddressSameAsSelections= new List<SelectOption>();
                if(!isCreateMultipleBillingAccounts){
                    billAddressSameAsSelections.add(new SelectOption('','-- None --'));
                }
                List<Schema.PicklistEntry> picklistEntries = Billing_Account__c.Billing_Address_Same_As__c.getDescribe().getPicklistValues();
                for(Schema.PicklistEntry pEntry: picklistEntries){
                    billAddressSameAsSelections.add(new SelectOption(pEntry.getValue(),pEntry.getLabel()));
                }
            }return billAddressSameAsSelections;
        }
        private set;
    }
    public boolean isWelcomeHomeKit{
        get{
            if(isWelcomeHomeKit==null){
                String isWHKStr = ApexPages.currentPage().getParameters().get('isWHK');
                if(isWHKStr != null && 'false'.equalsIgnoreCase(isWHKStr.trim())){
                    isWelcomeHomeKit = false;
                }    
                else isWelcomeHomeKit= true;
            }return isWelcomeHomeKit;
        }set;
    }
    public boolean createSuccessful{
        get{
            boolean temp = (createdBillAccId!= null);
            if(temp){
                if (isCreateMultipleBillingAccounts){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'Billing Account created successfully. Multiple accounts created. Please return to previous page.'));
                }else{
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'Billing Account created successfully. Account Number: '+currentBillAcc.Name+'. Please return to previous page.'));
                }
            }
            return temp;
        }
    }
    public String retURL{
        get{
            String temp = Apexpages.currentPage().getParameters().get('retURL');
            if (temp==null) temp = '/home/home.jsp';
            return temp;
        }
    }
    public String accountListURL {
        get {
            if (accountListURL == null && currentBillAcc != null && currentBillAcc.Customer__c != null) {
                Id reportId;
            
                try {
                    Report r = [Select r.Id, r.Name, r.DeveloperName From Report r
                                where DeveloperName = 'Account_List'];  
                    reportId = r.Id;            
                } catch (QueryException e) {
                }
            
                accountListURL = reportId + '?pv0='+((String)currentBillAcc.Customer__c).substring(0, 15);
            }
            return accountListURL;
        }
        private set;
    }
    public List<Billing_Account__c> multiCreatedAccounts { get; set;}

    /* CONSTRUCTOR */
    public CreateBillingAccountWizardExCon(ApexPages.StandardController controller) {
        stdCon = controller;
        setupBillingAccount();
    }

    /* PUBLIC METHODS */
    public void updateBillAccRecordType(){
        isStepTwo = true;
        if(currentBillAcc.RecordTypeId!=null){
            currentBillAcc.RecordType = [SELECT id, Name, DeveloperName FROM RecordType where id=:currentBillAcc.RecordTypeId];
        }else{
            isStepTwo = false;
        }
        if(currentBillAcc.Property__c != null){
            currentBillAcc.Property__r = [Select id, Street_Address__c, Suburb__c, State__c, Postal_Code__c, DPID__c from Property__c where id = :currentBillAcc.Property__c];
        }
        if(currentBillAcc.Customer__c != null){
            currentBillAcc.Customer__r = [Select id, RecordType.DeveloperName, Title__c, Initials__c, Account_Name__c,
                    BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,
                    ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry,
                    Billing_Address_DPID__c, Primary_Address_DPID__c from Account where id = :currentBillAcc.Customer__c];
        }else{
            isStepTwo = false;
        }
    }
    public PageReference submit(){
        autoDefaultBAcctFields();
        if(!isValidEntry()) return null;
        // NEW CHANGE - do NOT link property!!
        Id tempPropertyId = currentBillAcc.Property__c;
        Property__c tempProperty = currentBillAcc.Property__r;
        currentBillAcc.Property__c = null;
        currentBillAcc.Property__r = null;
        if(isAdHoc || isGroupBillAcc){
            currentBillAcc.Status__c = 'Active';
        }else{
            currentBillAcc.Status__c = 'Pending';
        }
        Integer noOfRecToCreate = 1;
        if(isCreateMultipleBillingAccounts){
            noOfRecToCreate = noOfBillAccsToCreate;
        }
        List<String> hiAfAccountNumbers;
        try{
            hiAfAccountNumbers = WSUtil_CreateBillingAccount.createBillingAccount(currentBillAcc, isWelcomeHomeKit, noOfRecToCreate);
        }catch(WSUtil.MultipleWebServiceBusinessException multiEx){
            for(WSUtil.SingleWebServiceBusinessException ex : multiEx.multiEx){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Create Account Web Service error: '+ex.getMessage()));
            }
            return null;
        }catch (Exception ex){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Unknown error: '+ex.getMessage()));
            return null;
        }
        // now insert account for real with billing account number
        List<Billing_Account__c> multiCreatedAccounts = new List<Billing_Account__c>();
        for(String accNumber: hiAfAccountNumbers){
            Billing_Account__c temp = currentBillAcc.clone(false,true);
            temp.HiAf_Account_Number__c = accNumber;
            temp.Name = temp.HiAf_Account_Number__c;
            multiCreatedAccounts.add(temp);
        }
        try{
            insert multiCreatedAccounts;
//            multiCreatedAccounts = accToCreate;
            system.debug('foofoo');
            system.debug(multiCreatedAccounts);
        }catch (Exception ex){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Unknown issue after account created successfully in HiAf, SFDC billing account not created - please contact system administrator. Account Number: '+currentBillAcc.Name));
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getMessage()));
            currentBillAcc.Property__c = tempPropertyId ;
            currentBillAcc.Property__r = tempProperty;
            return null;
        }
        createdBillAccId = multiCreatedAccounts[0].id;
        return getCompletedBillAcctPage(createdBillAccId , isWelcomeHomeKit, noOfRecToCreate );
    }
    public PageReference viewCreatedRecord(){
        PageReference pageRef = new PageReference('/'+createdBillAccId);
        pageRef.setRedirect(true);
        return pageRef;
    }
    
    /* PRIVATE METHODS */
    private static PageReference getCompletedBillAcctPage(Id billAccId, boolean isWelcomeHomeKit, Integer noOfBillAcctCreated){
        PageReference pageRef = Page.createbillingaccountwizard;
        String retURLStr = Apexpages.currentPage().getParameters().get('retURL');
        if(retURLStr != null){
            pageRef.getParameters().put('retURL',retURLStr );
        }
        String propertyIdStr = Apexpages.currentPage().getParameters().get('propertyId');
        if(propertyIdStr != null){
            pageRef.getParameters().put('propertyId',propertyIdStr );
        }
        String customerIdStr = Apexpages.currentPage().getParameters().get('customerId');
        if(customerIdStr != null){
            pageRef.getParameters().put('customerId',customerIdStr );
        }
        pageRef.getParameters().put('id',billAccId);
        pageRef.setRedirect(true);
        if(isWelcomeHomeKit){
            pageRef.getParameters().put('isWHK','true');
        }else{
            pageRef.getParameters().put('isWHK','false');
        }
        pageRef.getParameters().put('noOfBillAcctCreated',noOfBillAcctCreated+'');
        return pageRef;
    }
    private boolean isValidEntry(){
        boolean valid = true;
 /*       if(currentBillAcc.Title__c == null && !currentBillAcc.Same_Name_As_Customer__c){
            valid = false;
            currentBillAcc.Title__c.addError('Title is mandatory if it is not same as customer record');
        }*/
/*        if(currentBillAcc.Initials__c == null && !currentBillAcc.Same_Name_As_Customer__c){
            valid = false;
            currentBillAcc.Initials__c.addError('First Name is mandatory if it is not same as customer record');
        }*/
        if(currentBillAcc.Account_Name__c == null && !currentBillAcc.Same_Name_As_Customer__c){
            valid = false;
            currentBillAcc.Account_Name__c.addError('Last Name is mandatory unless it is same as customer record');
        }
        if(currentBillAcc.Billing_Address_Same_As__c==null){
            if(currentBillAcc.Street_Address__c == null){
                valid = false;
                currentBillAcc.Street_Address__c.addError('Street Address is mandatory unless it is same as customer / property record.');
            }
            if(currentBillAcc.City__c == null){
                valid = false;
                currentBillAcc.City__c.addError('City is mandatory unless it is same as customer / property record.');
            }
            if(currentBillAcc.State__c == null){
                valid = false;
                currentBillAcc.State__c.addError('State is mandatory unless it is same as customer / property record.');
            }
            if(currentBillAcc.Postal_Code__c == null){
                valid = false;
                currentBillAcc.Postal_Code__c.addError('Postal Code is mandatory unless it is same as customer / property record.');
            }
            if(currentBillAcc.Country__c == null){
                valid = false;
                currentBillAcc.Country__c.addError('Country is mandatory unless it is same as customer / property record.');
            }
        }
        return valid;
    }
    private void setupBillingAccount(){
        if(createdBillAccId==null){
            String propertyIdStr = ApexPages.currentPage().getParameters().get('propertyId');
            if(propertyIdStr != null && !(''.equals(propertyIdStr))){
                currentBillAcc.Property__c = (Id)propertyIdStr;
            }
            String customerIdStr = ApexPages.currentPage().getParameters().get('customerId');
            if(customerIdStr != null && !(''.equals(customerIdStr))){
                currentBillAcc.Customer__c= (Id)customerIdStr ;
            }
        }
    }
    private void autoDefaultBAcctFields(){
        currentBillAcc.Name = 'TBD';
        if(currentBillAcc.Customer__c!=null){
            if('Residential'.equals(currentBillAcc.Customer__r.RecordType.DeveloperName)){
                currentBillAcc.Residential_or_Non_Residential__c = 'Residential';
            }else{
                currentBillAcc.Residential_or_Non_Residential__c = 'Non-Residential';
            }
        }
        if(currentBillAcc.Same_Name_As_Customer__c){
            if(currentBillAcc.Customer__r.Title__c != null) currentBillAcc.Title__c = currentBillAcc.Customer__r.Title__c;
            if(currentBillAcc.Customer__r.Initials__c != null) currentBillAcc.Initials__c= currentBillAcc.Customer__r.Initials__c;
            if(currentBillAcc.Customer__r.Account_Name__c != null) currentBillAcc.Account_Name__c = currentBillAcc.Customer__r.Account_Name__c ;
        }
        if('Customer Mailing'.equals(currentBillAcc.Billing_Address_Same_As__c)){
            currentBillAcc.Street_Address__c = currentBillAcc.Customer__r.BillingStreet;
            currentBillAcc.City__c = currentBillAcc.Customer__r.BillingCity;
            currentBillAcc.State__c = currentBillAcc.Customer__r.BillingState;
            currentBillAcc.Postal_Code__c = currentBillAcc.Customer__r.BillingPostalCode;
            currentBillAcc.DPID__c = currentBillAcc.Customer__r.Billing_Address_DPID__c;
            currentBillAcc.Country__c = currentBillAcc.Customer__r.BillingCountry;
        }else if('Customer Primary'.equals(currentBillAcc.Billing_Address_Same_As__c)){
            currentBillAcc.Street_Address__c = currentBillAcc.Customer__r.ShippingStreet;
            currentBillAcc.City__c = currentBillAcc.Customer__r.ShippingCity;
            currentBillAcc.State__c = currentBillAcc.Customer__r.ShippingState;
            currentBillAcc.Postal_Code__c = currentBillAcc.Customer__r.ShippingPostalCode;
            currentBillAcc.DPID__c = currentBillAcc.Customer__r.Primary_Address_DPID__c;
            currentBillAcc.Country__c = currentBillAcc.Customer__r.ShippingCountry;
        }else if('Property'.equals(currentBillAcc.Billing_Address_Same_As__c)){
            currentBillAcc.Street_Address__c = currentBillAcc.Property__r.Street_Address__c;
            currentBillAcc.City__c = currentBillAcc.Property__r.Suburb__c;
            currentBillAcc.State__c = currentBillAcc.Property__r.State__c;
            currentBillAcc.Postal_Code__c = currentBillAcc.Property__r.Postal_Code__c;
            currentBillAcc.DPID__c = currentBillAcc.Property__r.DPID__c ;
            currentBillAcc.Country__c = 'Australia';
        }
    }
    /* TEST METHOD */
    public static testmethod void test_CreateBillingAccountWizardExCon(){
        Property__c prop = new Property__c();
        prop.Universal_Id_c__c = 'sdgfsdgf';
        prop.Name = 'Test Property';
        prop.Street_Address__c = 'sdgservgtwe';
        prop.Suburb__c = 'sdgservgtwe';
        prop.State__c = 'sdgservgtwe';
        prop.Postal_Code__c = '1234';
        insert prop;
        Account acc = new Account();
        acc.Title__c = 'Mr';
        acc.Initials__c = 'J';
        acc.Account_Name__c = 'Jay and Kay El';
        acc.name = acc.Account_Name__c;
        acc.RecordTypeId = [Select id from RecordType where DeveloperName = 'Residential' and SObjectType = 'Account'][0].id;
        acc.BillingStreet = 'sdfascvv';
        acc.BillingCity = 'sdfascvv';
        acc.BillingState = 'sdfascvv';
        acc.BillingPostalCode = '1234';
        acc.BillingCountry = 'sdfascvv';
        insert acc;
        PageReference pageRef = Page.CreateBillingAccountWizard;
        pageRef.getParameters().put('propertyId',prop.id);
        pageRef.getParameters().put('customerId',acc.id);
        pageRef.getParameters().put('isWHK', 'true');
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController stdCon = new ApexPages.StandardController(new Billing_Account__c());
        CreateBillingAccountWizardExCon excon = new CreateBillingAccountWizardExCon(stdCon);
        System.assertEquals(false, excon.isStepTwo);
        System.assertEquals(false, excon.isGroupBillAcc);
        System.assertEquals(false, excon.isBillAcc);
        System.assertEquals(false, excon.isAdHoc);
        for(SelectOption option: excon.billAccRecordTypeSelections){
            if('Group Billing Account'.equals(option.getLabel())){
                excon.currentBillAcc.recordTypeId = option.getValue();
            }
        }
        excon.updateBillAccRecordType();
        System.assertEquals(true, excon.isStepTwo);
        System.assertEquals(true, excon.isGroupBillAcc);
        System.assertEquals(false, excon.isBillAcc);
        System.assertEquals(false, excon.isAdHoc);
        for(SelectOption option: excon.billAccRecordTypeSelections){
            if('Ad-Hoc'.equals(option.getLabel())){
                excon.currentBillAcc.recordTypeId = option.getValue();
            }
        }
        excon.updateBillAccRecordType();
        System.assertEquals(true, excon.isStepTwo);
        System.assertEquals(false, excon.isGroupBillAcc);
        System.assertEquals(false, excon.isBillAcc);
        System.assertEquals(true, excon.isAdHoc);
        for(SelectOption option: excon.billAccRecordTypeSelections){
            if('Billing Account'.equals(option.getLabel())){
                excon.currentBillAcc.recordTypeId = option.getValue();
            }
        }
        excon.updateBillAccRecordType();
        System.assertEquals(true, excon.isStepTwo);
        System.assertEquals(false, excon.isGroupBillAcc);
        System.assertEquals(true, excon.isBillAcc);
        System.assertEquals(false, excon.isAdHoc);
        excon.submit();
        System.assertEquals(false, excon.createSuccessful);
        List<SelectOption> temp = excon.billAddressSameAsSelections;
        excon.currentBillAcc.Same_Name_As_Customer__c = true;
        excon.currentBillAcc.Billing_Address_Same_As__c = 'Customer Mailing';
        excon.submit();
        System.assertEquals(true, excon.createSuccessful);
        excon.currentBillAcc.Billing_Address_Same_As__c = 'Customer Primary';
        excon.submit();
        System.assertEquals(true, excon.createSuccessful);
        excon.currentBillAcc.Billing_Address_Same_As__c = 'Property';
        excon.submit();
        System.assertEquals(true, excon.createSuccessful);
        excon.noOfBillAccsToCreate = 2;
        pageRef = excon.submit();
        System.assertEquals(true, excon.createSuccessful);
        excon.viewCreatedRecord();
        String url = excon.accountListUrl;
        url = excon.retURL;
        Test.setCurrentPage(pageRef);
        stdCon = new ApexPages.StandardController([Select id from Billing_Account__c where id = :pageRef.getParameters().get('id')]);
        excon = new CreateBillingAccountWizardExCon(stdCon);
        System.assertEquals(2, excon.noOfBillAccsToCreate);

        TibcoCreateBillingAccount_MessageType.ErrorStatus_element  err = new TibcoCreateBillingAccount_MessageType.ErrorStatus_element();
    }
}