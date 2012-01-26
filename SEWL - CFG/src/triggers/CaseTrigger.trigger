trigger CaseTrigger on Case (before insert, before update, after insert, after update) {

/*
    Type:       Trigger
    Purpose:    (i)     Defaults the due date using default business hours (10 days from now)
                (ii)    Set the b/acct to the vendor account for NOS
                (iii)   Set the purchaser to the tenant for NOS sale type = 'Tenant is Purchaser'
                (iv)    Set the case owner team and redirect to portal queue if case is not closed and assigned to a portal user.
                (v)     Set the customer to the billing account customer
                (vi)    Populate NOS classification flags
                (vii)   Update the case duplicate task (so cases can be viewed in interaction log as well)
                (viii)  Update billing acct from SMR billing acct
                (ix)    Update billing account and customer ewov invistagtive flag
                (x)     check SMR if reading date is at least 2 business days after today
                (xi)    On after insert, if auto suspend is on, and case is not closed, and of certain type
                        as specified in Custom Setting CaseTypeSetting.Is_Auto_Suspend__c
                (x)     EWOV cases have different due dates
                (xiii)  Auto truncate Alert and Information long integration field to short integration field

    ---------------------------------------------------------------
    History:
        13-Sep-2011 - D.Thong (SFDC)    Created
*/

    if (trigger.isBefore && trigger.isInsert) {
        // (i) do so for all new cases
        CaseUtil.SetCaseDueDate(trigger.new);
    }

    if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)) {
        // Perform (ii) & (iii) & (iv) & (v) & (vi) & (x) * (xiii)
        CaseUtil.truncateAlertsInformationLongIntFields(trigger.new);
        CaseUtil.checkSMRReadDateTwoBusinessDayFromToday(trigger.new);
        CaseUtil.setCaseOwnerAndTeam(trigger.new);

        List <Case> NOSCases = new List <Case>();
        List <Case> casesToDefault = new List <Case>();
        List<Case> NOSChangedBillAccountCases = new List<Case>();
        List<Case> EWOVDueDateCases = new List<Case>();

        for (Case c : trigger.new) {
           // populate the SMR billing account to billing account
            if (c.Billing_Account_SMR__c != c.Billing_Account__c && c.Billing_Account_SMR__c != null)
                c.Billing_Account__c = c.Billing_Account_SMR__c;

            if (c.RecordTypeId == CaseUtil.NOTICE_OF_SALE_RECORDTYPE_ID) {
                NOSCases.add(c);
                if (c.Billing_Account__c != null && (trigger.isInsert  || c.Billing_Account__c != trigger.oldMap.get(c.Id).Billing_Account__c)){
                    // (vi) populate NOS class flags
                    NOSChangedBillAccountCases.add(c);
                }
            }
            system.debug('### DEBUG: setNOSDefaults Cases: ' + NOSCases);
            if (!NOSCases.isEmpty()) CaseUtil.setNOSDefaults(NOSCases);
            // (v) populate the account from the B/acct if it is missing
            if ((c.AccountId == null || c.property__c == null) && c.Billing_Account__c != null) {
                casesToDefault.add(c);
            }

            // (x) EWOV Due Dates
            if (trigger.isUpdate && c.EWOV_Type__c != trigger.oldMap.get(c.Id).EWOV_Type__c && !c.IsClosed) {
                EWOVDueDateCases.add(c);
            }
        }

        // do all the stuff
        system.debug('### DEBUG: noCustIdCases Cases: ' + casesToDefault);
        system.debug('### DEBUG: setNOSClassificationFlags Cases: ' + NOSChangedBillAccountCases);
        if (!casesToDefault.isEmpty()) CaseUtil.DefaultCaseFieldsFromBAcct(casesToDefault);
        if (!NOSChangedBillAccountCases.isEmpty()) CaseUtil.setNOSClassificationFlags(NOSChangedBillAccountCases);
        if (!EWOVDueDateCases.isEmpty()) CaseUtil.SetCaseDueDate(EWOVDueDateCases);

    }
    if(Trigger.isAfter && (trigger.isInsert || trigger.isUpdate)){
        //(xi)    On after insert, if No_Action_Required__c is off, and case is not closed, and of certain type
        //        as specified in Custom Setting CaseTypeSetting.Is_Auto_Suspend__c

        List <Case> suspendCases = new List <Case>();

        for (Case caseRec : trigger.new) {
            if ((!caseRec.isClosed)
                    && ((trigger.isInsert && caseRec.Suspend_Billing__c) ||
                            (trigger.IsUpdate && caseRec.Suspend_Billing__c && !trigger.oldMap.get(caseRec.id).Suspend_Billing__c))
                    && caseRec.Billing_Account__c != null){
                suspendCases.add(caseRec);
            }
        }

        if( !suspendCases.isEmpty() ){
            CaseUtil.setBillAccAutoSuspendByCase(suspendCases);
        }

        // (vii)   Update the case duplicate task (so cases can be viewed in interaction log as well)
        CaseUtil.createUpdateCaseDuplicateTask(trigger.new);
        // (ix)   Update billing account and customer ewov invistagtive flag
        List<Case> casesToCheck = new List<Case>(trigger.new);
        if(trigger.isUpdate) casesToCheck.addAll(trigger.old);

        CaseUtil.updateBillAcctEWOVflag(casesToCheck);
        CaseUtil.updateCustEWOVflag(casesToCheck);

        CaseUtil.UpdatePropertyInsuranceFlag(casesToCheck);
        CaseUtil.UpdateContactInsuranceFlag(casesToCheck);

    }
}