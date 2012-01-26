/*
    Type:       Controller Extension
    Purpose:    Controls the matching person records search VF page

    Used By:    MatchingPersonRecordsSearch
    ---------------------------------------------------------------
    History:

    15-Sep-2011 J.Pe (Davanti Consulting)    Created

*/

public class MatchingPersonRecordsSearchExCon {

    /* PRIVATE PROPERTIES, VARIABLES */
    private ApexPages.StandardController stdCon;
    
    private Contact currentPerson{
        get{
            return (Contact) stdCon.getRecord();
        }
    }
    
    private Map<id, Contact> selectedPersonsMap{
        get{
            List<Contact> selectedPersons = (List<Contact>) stdSetCon.getSelected();
            Map<id, Contact> tempMap = new Map<id, Contact>(selectedPersons);
            return tempMap;
        }
    }
    
    /* PUBLIC PROPERTIES, VARIABLES */
    public ApexPages.StandardSetController stdSetCon {
        get{
            if (stdSetCon == null){
                if(searchStr!=null && !(''.equals(searchStr.trim())) && searchStr.length()>=2){
                    List<List<SObject>> searchResults;
                    if(currentPerson.DP_Key__c == null){
                        searchResults = [FIND :searchStr+'*' IN ALL FIELDS RETURNING CONTACT(id where id <> :currentPerson.id)];
                    }else{
                        searchResults = [FIND :searchStr+'*' IN ALL FIELDS RETURNING CONTACT(id where DP_Key__c <> :currentPerson.DP_Key__c and id <> :currentPerson.id)];
                    }
                    List<Contact> contactIds = (List<Contact>)searchResults[0];
                    if(contactIds.size()>0){
                        stdSetCon = new ApexPages.StandardSetController(Database.getQueryLocator([Select Name, AccountId, Account.Name, Email, Birthdate, 
                                      Drivers_License_Number__c, Preferred_Phone_Number__c, DP_Key__c, DP_Key__r.Name, MailingStreet, MailingCity, MailingState, MailingCountry, MailingPostalCode 
                                      from Contact where id in :contactIds]));
                    }
                }
                if(stdSetCon == null){
                    stdSetCon = new ApexPages.StandardSetController(new List<Contact>());
                }
                stdSetCon.setPageSize(20);
            }return stdSetCon;
        }private set;
    }
    
    public List<PersonWrapper> personWrapRecords{
        get{
            if(personWrapRecords!=null){
                List<Contact> selectedContacts = new List<Contact>();
                for(PersonWrapper personWrapRec: personWrapRecords){
                    if(personWrapRec.isSelected){
                        selectedContacts.add(personWrapRec.person);
                    }
                }
                stdSetCon.setSelected(selectedContacts);
            }
            personWrapRecords = new List<PersonWrapper>();
            List<Contact> personRecords = (List<Contact>) stdSetCon.getRecords();
            for(Contact personRec: personRecords){
                if(selectedPersonsMap.containsKey(personRec.id)){
                    personWrapRecords.add(new PersonWrapper(personRec, currentPerson.DP_Key__c, true));
                }else{
                    personWrapRecords.add(new PersonWrapper(personRec, currentPerson.DP_Key__c));
                }
            }return personWrapRecords;
        }private set;
    }
    
    public String searchStr{
        get;
        set{
            if (value==null||''.equals(value.trim())||value.length()<2){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Search field must have at least two characters.'));
            }
            searchStr = value;
        }
    }
    
    public String retURL{
        get{
            String temp = Apexpages.currentPage().getParameters().get('retURL');
            if (temp==null) temp = '/'+currentPerson.id;
            return temp;
        }
    }
    
    /* CONSTRUCTOR */
    public MatchingPersonRecordsSearchExCon(ApexPages.StandardController controller) {
        stdCon = controller;
        searchStr = currentPerson.Name;
    }   
    
    /* PUBLIC METHODS */
    public void search(){
        resetSearchResults();
    }
    
    public void linkSelectedRecords(){
        List<Contact> selectedPersons = getSelectedPersonsToLink();
        selectedPersons .add(currentPerson);
        // find all duplicate keys in list
        Id dupKeyId;
        for(Contact personR: selectedPersons){
            if(personR.DP_Key__c != null){
                if(dupKeyId == null){
                    dupKeyId = personR.DP_Key__c;
                }else if(dupKeyId != personR.DP_Key__c){
                    // if more than 1, error out
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'You cannot link person records who belong to multiple duplicate person key. Please delink the records first.'));
                    return;
                }
            }
        }
        // if none, create duplicate key
        Savepoint sp = Database.setSavepoint();
        try{
            if(dupKeyId == null){
                Duplicate_Person_Key__c dpKey = new Duplicate_Person_Key__c();
                insert dpKey ;
                dupKeyId = dpKey.id;
            }
            // link to all contacts
            List<Contact> personRecToUpdate = new List<Contact>();
            for(Contact personR: selectedPersons){
                if(personR.DP_Key__c != dupKeyId){
                    personR.DP_Key__c = dupKeyId;
                    personRecToUpdate.add(personR);
                }
            }
            update personRecToUpdate;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'Person records linked and updated successfully.'));
            resetSearchResults();
        }finally{
            return;
        }
    }
    
    public void selectAllRecords(){
        setSelectOnAllRecords(true);
    }
    public void unselectAllRecords(){
        setSelectOnAllRecords(false);
    }
    
    /* PRIVATE METHODS */
    private void setSelectOnAllRecords(boolean bool){
        for(PersonWrapper personW: personWrapRecords){
            personW.isSelected = bool;
        }
    }
    private void resetSearchResults(){
        if(!Test.isRunningTest()){
            stdCon.reset();
        }
        personWrapRecords = null;
        stdSetCon = null;
    }
    private List<Contact> getSelectedPersonsToLink(){
        List<PersonWrapper> temp = personWrapRecords;
        return selectedPersonsMap.values();
    }
    
    /* INNER CLASS */
    public class PersonWrapper{
        public Contact person{get;set;}
        public boolean isSelected{get;set;}
        public boolean isSelectable{get;set;}
        public Case personLink{
            get{
                return new Case(contactid = person.id);
            }
        }
        public PersonWrapper(Contact person, Id dupKeyIDToCompare){
            this(person,dupKeyIDToCompare, false);
        }
        public PersonWrapper(Contact person, Id dupKeyIDToCompare, boolean isSelected){
            this.person = person;
            this.isSelected = isSelected;
            if(dupKeyIDToCompare!= null && person.DP_Key__c != null && dupKeyIDToCompare != person.DP_Key__c){
                isSelectable = false;
            }else{
                isSelectable = true;
            }
        }
    }
    
    /* TEST METHOD */
    public static testmethod void test_MatchingPersonRecordsSearchExCon (){
        Duplicate_Person_Key__c key = new Duplicate_Person_Key__c();
        insert key;
        Contact con1 = new Contact(FirstName = 'test', LastName = 'test', Salutation = 'Mr', Birthdate = Date.today(),
            Drivers_License_Number__c = '235355', Email = 'sdfg@sdgs.com', Title = 'test', Department = 'test',
            Phone = '1234456', MobilePhone = '1234456', HomePhone = '1234456', OtherPhone = '1234456', Preferred_Contact_Type__c = 'Call',
            Preferred_Phone_Type__c = 'Home', /*Agent_s_Phone__c = '1234566', Agent_s_Name__c = 'test',*/ Mail_opt_out__c = true,
            MailingStreet = 'test', MailingCity = 'test', MailingState = 'test', MailingCountry = 'test', MailingPostalCode = '1234', Mailing_Address_DPID__c = '23453',
            OtherStreet = 'test', OtherCity = 'test', OtherState = 'test', OtherCountry = 'test', OtherPostalCode = '1234', Other_Address_DPID__c = '23453', DP_Key__c = key.id);
        insert con1;
        Contact con2 = new Contact(FirstName = 'test', LastName = 'test');
        insert con2;
        Test.setFixedSearchResults(new Id[]{con2.id});
        PageReference pageRef = Page.MatchingPersonRecordsSearch;
        pageRef.getParameters().put('id',con1.id);
        pageRef.getParameters().put('retURL','/'+con1.id);
        Test.setCurrentPage(pageRef);
        con1 = [Select Name, AccountId, Account.Name, Email, Birthdate, 
                                      Drivers_License_Number__c, Preferred_Phone_Number__c, DP_Key__c, DP_Key__r.Name, MailingStreet, MailingCity, MailingState, MailingCountry, MailingPostalCode 
                                      from Contact where id = :con1.id];
        Apexpages.StandardController stdCon = new Apexpages.StandardController(con1);
        MatchingPersonRecordsSearchExCon exCon = new MatchingPersonRecordsSearchExCon(stdCon);
        System.assertEquals(con1.Name, excon.searchStr);
        excon.search();
        System.assertNotEquals(0, excon.personWrapRecords.size());
        excon.personWrapRecords[0].isSelected = true;
        excon.unselectAllRecords();
        excon.selectAllRecords();        
        excon.linkSelectedRecords();
        con2 = [Select id, DP_Key__c from Contact where id = :con2.id];
        System.assertEquals(con1.DP_Key__c, con2.DP_Key__c);
        System.assertEquals('/'+con1.id, excon.retURL);
    }
}