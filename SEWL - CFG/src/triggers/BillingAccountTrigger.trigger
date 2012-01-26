trigger BillingAccountTrigger on Billing_Account__c (before insert, before update) {

    /**************************************************************************/
    /*  Description:
    /*      (1) Calculates check digit

    /*  Change History:
    /*      D.Thong     12-May-2011     Created
    /**************************************************************************/

    if (trigger.isBefore) {
        if (trigger.isInsert || trigger.isUpdate) {

            for (Billing_Account__c ba : trigger.new) {
                if (ba.HiAF_Account_Number__c != null) {
                    String chkdigit = CheckDigit.CalculateBAcctCheckDigit(ba.HiAF_Account_Number__c);
                    ba.HiAF_Account_Number_Check_Digit__c = ba.HiAF_Account_Number__c + chkdigit;
                } else
                    ba.HiAF_Account_Number_Check_Digit__c = null;
                if (ba.Name != ba.HiAF_Account_Number__c) ba.Name = ba.HiAF_Account_Number__c;
            }

        }
    }

}