/*
    Type:       Controller
    Purpose:    Controls the portal new user registration VF page

    Used By:    SiteNewPortalUserRegistration
    ---------------------------------------------------------------
    History:

    07-Sep-2011 J.Pe (Davanti Consulting)    Created

*/
public without sharing class SiteNewPortalUserRegistrationController {
    
    /* PRIVATE PROPERTIES, VARIABLES */
    private String billAcctErrorMessage{
        get{
            if (billAcctErrorMessage==null){
                billAcctErrorMessage = 'The account details you provided could not be verified. Please try again.';
            }return billAcctErrorMessage;
        }
        set;
    }
    private String contactInfoErrorMessage{get;set;}
    private boolean isBypassreCAPTCHA{
        get{
            if(isBypassreCAPTCHA== null){
                isBypassreCAPTCHA = false;
            }return isBypassreCAPTCHA;
        }set;
    }
    /* PUBLIC PROPERTIES, VARIABLES */
    public reCAPTCHA reCAPTCHA{
        get{
            if (reCAPTCHA == null){
                reCAPTCHA = new reCAPTCHA();
            }return reCAPTCHA;
        }set;
    }

    public String accNumberEntryStr{get;set;}
    public String accNameEntryStr{get;set;}
    public User newUserToRegister{
        get{
            if (newUserToRegister==null){
                newUserToRegister = setupNewUserToRegister();
            }return newUserToRegister;
        }private set;
    }
    public String userFirstNameEntryStr{get;set;}
    public String userLastNameEntryStr{get;set;}
    public String userTelNoEntryStr{get;set;}
    public Date userBirthdateEntryDate{
        get{
            return newUserToRegister.HIDDEN_Birthdate__c;
        }
    }
    public String userDriverLicenseNoStr{get;set;}
    public String userConfirmEmailEntryStr{get;set;}
    public String userPasswordEntryStr{get;set;}
    public String userConfirmPasswordEntryStr{get;set;}
    public boolean isValidUserDetail{
        get{
            if(isValidUserDetail==null || billAcctEntered== null || contactInfoEntered == null){
                isValidUserDetail = false;
            }
            return isValidUserDetail;
        }set;
    }
    public boolean isMarketingOptIn{
        get{
            if(isValidUserDetail) return contactInfoEntered.Marketing_Opt_In__c;
            return false;
        }set{
            if(isValidUserDetail) contactInfoEntered.Marketing_Opt_In__c = value;
        }
    }
    public boolean isNewUserRegSuccessful{
        get{
            if(isNewUserRegSuccessful == null){
                isNewUserRegSuccessful = false;
            }return isNewUserRegSuccessful;
        }private set;
    }

    public Billing_Account__c billAcctEntered{
        get{
            if(billAcctEntered==null){
                if(accNumberEntryStr==null||''.equals(accNumberEntryStr)) return null;
                if(accNameEntryStr==null||''.equals(accNameEntryStr)) return null;
                billAcctEntered = findBillingAccount(accNumberEntryStr, accNameEntryStr);
            }return billAcctEntered;
        }private set;
    }
    public Contact contactInfoEntered{
        get{
            if(contactInfoEntered==null){
                if (billAcctEntered==null) return null;
                if(userLastNameEntryStr==null||''.equals(userLastNameEntryStr)){
                    contactInfoErrorMessage = 'Last name must be provided.';
                    return null;
                }
                List<Contact> relatedContacts = findContacts(billAcctEntered.Customer__c, userFirstNameEntryStr, userLastNameEntryStr, userTelNoEntryStr, userBirthdateEntryDate, userDriverLicenseNoStr);
                if(relatedContacts==null || relatedContacts.isEmpty()) {
                    contactInfoErrorMessage = 'The identification details you provided could not be verified. Please try again.';
                    return null;
                }
                contactInfoEntered = getContactwithoutUser(relatedContacts);
                if(contactInfoEntered==null) {
                    contactInfoErrorMessage = 'There is already a user registered under the same identification details.';
                    return null;
                }
            }return contactInfoEntered;
        }private set;
    }
    
    /* PUBLIC METHODS */
    public void checkAccountAndContactDetails(){
        boolean isValidAccount = true;
        reCAPTCHA.verify();
        if(!reCAPTCHA.correctResponse && !isBypassreCAPTCHA){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'The Captcha code you entered is invalid. Please try again.'));
            isValidAccount = false;
        } else{
            if(billAcctEntered==null){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,billAcctErrorMessage));
                isValidAccount = false;
            }else{
                if(contactInfoEntered==null){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,contactInfoErrorMessage));
                    isValidAccount = false;
                }
            }
        }
        if(!isValidAccount){
            billAcctEntered = null;
            contactInfoEntered = null;
        }
    }

    public void prepareUserReg(){
        isValidUserDetail = true;
        if(newUserToRegister.Username == null || ''.equals(newUserToRegister.Username.trim())){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Username is required.'));
            isValidUserDetail = false;
        }else{
            List<User> usersWithMatchingUsername = [Select id from User where Username = :PortalUtil.convertUserName(newUserToRegister.Username)];
            if(usersWithMatchingUsername != null && !(usersWithMatchingUsername.isEmpty())){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Username already exists - please choose another username.'));
                isValidUserDetail = false;
            }
        }
        if( userPasswordEntryStr == null || ''.equals(userPasswordEntryStr.trim())){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Password is required.'));
            isValidUserDetail = false;
        }else {
            Pattern passwordPattern = Pattern.compile('^.*(?=.{8,})(?=.*\\d)(?=.*[A-Za-z]).*$');
            Matcher passwordMatcher = passwordPattern.matcher(userPasswordEntryStr);
            if (userPasswordEntryStr.toLowerCase().contains('password') || (!passwordMatcher.matches()) ){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Password must contain one alphabet and one numeric character, must be a minimum of 8 characters and it cannot contain the text \"password\"'));
                isValidUserDetail = false;
            }else if (userConfirmPasswordEntryStr == null || ''.equals(userConfirmPasswordEntryStr.trim()) || (!userPasswordEntryStr.equals(userConfirmPasswordEntryStr))){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Confirm Password must be the same as Password'));
                isValidUserDetail = false;
            }
        }
        if(newUserToRegister.email == null || ''.equals(newUserToRegister.email .trim())){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Email is required.'));
            isValidUserDetail = false;
        }
        if(newUserToRegister.Secret_Question__c == null || ''.equals(newUserToRegister.Secret_Question__c.trim())){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Secret Question is required.'));
            isValidUserDetail = false;
        }
        if(newUserToRegister.Secret_Answer__c == null || ''.equals(newUserToRegister.Secret_Answer__c.trim())){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Secret Answer is required.'));
            isValidUserDetail = false;
        }
        if(userConfirmEmailEntryStr==null || (!userConfirmEmailEntryStr.equals(newUserToRegister.email))){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Emails entered does not match - please re-enter the email addresses.'));
            newUserToRegister.email = null;
            userConfirmEmailEntryStr = null;
            isValidUserDetail = false;
        }
        if(isValidUserDetail){
            newUserToRegister.contactid = contactInfoEntered.id;
            isMarketingOptIn = true;
        }else{
            userPasswordEntryStr = null;
            userConfirmPasswordEntryStr = null;
        }
    }
    public void submitNewUserReg(){
        PortalUtil_WS.PortalUtil stub = new PortalUtil_WS.PortalUtil();
        stub.SessionHeader = new PortalUtil_WS.SessionHeader_element();
        stub.SessionHeader.sessionId = UserInfo.getSessionId();
        try{
            PortalUtil_WS.PortalUtilResponse response = stub.newUserRegistration(contactInfoEntered.id, newUserToRegister.userName, userPasswordEntryStr, newUserToRegister.email, newUserToRegister.Secret_Question__c, newUserToRegister.Secret_Answer__c, contactInfoEntered.Marketing_Opt_In__c);
            isNewUserRegSuccessful = response.isSuccessful;
            if(!isNewUserRegSuccessful){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, response.errorMessage));
            }
        }catch(Exception e){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
        }
    }

    public boolean isResidential { 
        get {
            if (isResidential == null) isResidential = true;
            return isResidential;
        }
        set;
    }

    /* PRIVATE METHODS */
    private Billing_Account__c findBillingAccount(String accountNumber, String accountName){
        billAcctErrorMessage = null;
        Billing_Account__c temp;
        List<Billing_Account__c> billingAccountMatches = [Select id, Title__c, Initials__c, Account_Name__c, Customer__c, Customer__r.Name, Customer__r.RecordType.Name from Billing_Account__c where HiAF_Account_Number_Check_Digit__c = :accountNumber];

        System.debug('foobar');
        System.debug(billingAccountMatches);
        if(billingAccountMatches.isEmpty()) return null;
        for(Billing_Account__c billAcct: billingAccountMatches){
            if(getComparableString(accountName).equalsIgnoreCase(getComparableString(billAcct.Title__c)+getComparableString(billAcct.Initials__c)+getComparableString(billAcct.Account_Name__c))){
                if('Non-Residential Company Customer'.equals(billAcct.Customer__r.RecordType.Name)){
                    billAcctErrorMessage = 'Our system indicates that you are a Non-Residential Company Customer and it is not possible to register for online portal access via this form. Please see the information box above for instructions.';
                }else{
                    temp = billAcct;
                    break;
                }
            }
        }
        if(temp == null && billAcctErrorMessage == null){
            billAcctErrorMessage = 'The Customer Number or Customer Name you have entered does not match our records. Please enter the correct combination.';
        }
        return temp;
    }

    private static List<Contact> findContacts(Id customerId, String firstName, String lastName, String telNo, Date birthdate, String driverLicenceNo){
        List<Contact> matchedContacts = new List<Contact>();
        List<Account> customerMatches = [Select id, (Select id, FirstName, LastName, Phone, MobilePhone, OtherPhone, HomePhone, Birthdate, Drivers_License_Number__c from Contacts) from Account where id = :customerId];
        System.debug('hey');
        System.debug(customerMatches);
        for(Account cust: customerMatches ){
            List<Contact> contacts = cust.getSObjects('Contacts');
            if(contacts != null){
                for(Contact personContact :contacts ){
                    System.debug(personContact);
                    System.debug(firstName+lastName+telNo+driverLicenceNo);
                    System.debug(birthdate);
                    if((getComparableString(firstName)+getComparableString(lastName)).equalsIgnoreCase(getComparableString(personContact.FirstName)+getComparableString(personContact.LastName))){
                        System.debug('name matches');
                        Integer matchedAttributesNo = 0;
                        if(telNo!=null && getComparablePhoneNo(telNo).equalsIgnoreCase(getComparablePhoneNo(personContact.Phone))||
                                getComparablePhoneNo(telNo).equalsIgnoreCase(getComparablePhoneNo(personContact.MobilePhone))||
                                getComparablePhoneNo(telNo).equalsIgnoreCase(getComparablePhoneNo(personContact.OtherPhone))||
                                getComparablePhoneNo(telNo).equalsIgnoreCase(getComparablePhoneNo(personContact.HomePhone))
                                ){
                            matchedAttributesNo++;
                            system.debug('phone matches');
                        }
                        if(birthdate!=null && birthdate.daysBetween(personContact.Birthdate)==0){
                            matchedAttributesNo++;
                            system.debug('birthdate matches');
                        }
                        if(personContact.Drivers_License_Number__c != null && (getComparableString(driverLicenceNo).equalsIgnoreCase(getComparableString(personContact.Drivers_License_Number__c))
                            || personContact.Drivers_License_Number__c.split(' ')[0].equals(driverLicenceNo))){
                            matchedAttributesNo++;
                            system.debug('DL# matches');
                        }
                        if(matchedAttributesNo>=2){
                            system.debug('adding contact');
                            matchedContacts.add(personContact);
                        }
                    }
                }
            }
        }
        if(matchedContacts.size()==0){
            //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'The identification details you provided could not be verified. Please try again.'));
            return null;
        }return matchedContacts;
    }
    private static Contact getContactwithoutUser(List<Contact> relatedContacts){
        Contact temp;
        List<User> usersLinkedToMatchedContacts = [Select id, ContactId from User where contactId in :relatedContacts and isActive = true];
        Set<Id> contactIdsAlreadyHasUsers= new Set<Id>();
        for(User usrRec: usersLinkedToMatchedContacts ){
            contactIdsAlreadyHasUsers.add(usrRec.contactId);
        }
        for(Contact contactRec: relatedContacts){
            if(!contactIdsAlreadyHasUsers.contains(contactRec.id)){
                temp = contactRec;
                break;
            }
        }
        return temp;
    }

    private static String getComparableString(String str){
        if(str==null) return '';
        str = str.toLowerCase();
        str = str.replace(' ','');
        str = str.replace('[^a-zA-Z0-9]','');
        return str;
    }
    private static String getComparablePhoneNo(String str){
        if(str==null) return '';
        str = str.replace(' ','');
        str = str.replace('[^0-9]','');
        return str;
    }
    private static User setupNewUserToRegister(){
        User tempUsr = new User();
        return tempUsr;
    }
    
    /* TEST METHOD */
    public static testmethod void test_SiteNewPortalUserRegistrationController(){
        // create test data
        Account account = new Account();
        account.name = 'foo';
        RecordType rt = [Select id from RecordType where DeveloperName = 'Residential' and SobjectType = 'Account'];
        account.RecordTypeId = rt.id;
        insert account;

        Contact contact = new Contact();
        contact.LastName = 'Foo';
        contact.MobilePhone = '1234567';
        contact.AccountId = account.id;
        contact.Title = 'x';
        contact.Phone = 'x';
        contact.Email = 'x@x.com';
        contact.Birthdate = Date.today();
        insert contact;

        Property__c prop = new Property__c();
        prop.Universal_Id_c__c = 'sdgfsdgf';
        prop.Name = 'Test Property';
        insert prop;

        Billing_Account__c billAcc = new Billing_Account__c();
        billAcc.Name = 'asetwetwrt';
        billAcc.Title__c = 'dd';
        billAcc.Initials__c = 'fg';
        billAcc.Account_Name__c = 'hjy';
        billAcc.Same_Name_As_Customer__c = false;
        billAcc.Customer__c = account.id;
        billAcc.Property__c = prop.id;
        billAcc.HiAf_Account_Number__c = '9465494';
        billAcc.HiAf_Account_Number_Check_Digit__c = '9465494';
        insert billAcc;
        billAcc = [Select id, Title__c, Initials__c, Account_Name__c, HiAf_Account_Number_Check_Digit__c from Billing_Account__c where id = :billAcc.id];

        SiteNewPortalUserRegistrationController con = new SiteNewPortalUserRegistrationController();
        con.checkAccountAndContactDetails();
        con.isBypassreCAPTCHA= true;
        con.checkAccountAndContactDetails();
        con.accNumberEntryStr = billAcc.HiAf_Account_Number_Check_Digit__c ;
        con.accNameEntryStr = billAcc.Title__c+billAcc.Initials__c+billAcc.Account_Name__c;
        con.reCAPTCHA.challenge = con.reCAPTCHA.response = 'foo';
        con.checkAccountAndContactDetails();
        con.userLastNameEntryStr = 'Foo';
        con.userTelNoEntryStr = '1234567';
        con.newUserToRegister.HIDDEN_Birthdate__c = Date.today();
        con.reCAPTCHA.challenge = con.reCAPTCHA.response = 'foo';
        con.checkAccountAndContactDetails();
        con.prepareUserReg();
        con.newUserToRegister.Username = 'sdgfsdgf';
        con.userPasswordEntryStr = 'sdgfsdgf';
        con.userConfirmPasswordEntryStr = 'sdgfsdgf';
        con.newUserToRegister.email = 'fwerfw@sdgfwe.com';
        con.userConfirmEmailEntryStr = 'fwerfw@sdgfwe.com';
        con.newUserToRegister.Secret_Question__c = 'fswefwe';
        con.newUserToRegister.Secret_Answer__c = 'fswefwe';
        con.prepareUserReg();
        con.userPasswordEntryStr = 'passwordwdt';
        con.userConfirmPasswordEntryStr = 'passwordwdt';
        con.prepareUserReg();
        con.userPasswordEntryStr = 'sdgfsdfg45';
        con.userConfirmPasswordEntryStr = 'gfhjdf';
        con.prepareUserReg();
        con.userPasswordEntryStr = 'sdgfsdfg45';
        con.userConfirmPasswordEntryStr = 'sdgfsdfg45';
        con.prepareUserReg();
        con.isMarketingOptIn = false;
        con.submitNewUserReg();
        
        PortalUtil_WS.LogInfo wsli = new PortalUtil_WS.LogInfo();
        PortalUtil_WS.AllowFieldTruncationHeader_element afe = new PortalUtil_WS.AllowFieldTruncationHeader_element ();
        PortalUtil_WS.DebuggingHeader_element dhe = new PortalUtil_WS.DebuggingHeader_element();
        PortalUtil_WS.CallOptions_element coe = new PortalUtil_WS.CallOptions_element();
        PortalUtil_WS.DebuggingInfo_element die = new PortalUtil_WS.DebuggingInfo_element();
    }

}