/*
    Type:       Controller Extension
    Purpose:    Controls the create customer and person wizard VF page

    Used By:    CreateCustomerAndPersonWizard
    ---------------------------------------------------------------
    History:

    07-Sep-2011 J.Pe (Davanti Consulting)    Created

*/

public class CreateCustomerAndPersonWizardExCon {
    
    /* PRIVATE PROPERTIES, VARIABLES */
    private ApexPages.StandardController stdCon;
    private Account currentCustomer {
        get{
            return (Account) stdCon.getRecord();
        }
    }
    private Property__c currentProperty{
        get{
            if(currentProperty==null){
                String propertyIdStr = ApexPages.currentPage().getParameters().get('propertyId');
                if(propertyIdStr == null || ''.equals(propertyIdStr)) return null;
                List<Property__c> properties = [Select id, Street_Address__c, Suburb__c, State__c, Postal_Code__c, DPID__c, NSM__c from Property__c where id = :propertyIdStr];
                if(properties.size()>0){
                    currentProperty = properties[0];
                }
            }return currentProperty;
        }set;
    }
    private String currentCustRecTypeDevName{
        get{
            return currentCustomer.RecordType.DeveloperName;
        }
    }
    
    /* PUBLIC PROPERTIES, VARIABLES */
    public Id createdCustomerId{
        get{
            if(currentCustomer.id!=null) return currentCustomer.id;
            return createdCustomerId;
        }
        set;
    }
    public boolean isResidential{
        get{
            return 'Residential'.equals(currentCustRecTypeDevName);
        }
    }
    public boolean isNonResCompany{
        get{
            return 'Non_Residential_Company_Customer'.equals(currentCustRecTypeDevName);
        }
    }
    public boolean isNonResIndividual{
        get{
            return 'Non_Residential_Individual_Customer'.equals(currentCustRecTypeDevName);
        }
    }
    public List<PersonWrapper> currentPersonWrappers{
        get{
            if(currentPersonWrappers==null){
                currentPersonWrappers= new List<PersonWrapper>();
                if(createdCustomerId==null){
                    for(Integer i = 0 ; i < 6 ; i++){
                        currentPersonWrappers.add(new PersonWrapper());
                    }
                }else{
                    List<Contact> existingContacts = [Select id, FirstName, LastName, Birthdate, 
                            Drivers_License_Number__c, MobilePhone,Phone,HomePhone,OtherPhone,
                            Email,Preferred_Contact_Type__c,Preferred_Phone_Type__c,
                            Primary_Secondary_Contact__c from Contact
                            where AccountId = :createdCustomerId];
                    for(Contact personRec: existingContacts){
                        currentPersonWrappers.add(new PersonWrapper(personRec));
                    }
                }
            }return currentPersonWrappers;
        }private set;
    }
    public List<PersonWrapper> filledInPersonWrappers{
        get{
            List<PersonWrapper> temp = new List<PersonWrapper>();
            for(PersonWrapper pw: currentPersonWrappers){
                if(!pw.isEmpty()){
                    temp.add(pw);
                }
            }
            return temp;
        }
    }
    public PersonWrapper firstCurrentPersonWrapper{
        get{
            return currentPersonWrappers[0];
        }    
    }
    public PersonWrapper secondCurrentPersonWrapper{
        get{
            return currentPersonWrappers[1];
        }    
    }
    public PersonWrapper thirdCurrentPersonWrapper{
        get{
            return currentPersonWrappers[2];
        }    
    }
    /*
    public boolean noInfoForLicence{
        get{
            if(noInfoForLicence==null){
                noInfoForLicence = false;
            }return noInfoForLicence;
        }set;
    }
    */
    public boolean isNSM{
        get{
            if(isNSM == null){                
                String isNSMStr = ApexPages.currentPage().getParameters().get('isNSM');
                if(isNSMStr != null && 'true'.equalsIgnoreCase(isNSMStr.trim())){
                    isNSM = true;
                }    
                else isNSM = false;
            }return isNSM;
        }set;
    }
    public boolean createSuccessful{
        get{
            boolean temp = (createdCustomerId != null);
            if(temp){
                if(isNSM){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'Customer and person records created. NOTE: Billing account cannot be created because the property is not seperately metered.'));
                }else{
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'Customer and person records created. Please proceed to create billing account or return to previous page.'));
                }
            }
            return temp;
        }
    }

    public List<SelectOption> customerRecordTypeSelections{
        get{
            if(customerRecordTypeSelections==null){
                customerRecordTypeSelections= new List<SelectOption>();
                customerRecordTypeSelections.add(new SelectOption('','-- None --'));
                Schema.DescribeSObjectResult accSObj = Account.SObjectType.getDescribe();
                List<Schema.RecordTypeInfo> recordTypeInfos = accSObj.getRecordTypeInfos();
                for(Schema.RecordTypeInfo rti: recordTypeInfos ){
                    if(rti.isAvailable()&&!('Master'.equals(rti.getName()))){
                        customerRecordTypeSelections.add(new SelectOption(rti.getRecordTypeId(), rti.getName()));
                    }
                }
            }return customerRecordTypeSelections;
        }
        private set;
    }
    public String fakeSecondCurrentPersonFirstName{get;set;}
    public String fakeSecondCurrentPersonLastName{get;set;}
    public String fakeThirdCurrentPersonFirstName{get;set;}
    public String fakeThirdCurrentPersonLastName{get;set;}
    public boolean isAndOthers{
        get{
            if(isAndOthers==null){
                isAndOthers = false;
            }return isAndOthers;
        }set;
    }
    
    public String retURL{
        get{
            String temp = Apexpages.currentPage().getParameters().get('retURL');
            if (temp==null) temp = '/home/home.jsp';
            return temp;
        }
    }
    public String getCompletedCustomerPageURL{
        get{
            return getCompletedCustomerPage(createdCustomerId, isNSM).getURL();
        }
    }
    
    /* CONSTRUCTOR */
    public CreateCustomerAndPersonWizardExCon(ApexPages.StandardController controller) {
        stdCon = controller;
        copyPropertyAddressToCustomerAddresses();
    }
    
    /* PUBLIC METHODS*/
    public void updateCustRecordType(){
        if(currentCustomer.RecordTypeId!=null){
            currentCustomer.RecordType = [SELECT id, Name, DeveloperName FROM RecordType where id=:currentCustomer.RecordTypeId];
        }
    }
    
    public void updateMainPersonInfoFromCustomer(){
        firstCurrentPersonWrapper.person.Preferred_Contact_Type__c = currentCustomer.Preferred_Contact_Type__c;
        firstCurrentPersonWrapper.person.Primary_Secondary_Contact__c = 'Primary Contact';
        if(fakeSecondCurrentPersonFirstName != null && !(''.equals(fakeSecondCurrentPersonFirstName ))){
            secondCurrentPersonWrapper.person.FirstName = fakeSecondCurrentPersonFirstName;
            secondCurrentPersonWrapper.person.Primary_Secondary_Contact__c = 'Secondary Contact';
        }
        if(fakeSecondCurrentPersonLastName!= null && !(''.equals(fakeSecondCurrentPersonLastName))){
            secondCurrentPersonWrapper.person.LastName= fakeSecondCurrentPersonLastName;
            secondCurrentPersonWrapper.person.Primary_Secondary_Contact__c = 'Secondary Contact';
        }
        if(fakeThirdCurrentPersonFirstName!= null && !(''.equals(fakeThirdCurrentPersonFirstName))){
            thirdCurrentPersonWrapper.person.FirstName = fakeThirdCurrentPersonFirstName;
        }
        if(fakeThirdCurrentPersonLastName!= null && !(''.equals(fakeThirdCurrentPersonLastName))){
            thirdCurrentPersonWrapper.person.LastName= fakeThirdCurrentPersonLastName;
        }
    }
    
    public void copyPrimaryAddressFromMailingAddress(){
            currentCustomer.ShippingStreet = currentCustomer.BillingStreet;
            currentCustomer.ShippingCity = currentCustomer.BillingCity;
            currentCustomer.ShippingState = currentCustomer.BillingState;
            currentCustomer.ShippingPostalCode = currentCustomer.BillingPostalCode;
            currentCustomer.ShippingCountry = currentCustomer.BillingCountry;
    }
    
    public PageReference submit(){
        if(!isValidEntry()) return null;
        copyFirstLastNameToAccountName();
        Savepoint sp = Database.setSavepoint();
        // Save Customer
        Account cloneCustomer = currentCustomer.clone(false,true);
        try{
            insert cloneCustomer;
        }catch (Exception ex){
            try{
                insert currentCustomer;
            }finally{
                Database.rollback(sp);
                return null;
            }
        }
        // Update Id into contacts
        List<Contact> personsToCreate = new List<Contact>();
        List<Contact> clonePersonsToCreate = new List<Contact>();
        for(PersonWrapper pw: filledInPersonWrappers){
            pw.person.AccountId = cloneCustomer.id;
            personsToCreate.add(pw.person);
            pw.clonePerson = pw.person.clone(false,true);
            clonePersonsToCreate.add(pw.clonePerson);
        }
        try{
            insert clonePersonsToCreate;
        }catch(Exception ex){
            try{
                insert personsToCreate;
            }finally{
                Database.rollback(sp);
                return null;
            }
        }
        /*
        // update id into relationship object
        List<Person_Customer_Relationship__c> relsToCreate = new List<Person_Customer_Relationship__c>();
        List<Person_Customer_Relationship__c> cloneRelsToCreate = new List<Person_Customer_Relationship__c>();
        for(PersonWrapper pw: filledInPersonWrappers){
            pw.thirdPartyRel.Customer__c = cloneCustomer.id;
            pw.thirdPartyRel.Person__c = pw.clonePerson.id;
            relsToCreate.add(pw.thirdPartyRel);
            cloneRelsToCreate.add(pw.thirdPartyRel.clone(false,true));
        }
        try{
            insert cloneRelsToCreate;
        }catch(Exception ex){
            try{
                insert relsToCreate;
            }finally{
                Database.rollback(sp);
                return null;
            }
        }
        */
        // create NSM record if isNSM
        if(isNSM){
            NSM__c nsm;
            if(currentProperty!=null){
                nsm = new NSM__c(Customer__c = cloneCustomer.id, Property__c = currentProperty.id, Status__c = 'Active');
            }else{
                nsm = new NSM__c(Customer__c = cloneCustomer.id, Status__c = 'Active');
            }
            try{
                insert nsm;
            }catch(Exception ex){
                Database.rollback(sp);
                return null;
            }
        }
        createdCustomerId = cloneCustomer.id;
        return getCompletedCustomerPage(createdCustomerId, isNSM);
    }
    public PageReference createBillAcc(){
        PageReference pageRef = Page.CreateBillingAccountWizard;
        if(currentProperty!=null){
            pageRef.getParameters().put('propertyId',currentProperty.id);
        }
        pageRef.getParameters().put('customerId',createdCustomerId);
        Map<String, String> currentParameters = ApexPages.currentPage().getParameters();
        for(String key: currentParameters.keySet()){
            if(!'id'.equalsignorecase(key) && !pageRef.getParameters().containsKey(key)){
                pageRef.getParameters().put(key,currentParameters.get(key));
            }
        }
        pageRef.setRedirect(true);
        return pageRef;
    }
    
    public PageReference viewCreatedRecord(){
        PageReference pageRef = new PageReference('/'+createdCustomerId);
        pageRef.setRedirect(true);
        return pageRef;
    }
    
    /* PRIVATE METHODS */
    private static PageReference getCompletedCustomerPage(Id customerId, boolean isNSM){
        PageReference pageRef = Page.CreateCustomerAndPersonWizard;
        String retURLStr = Apexpages.currentPage().getParameters().get('retURL');
        if(retURLStr != null){
            pageRef.getParameters().put('retURL',retURLStr );
        }
        String propertyIdStr = Apexpages.currentPage().getParameters().get('propertyId');
        if(propertyIdStr != null){
            pageRef.getParameters().put('propertyId',propertyIdStr );
        }
        pageRef.getParameters().put('id',customerId);
        pageRef.setRedirect(true);
        if(isNSM){
            pageRef.getParameters().put('isNSM','true');
        }
        return pageRef;
    }
    private boolean isValidEntry(){
        boolean valid = true;
        if (isResidential){
            valid &= isValidForResidential();
        } else if (isNonResCompany){
            valid &= isValidForNonResCompany();
        } else if (isNonResIndividual){
            valid &= isValidForNonResIndividual();
        }
        for(PersonWrapper pw: filledInPersonWrappers){
            valid &= pw.isValid();
        }
        return valid;
    }
    
    private boolean isValidForNonResIndividual(){
        boolean valid = true;
        if(currentCustomer.Name == null && (firstCurrentPersonWrapper.person.FirstName == null || firstCurrentPersonWrapper.person.LastName == null)){
            valid = false;
            firstCurrentPersonWrapper.person.FirstName.addError('One of Customer\'s Company Name or First & Last Name is required.');
            firstCurrentPersonWrapper.person.LastName.addError('One of Customer\'s Company Name or First & Last Name is required.');
            currentCustomer.Name.addError('One of Customer\'s Company Name or First & Last Name is required.');
        }
        /*
        if(currentCustomer.ACN__c == null && currentCustomer.ABN__c == null && (firstCurrentPersonWrapper.person.Birthdate == null)){
            valid = false;
            firstCurrentPersonWrapper.person.Birthdate.addError('Either one of the customer\'s ACN, ABN or Birthdate is required.');
            currentCustomer.ACN__c.addError('Either one of the customer\'s ACN, ABN or Birthdate is required.');
            currentCustomer.ABN__c.addError('Either one of the customer\'s ACN, ABN or Birthdate is required.');
        }
        */
        valid &= isCustomerLicenceValid();
        valid &= isContactDetailsValid();
        valid &= isAddressDetailsValid();
        return valid;
    }
    
    private boolean isValidForNonResCompany(){
        boolean valid = true;
        if(currentCustomer.Name == null){
            valid = false;
            currentCustomer.Name.addError('Customer\'s Company Name is required.');
        }
        /*
        if(currentCustomer.ACN__c == null && currentCustomer.ABN__c == null){
            valid = false;
            currentCustomer.ACN__c.addError('Either one of the customer\'s ACN or ABN is required.');
            currentCustomer.ABN__c.addError('Either one of the customer\'s ACN or ABN is required.');
        }
        */
        valid &= isContactDetailsValid();
        valid &= isAddressDetailsValid();
        return valid;
    }
    private boolean isValidForResidential(){
        boolean valid = true;
        if(firstCurrentPersonWrapper.person.FirstName == null){
            valid = false;
            firstCurrentPersonWrapper.person.FirstName.addError('Customer\'s First Name is required.');
        }
        if(firstCurrentPersonWrapper.person.LastName == null){
            valid = false;
            firstCurrentPersonWrapper.person.LastName.addError('Customer\'s Last Name is required.');
        }
        /*
        if(firstCurrentPersonWrapper.person.Birthdate == null){
            valid = false;
            firstCurrentPersonWrapper.person.Birthdate.addError('Customer\'s Birthdate is required.');
        }
        */
        valid &= isCustomerLicenceValid();
        valid &= isContactDetailsValid();
        valid &= isAddressDetailsValid();
        return valid;
    }
    private boolean isCustomerLicenceValid(){
        boolean valid = true;
        /*
        if(firstCurrentPersonWrapper.person.Drivers_License_Number__c == null && !noInfoForLicence){
            valid = false;
            firstCurrentPersonWrapper.person.Drivers_License_Number__c.addError('Customer\'s Driver License is required unless \'No Info\' is checked.');
        }
        */
        return valid;        
    }
    private boolean isContactDetailsValid(){
        boolean valid = true;
        if(currentCustomer.Phone == null){
            valid = false;
            currentCustomer.Phone.addError('Customer\'s Preferred Phone is required.');
        }
        if(currentCustomer.Preferred_Contact_Type__c == null){
            valid = false;
            currentCustomer.Preferred_Contact_Type__c.addError('Customer\'s Preferred Contact Type is required.');
        }
        return valid;
    }
    private boolean isAddressDetailsValid(){
        boolean valid = true;
        if(currentCustomer.BillingStreet == null){
            valid = false;
            currentCustomer.BillingStreet.addError('Customer\'s Mailing Street is required.');
        }
        if(currentCustomer.BillingCity == null){
            valid = false;
            currentCustomer.BillingCity.addError('Customer\'s Mailing City is required.');
        }
        if(currentCustomer.BillingState == null){
            valid = false;
            currentCustomer.BillingState.addError('Customer\'s Mailing State is required.');
        }
        if(currentCustomer.BillingCountry == null){
            valid = false;
            currentCustomer.BillingCountry.addError('Customer\'s Mailing Country is required.');
        }
        if(currentCustomer.BillingPostalCode == null){
            valid = false;
            currentCustomer.BillingPostalCode.addError('Customer\'s Mailing Post Code is required.');
        }
        return valid;
    }
    
    private void copyFirstLastNameToAccountName(){
        if(isResidential || currentCustomer.Name==null){
            String temp = firstCurrentPersonWrapper.person.FirstName + ' ' + firstCurrentPersonWrapper.person.LastName;
            if((fakeSecondCurrentPersonFirstName!=null&&!(''.equals(fakeSecondCurrentPersonFirstName)))||(fakeSecondCurrentPersonLastName!=null&&!(''.equals(fakeSecondCurrentPersonLastName)))){
                temp += ' & ';
                if(fakeSecondCurrentPersonFirstName!=null&&!(''.equals(fakeSecondCurrentPersonFirstName))){
                    temp += fakeSecondCurrentPersonFirstName;
                }
                if(fakeSecondCurrentPersonLastName!=null&&!(''.equals(fakeSecondCurrentPersonLastName))){
                    temp += ' '+fakeSecondCurrentPersonLastName;
                }
            }
            if((fakeThirdCurrentPersonFirstName!=null&&!(''.equals(fakeThirdCurrentPersonFirstName)))||(fakeThirdCurrentPersonLastName!=null&&!(''.equals(fakeThirdCurrentPersonLastName)))){
                temp += ' & ';
                if(fakeThirdCurrentPersonFirstName!=null&&!(''.equals(fakeThirdCurrentPersonFirstName))){
                    temp += fakeThirdCurrentPersonFirstName;
                }
                if(fakeThirdCurrentPersonLastName!=null&&!(''.equals(fakeThirdCurrentPersonLastName))){
                    temp += ' '+fakeThirdCurrentPersonLastName;
                }
            }
            if(isAndOthers){
                temp += ' & others';
            }
            currentCustomer.Name = temp ;
        }
        currentCustomer.Account_Name__c = currentCustomer.Name.substring(0,((currentCustomer.Name.length()>=30)?(30):(currentCustomer.Name.length())));
    }
    private void copyPropertyAddressToCustomerAddresses(){
        if(currentProperty!=null){
            currentCustomer.BillingStreet = currentProperty.Street_Address__c;
            currentCustomer.BillingCity = currentProperty.Suburb__c;
            currentCustomer.BillingState = currentProperty.State__c;
            currentCustomer.BillingPostalCode = currentProperty.Postal_Code__c;
            currentCustomer.BillingCountry = 'Australia';
            currentCustomer.Billing_Address_DPID__c = currentProperty.DPID__c;
            currentCustomer.ShippingStreet = currentProperty.Street_Address__c;
            currentCustomer.ShippingCity = currentProperty.Suburb__c;
            currentCustomer.ShippingState = currentProperty.State__c;
            currentCustomer.ShippingPostalCode = currentProperty.Postal_Code__c;
            currentCustomer.ShippingCountry = 'Australia';
            currentCustomer.Primary_Address_DPID__c = currentProperty.DPID__c;
        }
    }
    
    /* INNER CLASS */
    public class PersonWrapper{
        public Contact person{get;set;}
        public Person_Customer_Relationship__c thirdPartyRel{get;set;}
        
        // saving clone person for relationship
        public Contact clonePerson{get;set;}
        public String uniqueId{
            get{
                if(uniqueId == null){
                    uniqueId = (''+Datetime.now().getTime()+(Math.roundToLong(Decimal.valueof(Math.random()*10000))));
                }return uniqueId;
            }private set;
        }
        public PersonWrapper(){
            this(new Contact());
        }
        public PersonWrapper(Contact person){
            this.person = person;
            this.thirdPartyRel = new Person_Customer_Relationship__c();
        }
        private boolean isEmpty(){
            return person.FirstName == null &&
                   person.LastName == null &&
                   person.Birthdate == null &&
                   person.Drivers_License_Number__c == null &&
                   person.Preferred_Phone_Number__c == null &&
                   person.MobilePhone == null &&
                   person.Email == null &&
                   person.Preferred_Contact_Type__c == null &&
                   person.Primary_Secondary_Contact__c == null;
                   //thirdPartyRel.Third_Party_Type__c == null;
        }
        private boolean isValid(){
            boolean valid = true;
            if(person.FirstName == null){
                valid = false;
               person.FirstName.addError('Associated person\'s First Name is required.');
            }
            if(person.LastName == null){
                valid = false;
               person.LastName.addError('Associated person\'s Last Name is required.');
            }
            return valid;        
        }
    }
    
    /* TEST METHOD */
    public static testmethod void test_CreateCustomerAndPersonWizardExCon(){
        Property__c prop = new Property__c();
        prop.Universal_Id_c__c = 'sdgfsdgf';
        prop.Name = 'Test Property';
        prop.Street_Address__c = 'sdgservgtwe';
        prop.Suburb__c = 'sdgservgtwe';
        prop.State__c = 'sdgservgtwe';
        prop.Postal_Code__c = '1234';
        insert prop;
        PageReference pageRef = Page.CreateCustomerAndPersonWizard;
        pageRef.getParameters().put('propertyId',prop.id);
        Test.setCurrentPage(pageRef);
        Account newCustomer = new Account();
        ApexPages.StandardController stdCon = new ApexPages.StandardController(new Account());
        CreateCustomerAndPersonWizardExCon excon = new CreateCustomerAndPersonWizardExCon(stdCon);
        System.assertEquals(false, excon.isResidential);
        System.assertEquals(false, excon.isNonResCompany);
        System.assertEquals(false, excon.isNonResIndividual);
        for(SelectOption option: excon.customerRecordTypeSelections){
            if('Non-Residential Company Customer'.equals(option.getLabel())){
                excon.currentCustomer.recordTypeId = option.getValue();
            }
        }
        excon.updateCustRecordType();
        System.assertEquals(false, excon.isResidential);
        System.assertEquals(true, excon.isNonResCompany);
        System.assertEquals(false, excon.isNonResIndividual);
        excon.submit();
        System.assertEquals(false, excon.createSuccessful);
        for(SelectOption option: excon.customerRecordTypeSelections){
            if('Non-Residential Individual Customer'.equals(option.getLabel())){
                excon.currentCustomer.recordTypeId = option.getValue();
            }
        }
        excon.updateCustRecordType();
        System.assertEquals(false, excon.isResidential);
        System.assertEquals(false, excon.isNonResCompany);
        System.assertEquals(true, excon.isNonResIndividual);
        excon.submit();
        System.assertEquals(false, excon.createSuccessful);
        for(SelectOption option: excon.customerRecordTypeSelections){
            if('Residential Customer'.equals(option.getLabel())){
                excon.currentCustomer.recordTypeId = option.getValue();
            }
        }
        excon.updateCustRecordType();
        System.assertEquals(true, excon.isResidential);
        System.assertEquals(false, excon.isNonResCompany);
        System.assertEquals(false, excon.isNonResIndividual);
        excon.submit();
        System.assertEquals(false, excon.createSuccessful);
        excon.currentCustomer.BillingStreet = null;
        excon.currentCustomer.BillingCity = null;
        excon.currentCustomer.BillingState = null;
        excon.currentCustomer.BillingPostalCode = null;
        excon.currentCustomer.BillingCountry = null;
        excon.copyPrimaryAddressFromMailingAddress();
        excon.submit();
        System.assertEquals(false, excon.createSuccessful);
        excon.firstCurrentPersonWrapper.person.FirstName = 'Jay';
        excon.fakeSecondCurrentPersonFirstName = 'Kay';
        excon.firstCurrentPersonWrapper.person.LastName = 'El';
        excon.currentCustomer.Phone = '1481464';
        excon.currentCustomer.Preferred_Contact_Type__c = 'Call';
        excon.currentCustomer.BillingStreet = 'dsgfsgwrgrw';
        excon.currentCustomer.BillingCity = 'dsgfsgwrgrw';
        excon.currentCustomer.BillingState = 'dsgfsgwrgrw';
        excon.currentCustomer.BillingPostalCode = '1234';
        excon.currentCustomer.BillingCountry = 'dsgfsgwrgrw';
        excon.updateMainPersonInfoFromCustomer();
        excon.submit();
        System.assertEquals(false, excon.createSuccessful);
        excon.firstCurrentPersonWrapper.person.Birthdate = Date.today();
        //excon.noInfoForLicence = true;
        excon.secondCurrentPersonWrapper.person.Email = 'sdfgsdf@dfgd.com';
        excon.secondCurrentPersonWrapper.person.Firstname = null;
        excon.secondCurrentPersonWrapper.person.LastName = null;
        excon.submit();
        System.assertEquals(false, excon.createSuccessful);
        excon.secondCurrentPersonWrapper.person.Firstname = 'Kay';
        excon.secondCurrentPersonWrapper.person.LastName = 'Em';
        String tempStr = excon.secondCurrentPersonWrapper.uniqueId;
        excon.isNSM = true;
        excon.submit();
        System.assertEquals(true, excon.createSuccessful);
        excon.isNSM = false;
        excon.submit();
        System.assertEquals(true, excon.createSuccessful);
    }
}