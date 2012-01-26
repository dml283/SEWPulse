/*
    Type:       Controller Extension
    Purpose:    Controls the matching person records management VF page

    Used By:    MatchingPersonRecordsManagement
    ---------------------------------------------------------------
    History:

    14-Sep-2011 J.Pe (Davanti Consulting)    Created

*/
public class MatchingPersonRecordsMgmtExCon {

    /* PRIVATE PROPERTIES, VARIABLES */
    private ApexPages.StandardController stdCon;

    private Contact currentPerson{
        get{
            return (Contact) stdCon.getRecord();
        }
    }

    private List<String> fieldsNameToUpdate{
        get{
            List<String> temp = new List<String>();
            for(FieldWrapper fieldW: fieldsSelected){
                if(fieldW.hasChildFields){
                    for(FieldWrapper childFieldW: fieldW.childFields){
                        temp.add(childFieldW.devName);
                    }
                }else{
                    temp.add(fieldW.devName);
                }
            }
            return temp;
        }
    }

    /* PUBLIC PROPERTIES, VARIABLES */
    public List<FieldWrapper> fieldsAvailable{
        get{
            if(fieldsAvailable == null){
                fieldsAvailable = new List<FieldWrapper>();
                FieldWrapper nameFieldW = new FieldWrapper(Contact.Name.getDescribe());
                nameFieldW.childFields.add(new FieldWrapper(Contact.Salutation.getDescribe()));
                nameFieldW.childFields.add(new FieldWrapper(Contact.FirstName.getDescribe()));
                nameFieldW.childFields.add(new FieldWrapper(Contact.LastName.getDescribe()));
                fieldsAvailable.add(nameFieldW);
                fieldsAvailable.add(new FieldWrapper(Contact.Birthdate.getDescribe()));
                fieldsAvailable.add(new FieldWrapper(Contact.Drivers_License_Number__c.getDescribe()));
                fieldsAvailable.add(new FieldWrapper(Contact.Email.getDescribe()));
                fieldsAvailable.add(new FieldWrapper(Contact.Title.getDescribe()));
                fieldsAvailable.add(new FieldWrapper(Contact.Department.getDescribe()));
                fieldsAvailable.add(new FieldWrapper(Contact.Phone.getDescribe()));
                fieldsAvailable.add(new FieldWrapper(Contact.MobilePhone.getDescribe()));
                fieldsAvailable.add(new FieldWrapper(Contact.HomePhone.getDescribe()));
                fieldsAvailable.add(new FieldWrapper(Contact.OtherPhone.getDescribe()));
                FieldWrapper contactTypeFieldW = new FieldWrapper(Contact.Preferred_Contact_Type__c.getDescribe());
                contactTypeFieldW.childFields.add(new FieldWrapper(Contact.Preferred_Contact_Type__c.getDescribe()));
                contactTypeFieldW.childFields.add(new FieldWrapper(Contact.Preferred_Phone_Type__c.getDescribe()));
                fieldsAvailable.add(contactTypeFieldW);
                //fieldsAvailable.add(new FieldWrapper(Contact.Agent_s_Name__c.getDescribe()));
                //fieldsAvailable.add(new FieldWrapper(Contact.Agent_s_Name__c.getDescribe()));
                fieldsAvailable.add(new FieldWrapper(Contact.Mail_opt_out__c.getDescribe()));
                FieldWrapper mailingAddressFieldW = new FieldWrapper('Mailing Address', 'MailingAddress');
                mailingAddressFieldW.childFields.add(new FieldWrapper(Contact.MailingStreet.getDescribe()));
                mailingAddressFieldW.childFields.add(new FieldWrapper(Contact.MailingCity.getDescribe()));
                mailingAddressFieldW.childFields.add(new FieldWrapper(Contact.MailingState.getDescribe()));
                mailingAddressFieldW.childFields.add(new FieldWrapper(Contact.MailingPostalCode.getDescribe()));
                mailingAddressFieldW.childFields.add(new FieldWrapper(Contact.MailingCountry.getDescribe()));
                mailingAddressFieldW.childFields.add(new FieldWrapper(Contact.Mailing_Address_DPID__c.getDescribe()));
                fieldsAvailable.add(mailingAddressFieldW);
                FieldWrapper otherAddressFieldW = new FieldWrapper('Other Address', 'OtherAddress');
                otherAddressFieldW.childFields.add(new FieldWrapper(Contact.OtherStreet.getDescribe()));
                otherAddressFieldW.childFields.add(new FieldWrapper(Contact.OtherCity.getDescribe()));
                otherAddressFieldW.childFields.add(new FieldWrapper(Contact.OtherState.getDescribe()));
                otherAddressFieldW.childFields.add(new FieldWrapper(Contact.OtherPostalCode.getDescribe()));
                otherAddressFieldW.childFields.add(new FieldWrapper(Contact.OtherCountry.getDescribe()));
                otherAddressFieldW.childFields.add(new FieldWrapper(Contact.Other_Address_DPID__c.getDescribe()));
                fieldsAvailable.add(otherAddressFieldW);
            }return fieldsAvailable;
        }private set;
    }
    public List<FieldWrapper> fieldsSelected{
        get{
            List<FieldWrapper> temp = new List<FieldWrapper>();
            for(FieldWrapper fieldW: fieldsAvailable){
                if(fieldW.isSelected){
                    temp.add(fieldW);
                }
            }return temp;
        }
    }
    public String fieldsSelectedStr{
        get{
            String temp = '';
            for(FieldWrapper fieldW: fieldsSelected){
                temp += ', '+fieldW.label;
            }
            if(temp.length()==0) return 'NONE';
            return temp.substring(2,temp.length());
        }
    }

    public List<DuplicateRecordWrapper> duplicateRecords{
        get{
            if(duplicateRecords==null){
                if(currentPerson.DP_Key__c == null) return null;
                duplicateRecords = new List<DuplicateRecordWrapper>();
                List<Contact> duplicatePersons = [Select id, Name, FirstName, LastName, Salutation, AccountId, Account.Name, Birthdate,
                                                         Drivers_License_Number__c, Email, Title, Department, Phone, Preferred_Phone_Number__c,
                                                         MobilePhone, HomePhone, OtherPhone, Preferred_Contact_Type__c, Preferred_Phone_Type__c,
                                                         /*Agent_s_Phone__c, Agent_s_Name__c,*/ Mail_opt_out__c, MailingStreet, MailingCity, MailingState,
                                                         MailingPostalCode, MailingCountry, Mailing_Address_DPID__c, OtherStreet, OtherCity, OtherState,
                                                         OtherPostalCode, OtherCountry, Other_Address_DPID__c from Contact where DP_Key__c = :currentPerson.DP_Key__c
                                                         and id <> :currentPerson.id];
                for(Contact con: duplicatePersons){
                    duplicateRecords.add(new DuplicateRecordWrapper(con));
                }
            }return duplicateRecords;
        }private set;
    }
    public List<DuplicateRecordWrapper> duplicateRecordsSelected{
        get{
            List<DuplicateRecordWrapper> temp = new List<DuplicateRecordWrapper>();
            for(DuplicateRecordWrapper dupRecW: duplicateRecords){
                if(dupRecW.isSelected){
                    temp.add(dupRecW);
                }
            }return temp;
        }
    }

    public String retURL{
        get{
            String temp = Apexpages.currentPage().getParameters().get('retURL');
            if (temp==null) temp = '/'+currentPerson.id;
            return temp;
        }
    }

    public Id delinkPersonId{get;set;}

    /* CONSTRUCTOR */
    public MatchingPersonRecordsMgmtExCon(ApexPages.StandardController controller) {
        stdCon = controller;
    }

    /* PUBLIC METHODS */
    public void copyInfoToSelectedDupRecords(){
        List<Contact> personRecsToUpdate = new List<Contact>();
        // map of sObject fields for contact
        Map<String, Schema.SObjectField> contactFieldsMap = Schema.SObjectType.Contact.fields.getMap();

        for(DuplicateRecordWrapper dupRecW: duplicateRecordsSelected){
            personRecsToUpdate.add(dupRecW.person);
        }
        for(Contact personRec: personRecsToUpdate){
            for(String fieldName : fieldsNameToUpdate){
                Schema.DisplayType fieldType = contactFieldsMap.get(fieldName).getDescribe().getType();
                if (fieldType == Schema.DisplayType.Email ||
                        fieldType == Schema.Displaytype.MultiPicklist ||
                        fieldType == Schema.Displaytype.Picklist ||
                        fieldType == Schema.Displaytype.String ||
                        fieldType == Schema.Displaytype.TextArea  ||
                        fieldType == Schema.Displaytype.URL ||
                        fieldType == Schema.Displaytype.Phone ||
                        fieldType == Schema.Displaytype.Combobox
                        )
                    personRec.put(fieldName, (String)currentPerson.get(fieldName));
                else if (fieldType == Schema.Displaytype.Date)
                    personRec.put(fieldName, (Date)currentPerson.get(fieldName));
                else if (fieldType == Schema.Displaytype.Datetime)
                    personRec.put(fieldName, (DateTime)currentPerson.get(fieldName));
                else if (fieldType == Schema.Displaytype.Double ||
                            fieldType == Schema.Displaytype.Currency ||
                            fieldType == Schema.Displaytype.Percent)
                    personRec.put(fieldName, (Double)currentPerson.get(fieldName));
                else if (fieldType == Schema.Displaytype.ID ||
                            fieldType == Schema.Displaytype.Reference)
                    personRec.put(fieldName, (ID)currentPerson.get(fieldName));
                else if (fieldType == Schema.Displaytype.Boolean)
                    personRec.put(fieldName, (Boolean)currentPerson.get(fieldName));
                else if (fieldType == Schema.Displaytype.Integer)
                    personRec.put(fieldName, (Integer)currentPerson.get(fieldName));
            }
        }
        try{
            update personRecsToUpdate;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'Person information has been copied to selected duplicate records.'));
            duplicateRecords = null;
        }finally{
            return;
        }
    }

    public void delinkChosenPerson(){
        for(Integer i = 0 ; i < duplicateRecords.size() ; i++){
            DuplicateRecordWrapper dupRecW = duplicateRecords[i];
            if(dupRecW.person.id == delinkPersonId){
                dupRecW.person.DP_Key__c = null;
                update dupRecW.person;
                duplicateRecords.remove(i);
                return;
            }
        }
    }

    public void selectAllDuplRecords(){
        setSelectOnAllDuplRecords(true);
    }
    public void unselectAllDuplRecords(){
        setSelectOnAllDuplRecords(false);
    }
    public void selectAllFieldsAvailable(){
        setSelectOnAllFieldsAvailable(true);
    }
    public void unselectAllFieldsAvailable(){
        setSelectOnAllFieldsAvailable(false);
    }
    
    /* PRIVATE METHODS */
    private void setSelectOnAllDuplRecords(boolean bool){
        for(DuplicateRecordWrapper duplRec: duplicateRecords){
            duplRec.isSelected = bool;
        }
    }
    private void setSelectOnAllFieldsAvailable(boolean bool){
        for(FieldWrapper fieldW: fieldsAvailable){
            fieldW.isSelected = bool;
        }
    }

    /* INNER CLASS */
    public class DuplicateRecordWrapper{
        public boolean isSelected{
            get{
                if(isSelected==null){
                    isSelected = false;
                }return isSelected;
            }set;
        }
        public Contact person{get;set;}
        public Case personLink{
            get{
                return new Case(contactid = person.id);
            }
        }
        public DuplicateRecordWrapper(Contact person){
            this.person = person;
        }
    }
    public class FieldWrapper{
        public boolean isSelected{
            get{
                if(isSelected==null){
                    isSelected = false;
                }return isSelected;
            }set;
        }
        public String label{get; private set;}
        public String devName{get; private set;}
        public FieldWrapper(Schema.DescribeFieldResult fieldDescribe){
            this.label = fieldDescribe.getLabel();
            this.devName = fieldDescribe.getName();
        }
        public FieldWrapper(String label, string devName){
            this.label = label;
            this.devName = devName;
        }
        public List<FieldWrapper> childFields{
            get{
                if(childFields==null){
                    childFields = new List<FieldWrapper>();
                }return childFields;
            }private set;
        }
        public boolean hasChildFields{
            get{
                return childFields.size()>0;
            }
        }
    }
    
    /* TEST METHOD */
    public static testmethod void test_MatchingPersonRecordsMgmtExCon(){
        Duplicate_Person_Key__c key = new Duplicate_Person_Key__c();
        insert key;
        Contact con1 = new Contact(FirstName = 'test',LastName = 'test', Salutation = 'Mr', Birthdate = Date.today(),
            Drivers_License_Number__c = '235355', Email = 'sdfg@sdgs.com', Title = 'test', Department = 'test',
            Phone = '1234456', MobilePhone = '1234456', HomePhone = '1234456', OtherPhone = '1234456', Preferred_Contact_Type__c = 'Call',
            Preferred_Phone_Type__c = 'Home', /*Agent_s_Phone__c = '1234566', Agent_s_Name__c = 'test',*/ Mail_opt_out__c = true,
            MailingStreet = 'test', MailingCity = 'test', MailingState = 'test', MailingCountry = 'test', MailingPostalCode = '1234', Mailing_Address_DPID__c = '23453',
            OtherStreet = 'test', OtherCity = 'test', OtherState = 'test', OtherCountry = 'test', OtherPostalCode = '1234', Other_Address_DPID__c = '23453', DP_Key__c = key.id);
        insert con1;
        Contact con2 = new Contact(LastName = 'crap', DP_Key__c = key.id);
        insert con2;
        PageReference pageRef = Page.MatchingPersonRecordsManagement;
        pageRef.getParameters().put('id',con1.id);
        pageRef.getParameters().put('retURL','/'+con1.id);
        Test.setCurrentPage(pageRef);
        Apexpages.StandardController stdCon = new Apexpages.StandardController(con1);
        MatchingPersonRecordsMgmtExCon exCon = new MatchingPersonRecordsMgmtExCon(stdCon);
        exCon.unselectAllFieldsAvailable();
        System.assertEquals('NONE',exCon.fieldsSelectedStr);
        exCon.selectAllFieldsAvailable();
        System.assertNotEquals('NONE',exCon.fieldsSelectedStr);
        exCon.unselectAllDuplRecords();
        System.assertEquals(0,exCon.duplicateRecordsSelected.size());
        exCon.selectAllDuplRecords();
        System.assertEquals(1,exCon.duplicateRecordsSelected.size());
        exCon.copyInfoToSelectedDupRecords();
        con2 = [Select id, Name, FirstName, LastName, Salutation, AccountId, Account.Name, Birthdate,
                     Drivers_License_Number__c, Email, Title, Department, Phone,
                     MobilePhone, HomePhone, OtherPhone, Preferred_Contact_Type__c, Preferred_Phone_Type__c,
                     /*Agent_s_Phone__c, Agent_s_Name__c,*/ Mail_opt_out__c, MailingStreet, MailingCity, MailingState,
                     MailingPostalCode, MailingCountry, Mailing_Address_DPID__c, OtherStreet, OtherCity, OtherState,
                     OtherPostalCode, OtherCountry, Other_Address_DPID__c from Contact where id = :con2.id];
        System.assertEquals(con1.FirstName, con2.FirstName);
        System.assertEquals(con1.LastName, con2.LastName);
        System.assertEquals(con1.Salutation, con2.Salutation);
        System.assertEquals(con1.Birthdate, con2.Birthdate);
        System.assertEquals(con1.Drivers_License_Number__c, con2.Drivers_License_Number__c);
        System.assertEquals(con1.Email, con2.Email);
        System.assertEquals(con1.Title, con2.Title);
        System.assertEquals(con1.Department, con2.Department);
        System.assertEquals(con1.Phone, con2.Phone);
        System.assertEquals(con1.MobilePhone, con2.MobilePhone);
        System.assertEquals(con1.HomePhone, con2.HomePhone);
        System.assertEquals(con1.OtherPhone, con2.OtherPhone);
        System.assertEquals(con1.Preferred_Contact_Type__c, con2.Preferred_Contact_Type__c);
        System.assertEquals(con1.Preferred_Phone_Type__c, con2.Preferred_Phone_Type__c);
        //System.assertEquals(con1.Agent_s_Phone__c, con2.Agent_s_Phone__c);
        //System.assertEquals(con1.Agent_s_Name__c, con2.Agent_s_Name__c);
        System.assertEquals(con1.Mail_opt_out__c, con2.Mail_opt_out__c);
        System.assertEquals(con1.MailingStreet, con2.MailingStreet);
        System.assertEquals(con1.MailingCity, con2.MailingCity);
        System.assertEquals(con1.MailingState, con2.MailingState);
        System.assertEquals(con1.MailingPostalCode, con2.MailingPostalCode);
        System.assertEquals(con1.MailingCountry, con2.MailingCountry);
        System.assertEquals(con1.Mailing_Address_DPID__c, con2.Mailing_Address_DPID__c);
        System.assertEquals(con1.OtherStreet, con2.OtherStreet);
        System.assertEquals(con1.OtherCity, con2.OtherCity);
        System.assertEquals(con1.OtherState, con2.OtherState);
        System.assertEquals(con1.OtherPostalCode, con2.OtherPostalCode);
        System.assertEquals(con1.OtherCountry, con2.OtherCountry);
        System.assertEquals(con1.Other_Address_DPID__c , con2.Other_Address_DPID__c );
        String tempStr = excon.retURL;
        excon.delinkPersonId = con2.id;
        excon.delinkChosenPerson();
        con2 = [Select id, DP_Key__c from Contact where id = :con2.id];
        System.assertNotEquals(con1.DP_Key__c , con2.DP_Key__c );
    }
}