/*
    Type:       Controller Extension
    Purpose:    Controls the Manage_Concession and Delete_Concession VF pages

    Used By:    Manage Concession, Delete Concession
    ---------------------------------------------------------------
    History:

    13-Sep-2011 L.Tan (Coretec Solutions)    Created

*/
public without sharing class ConcessionExCon {
    public Case cse {get;set;}
    public Billing_Account__c bAcc {get;set;}
    public Account customer {get;set;}
    public Contact person {get;set;}
    public Boolean bPropAddr {get;set;}
    public Boolean bBillAddr {get;set;}
    public class ValidationException extends Exception {}
    
    public boolean isSubmitSuccessful{
        get{
            if (isSubmitSuccessful==null){
                isSubmitSuccessful = false;
            }return isSubmitSuccessful ;
        }
        set;
    }

    /* CONSTRUCTOR */
    public ConcessionExCon(ApexPages.StandardController controller) {
        //stdCon = controller;
        cse = (Case) controller.getRecord();

        if (cse != null && cse.id != null) {
            cse = [Select c.Information_Int_Long__c, c.Alerts_Int_Long__c,
                      c.CaseNumber, c.RecordTypeId, c.Billing_Account__c, c.AccountId, c.Account.Name, c.ContactId, c.Contact.Name, c.Id, c.Contact_Person_Name__c,
                      c.Privacy_Statement__c, c.Concession_Holder__c, c.Concession_Card_Type__c, c.Concession_Card_Number__c, c.Concession_Card_Lastname__c, c.Concession_Card_Firstname__c,
                      c.Received_Evidence_of_Responsibility__c, c.Authority_to_Transact__c, c.Received_Application_Form__c, c.Send_Application_Form__c, c.Send_Application_Form_To__c,
                      c.Concession_Evidence__c, c.Concession_Customer_Type__c, c.Concession_Contact_Point__c, c.Send_Confirmation_Letter__c, c.Print_Bill__c,
                      c.Rebilled_Amount__c, c.Rebilled_Date__c, delete_reason__c
               From case c where Id = :cse.id];

            PopulateBillingAccount(cse.Billing_Account__c);

/*          bAcc = [Select b.Name, b.HiAF_Account_Number__c,  b.Property__c, b.Property__r.Name, b.Property__r.Street_Address__c, b.Property__r.Suburb__c, b.Property__r.State__c, b.Property__r.Postal_Code__c,
                       b.Street_Address__c, b.Status__c, b.State__c, b.Postal_Code__c, b.Country__c, b.City__c,
                       b.Concession_Holder__c, b.Card_Type__c, b.Concession_Number__c,
                       b.Card_Lastname__c, b.Card_Firstname__c, b.Concession_Start_Date__c, b.Concession_End_Date__c
                From Billing_Account__c b where b.id = :cse.Billing_Account__c]; */
        } else {

            Id ConcessionRecordTypeId = [Select id, DeveloperName, Name from RecordType where SobjectType = 'Case' and DeveloperName='Concession'][0].Id;

            cse = new Case(RecordTypeId = ConcessionRecordTypeId);

            Id bAcctId = ApexPages.currentPage().getParameters().get('billAcctId');
            Id customerId = ApexPages.currentPage().getParameters().get('customerId');
            cse.AccountId = customerId;
            cse.Billing_Account__c = bAcctId;
            System.debug(bAcctId);
            PopulateBillingAccount(bAcctId);

        }

    } // end constructor

    // selects the account
    public PageReference SelectAccount() {
        PopulateBillingAccount(cse.Billing_Account__c);
        return null;
    }

    public PageReference submitAppForm() {
        try {
            resetInfoAndAlerts();
            if (bPropAddr) cse.Send_Application_Form_To__c='Property Address';
            if (bBillAddr) cse.Send_Application_Form_To__c='Billing Account Address';

            // call ws
            WSUtil_Concession ws = new WSUtil_Concession();
            ws.concessionUpdate(cse, bAcc.HiAF_Account_Number__c);
            WSUtil_Concession.ConcessionUpdateResponse response = ws.concessionResponse;

            // update case
            cse.Status = 'Closed';
            updateCaseAlertInfo(cse, response.errors);

            upsert (cse);

        } catch (System.CalloutException ex){       // SOAP Error
            ApexPages.addmessage(
                new ApexPages.message(ApexPages.severity.ERROR,'Problem with web service - please contact system administrator. Error message:'+ex.getMessage())
            );
            return null;

        } catch (WSUtil.MultipleWebServiceBusinessException e) { // Error return from webservice - Business level
            updateCaseAlertInfo(cse, e.multiEx);
            upsert(cse);
            return new PageReference('/' + cse.id);

        } catch (Exception e) {
            ApexPages.addmessages(e);
            return null;

        }
        return new PageReference('/' + cse.id);
    } // end submitAppForm

    public PageReference submitConcession() {
        try {
            
            resetInfoAndAlerts();

            System.debug('foofar');

            if (!cse.Privacy_Statement__c) {    //privacy statement must be checked.
                throw new ValidationException('Privacy statement must be read out and accepted by the customer to proceed.');
            }

            // call ws
            WSUtil_Concession ws = new WSUtil_Concession();
            boolean success = ws.concessionUpdate(cse, bAcc.HiAF_Account_Number__c);
            WSUtil_Concession.ConcessionUpdateResponse response = ws.concessionResponse;



            // update case
            cse.Valid_Concession__c = success; //response.ValidConcession;
            cse.Rebilled__c = response.Rebilled;
            cse.Rebilled_Amount__c = Decimal.valueOf(response.RebillAmount);
            cse.Rebilled_Date__c = Date.today();
            cse.Status = 'Closed';
            updateCaseAlertInfo(cse, response.errors);
            upsert(cse);

            // update Billing Account
            bAcc.Valid_Concession__c = cse.Valid_Concession__c;
            bAcc.Concession_Holder__c = cse.Concession_Holder__c;
            bAcc.Concession_Number__c = cse.Concession_Card_Number__c;
            bAcc.Card_Type__c = cse.Concession_Card_Type__c;
            bAcc.Card_Firstname__c = cse.Concession_Card_Firstname__c;
            bAcc.Card_Lastname__c = cse.Concession_Card_Lastname__c;
            bAcc.Concession_Start_Date__c = system.today();
            bAcc.Concession_End_Date__c = null;
            update(bAcc);

        } catch (System.CalloutException ex){       // SOAP Error
            ApexPages.addmessage(
                new ApexPages.message(ApexPages.severity.ERROR,'Problem with web service - please contact system administrator. Error message:'+ex.getMessage())
            );
            isSubmitSuccessful = false;
            return null;

        } catch (WSUtil.MultipleWebServiceBusinessException e) { // Error return from webservice - Business level
            updateCaseAlertInfo(cse, e.multiEx);
            upsert(cse);
            if(cse.Status == 'Follow up Required') isSubmitSuccessful = false;
            else isSubmitSuccessful = true;
            return new PageReference('/' + cse.id);

        } catch (Exception e) {
            ApexPages.addmessages(e);
            isSubmitSuccessful = false;
            return null;

        }
        isSubmitSuccessful = true;
        return new PageReference('/' + cse.id);
    } // end submitConcession
    

    public PageReference CloseCase() {
        try {
            resetInfoAndAlerts();
            // call ws

            // update case
            cse.Status = 'Closed';
            update(cse);

        } catch (Exception e) {
            ApexPages.addmessages(e);
            return null;

        }
        return new PageReference('/' + cse.id);
    } //end CloseCase

    public PageReference deleteConcession() {
        try {
            resetInfoAndAlerts();
            cse.Concession_Card_Firstname__c = bAcc.Card_Firstname__c;
            cse.Concession_Card_Lastname__c = bAcc.Card_Lastname__c;
            cse.Concession_Card_Number__c = bAcc.Concession_Number__c;
            cse.Category_Level_1__c = 'Customer Details';
            cse.Category_Level_2__c = 'Concession';
            cse.Category_Level_3__c = 'Delete Concession';
            cse.Mode__c = 'Action';

            // call ws
            WSUtil_Concession ws = new WSUtil_Concession();
            ws.concessionUpdate(cse, bAcc.HiAF_Account_Number__c);
            WSUtil_Concession.ConcessionUpdateResponse response = ws.concessionResponse;

            // thl: what is the response if it is a delete, what else do we need to update?
            // update case
            cse.Status = 'Closed';
            updateCaseAlertInfo(cse, response.errors);
            update (cse);

            bAcc.Concession_End_Date__c = System.today();
            bAcc.Valid_Concession__c = false;
            update(bAcc);


        } catch (System.CalloutException ex){       // SOAP Error
            ApexPages.addmessage(
                new ApexPages.message(ApexPages.severity.ERROR,'Problem with web service - please contact system administrator. Error message:'+ex.getMessage())
            );
            isSubmitSuccessful = false;
            return null;

        } catch (WSUtil.MultipleWebServiceBusinessException e) { // Error return from webservice - Business level
            updateCaseAlertInfo(cse, e.multiEx);
            update(cse);
            if(cse.Status == 'Follow up Required') isSubmitSuccessful = false;
            else isSubmitSuccessful = true;
            return new PageReference('/' + cse.id);

        } catch (Exception e) {
            ApexPages.addmessages(e);
            isSubmitSuccessful = false;
            return null;

        }
        isSubmitSuccessful = true;
        return new PageReference('/' + cse.id);
    } // delete Concession

    private void PopulateBillingAccount(Id bAcctId) {
        if (bAcctId != null)
            bAcc = [Select b.Name, b.HiAF_Account_Number__c,  b.Property__c, b.Property__r.Name, b.Property__r.Street_Address__c, b.Property__r.Suburb__c, b.Property__r.State__c, b.Property__r.Postal_Code__c,
                       b.Street_Address__c, b.Status__c, b.State__c, b.Postal_Code__c, b.Country__c, b.City__c,
                       b.Concession_Holder__c, b.Card_Type__c, b.Concession_Number__c,
                       b.Card_Lastname__c, b.Card_Firstname__c, b.Concession_Start_Date__c, b.Concession_End_Date__c
                From Billing_Account__c b where b.id = :bAcctId];
        else
            bAcc = new Billing_Account__c();
    
    }

    private void updateCaseAlertInfo(Case cse, List<WSUtil.SingleWebServiceBusinessException > errors){
        /*
        for (WSUtil.SingleWebServiceBusinessException err: errors) {
            if (Integer.valueOf(err.ErrorSeverity) > 2) {
                cse.Alerts_Int_Long__c = err.ErrorSeverity + ' - ' + err.ErrorCode + ' - ' + err.getMessage();
                cse.Status = 'Follow up Required';
            } else {
                cse.Information_Int_Long__c = err.ErrorSeverity + ' - ' + err.ErrorCode + ' - ' + err.getMessage();
                cse.Status = 'Closed';
            }
        }
        */
        boolean hasErrorSeverity = false;
        for (WSUtil.SingleWebServiceBusinessException err: errors) {
            if (Integer.valueOf(err.ErrorSeverity) > 2) {
                cse.Alerts_Int_Long__c += err.ErrorSeverity + ' - ' + err.ErrorCode + ' - ' + err.getMessage()+'\n';
                ApexPages.addmessage(
                    new ApexPages.message(ApexPages.severity.ERROR,err.getMessageByUserType())
                );
                hasErrorSeverity = true;
            } else {
                cse.Information_Int_Long__c += err.ErrorSeverity + ' - ' + err.ErrorCode + ' - ' + err.getMessage()+'\n';
                ApexPages.addmessage(
                    new ApexPages.message(ApexPages.severity.INFO,err.getMessageByUserType())
                );
            }        
        }
        if(hasErrorSeverity){
            cse.Status = 'Follow up Required';
        }else{
            cse.Status = 'Closed';
        }
    }
    private void resetInfoAndAlerts(){
        cse.Information_Int_Long__c = '';
        cse.Alerts_Int_Long__c = '';
        cse.Valid_Concession__c=false;
        cse.Rebilled__c=false;
        cse.Rebilled_Amount__c=null;
        cse.Rebilled_Date__c=null;
        // clear irrelavent fields
        if (cse.Concession_Holder__c == 'Account Holder') {
            cse.Concession_Evidence__c=null;
            cse.Concession_Customer_Type__c=null;
            cse.Concession_Contact_Point__c=null;
            cse.Contact_Person_Name__c=null;
            cse.Authority_to_Transact__c=null;
            cse.Received_Application_Form__c=null;
            cse.Received_Evidence_of_Responsibility__c=null;
            cse.Send_Application_Form__c=null;
            cse.Send_Application_Form_To__c=null;
        }
        if (cse.Concession_Holder__c == 'A/C Holder Partner') {
            if (cse.Authority_to_Transact__c == 'No') {
                cse.Privacy_Statement__c=false;
                cse.Send_Confirmation_Letter__c=false;
                cse.Concession_Card_Number__c=null;
                cse.Concession_Card_Firstname__c=null;
                cse.Concession_Card_Lastname__c=null;
                cse.Concession_Card_Type__c=null;
                cse.Concession_Evidence__c=null;
                cse.Concession_Customer_Type__c=null;
                cse.Concession_Contact_Point__c=null;
                cse.Contact_Person_Name__c=null;
                cse.Received_Application_Form__c=null;
                cse.Received_Evidence_of_Responsibility__c=null;
                cse.Send_Application_Form__c=null;
                cse.Send_Application_Form_To__c=null;
            } else {
                cse.Concession_Evidence__c=null;
                cse.Concession_Customer_Type__c=null;
                cse.Concession_Contact_Point__c=null;
                cse.Contact_Person_Name__c=null;
                cse.Received_Application_Form__c=null;
                cse.Received_Evidence_of_Responsibility__c=null;
                cse.Send_Application_Form__c=null;
                cse.Send_Application_Form_To__c=null;
            }
        }
        if (cse.Concession_Holder__c == 'Third Party') {
            if (cse.Received_Application_Form__c == 'Yes') {
                cse.Contact_Person_Name__c=null;
                cse.Authority_to_Transact__c=null;
                cse.Received_Evidence_of_Responsibility__c=null;
                cse.Send_Application_Form__c=null;
                cse.Send_Application_Form_To__c=null;
            } else {
                If (cse.Received_Evidence_of_Responsibility__c == 'Yes') {
                    cse.Concession_Evidence__c=null;
                    cse.Concession_Customer_Type__c=null;
                    cse.Concession_Contact_Point__c=null;
                    cse.Contact_Person_Name__c=null;
                    cse.Authority_to_Transact__c=null;
                    cse.Send_Application_Form__c=null;
                    cse.Send_Application_Form_To__c=null;
                } else {
                    cse.Privacy_Statement__c=false;
                    cse.Send_Confirmation_Letter__c=false;
                    cse.Concession_Card_Number__c=null;
                    cse.Concession_Card_Firstname__c=null;
                    cse.Concession_Card_Lastname__c=null;
                    cse.Concession_Card_Type__c=null;
                    cse.Concession_Evidence__c=null;
                    cse.Concession_Customer_Type__c=null;
                    cse.Concession_Contact_Point__c=null;
                    cse.Authority_to_Transact__c=null;
                }
            }
        }
    } // end resetInfoAndAlerts

     /* Test Method */
    public static testmethod void test_ConcessionExConAcctHolder(){

        Account acc = new Account(name='test parent');
        insert acc;
        Billing_Account__c ba = new Billing_Account__c(name='test', customer__c=acc.Id, HiAF_Account_Number__c='1234');
        insert ba;

        // concession senarios
        Case c = new Case(account=acc, Billing_Account__c=ba.Id);
        insert c;

        // get custom settings, update if already there
        SystemSettings__c cs;
        try {
            cs = [select id, setupOwnerId, Disable_Web_Services__c from SystemSettings__c limit 1];
        } catch (QueryException e) {
            cs = new SystemSettings__c();
            insert cs;
        }

        ApexPages.StandardController con = new ApexPages.StandardController(c);
        ConcessionExCon excon = new ConcessionExCon(con);

        excon.submitConcession();   // privacy statement = false
        System.assertEquals(true, ApexPages.hasMessages());

        // concession senarios - Account Holder
        c.Concession_Holder__c = 'Account Holder';
        c.Privacy_Statement__c = true;
        update c;
        con = new ApexPages.StandardController(c);
        excon = new ConcessionExCon(con);
        excon.submitConcession();

        Case cse = [select Valid_Concession__c from Case where Id = :c.Id];
        System.assert(cse.Valid_Concession__c);

        // test submitConcession exception
        cs.Disable_Web_Services__c = true;
        update cs;
        excon.submitConcession();

        cs.Disable_Web_Services__c = false;
        update cs;

    }

    public static testmethod void test_ConcessionExConAcctHolderPartner(){

        Account acc = new Account(name='test parent');
        insert acc;
        Billing_Account__c ba = new Billing_Account__c(name='test', customer__c=acc.Id, HiAF_Account_Number__c='1234');
        insert ba;

        // concession senarios
        Case c = new Case(account=acc, Billing_Account__c=ba.Id);
        // concession senarios - A/C Holder Partner
        c.Concession_Holder__c = 'A/C Holder Partner';
        c.Privacy_Statement__c = true;
        insert c;

        // get custom settings, update if already there
        SystemSettings__c cs;
        try {
            cs = [select id, setupOwnerId, Disable_Web_Services__c from SystemSettings__c limit 1];
        } catch (QueryException e) {
            cs = new SystemSettings__c();
            insert cs;
        }

        ApexPages.StandardController con = new ApexPages.StandardController(c);
        ConcessionExCon excon = new ConcessionExCon(con);

        excon.submitConcession();
        Case cse = [select Valid_Concession__c from Case where Id = :c.Id];
        System.assert(cse.Valid_Concession__c);

        // concession senario - A/C Holder Partner, no authority to transact
        c.Authority_to_Transact__c = 'No';
        update c;
        con = new ApexPages.StandardController(c);
        excon = new ConcessionExCon(con);
        excon.CloseCase();
        cse = [select Valid_Concession__c from Case where Id = :c.Id];
        System.assert(!cse.Valid_Concession__c);

    }

    public static testmethod void test_ConcessionExConThirdParty(){

        Account acc = new Account(name='test parent');
        insert acc;
        Billing_Account__c ba = new Billing_Account__c(name='test', customer__c=acc.Id, HiAF_Account_Number__c='1234');
        insert ba;

        // concession senarios
        Case c = new Case(account=acc, Billing_Account__c=ba.Id);
        // concession senario - Third Party, received application form, submit concession
        c.Concession_Holder__c = 'Third Party';
        c.Received_Application_Form__c = 'Yes';
        c.Privacy_Statement__c = true;
        insert c;

        // get custom settings, update if already there
        SystemSettings__c cs;
        try {
            cs = [select id, setupOwnerId, Disable_Web_Services__c from SystemSettings__c limit 1];
        } catch (QueryException e) {
            cs = new SystemSettings__c();
            insert cs;
        }

        ApexPages.StandardController con = new ApexPages.StandardController(c);
        ConcessionExCon excon = new ConcessionExCon(con);

        excon.submitConcession();
        Case cse = [select Valid_Concession__c, Information_Int_Long__c, Alerts_Int_Long__c from Case where Id = :c.Id];

        System.assert(cse.Valid_Concession__c);
        // concession senario - Third Party, submit concession
        c.Concession_Holder__c = 'Third Party';
        c.Received_Application_Form__c = 'No';
        c.Received_Evidence_of_Responsibility__c = 'Yes';
        c.Privacy_Statement__c = true;
        update c;
        con = new ApexPages.StandardController(c);
        excon = new ConcessionExCon(con);
        excon.submitConcession();
        cse = [select Valid_Concession__c from Case where Id = :c.Id];
        System.assert(cse.Valid_Concession__c);

        // concession senario - Third Party, send application form, billing account address
        c.Concession_Holder__c = 'Third Party';
        c.Received_Application_Form__c = 'No';
        c.Received_Evidence_of_Responsibility__c = 'No';
        c.Send_Application_Form__c = 'Yes';
        update c;
        con = new ApexPages.StandardController(c);
        excon = new ConcessionExCon(con);
        excon.bBillAddr = true;
        excon.bPropAddr = false;
        excon.submitAppForm();
        cse = [select Valid_Concession__c from Case where Id = :c.Id];
        System.assert(!cse.Valid_Concession__c);
        // concession senario - Third Party, send application form, property address
        c.Concession_Holder__c = 'Third Party';
        c.Received_Application_Form__c = 'No';
        c.Received_Evidence_of_Responsibility__c = 'No';
        c.Send_Application_Form__c = 'Yes';
        update c;
        con = new ApexPages.StandardController(c);
        excon = new ConcessionExCon(con);
        excon.bPropAddr = true;
        excon.bBillAddr = false;
        excon.submitAppForm();
        cse = [select Valid_Concession__c from Case where Id = :c.Id];
        System.assert(!cse.Valid_Concession__c);
        // test submitAppForm exception
        cs.Disable_Web_Services__c = true;
        update cs;
        excon.submitAppForm();

        cs.Disable_Web_Services__c = false;
        update cs;
    }

    public static testmethod void test_ConcessionExConOther(){

        Account acc = new Account(name='test parent');
        insert acc;
        Billing_Account__c ba = new Billing_Account__c(name='test', customer__c=acc.Id, HiAF_Account_Number__c='1234');
        insert ba;

        // concession senarios
        Case c = new Case(account=acc, Billing_Account__c=ba.Id);
        insert c;

        // get custom settings, update if already there
        SystemSettings__c cs;
        try {
            cs = [select id, setupOwnerId, Disable_Web_Services__c from SystemSettings__c limit 1];
        } catch (QueryException e) {
            cs = new SystemSettings__c();
            insert cs;
        }

        ApexPages.StandardController con = new ApexPages.StandardController(c);
        ConcessionExCon excon = new ConcessionExCon(con);
        excon.SelectAccount();

        // delete concession
        c.Delete_Reason__c = 'test';
        update c;
        excon.deleteConcession();
        Case cse = [select Valid_Concession__c from Case where Id = :c.Id];
        System.assert(!cse.Valid_Concession__c);

        // test deleteConcession exception
        cs.Disable_Web_Services__c = true;
        update cs;
        excon.deleteConcession();

        // general exceptions
        Account acc1 = new Account(name='test parent');
        insert acc1;
        Billing_Account__c ba1 = new Billing_Account__c(name='test', customer__c=acc1.Id, HiAF_Account_Number__c='9876');
        insert ba1;

        Case c1 = new Case(account=acc1, Billing_Account__c=ba1.Id);
        insert c1;
        ApexPages.StandardController con1 = new ApexPages.StandardController(c1);
        ConcessionExCon excon1 = new ConcessionExCon(con1);
        excon1.submitConcession();
        System.assertEquals(true, ApexPages.hasMessages());
        excon1.submitAppForm();
        System.assertEquals(true, ApexPages.hasMessages());
        excon1.deleteConcession();
        System.assertEquals(true, ApexPages.hasMessages());
    }
    
    private static TestMethod void testMe2() {
        ApexPages.StandardController con = new ApexPages.StandardController(new Case());
        ConcessionExCon excon = new ConcessionExCon(con);   

    }

}