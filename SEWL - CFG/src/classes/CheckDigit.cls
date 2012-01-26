public with sharing class CheckDigit {
    /*
    Type:       Utility Class
    Purpose:    Calculates check digits

    ---------------------------------------------------------------
    History:

    01-Jun-2011 D.Thong (Salesforce)    Created

    */

    // calculates check digit based on positional weightings from right
    public static string CalculateBAcctCheckDigit (string value){

        integer weightedSum = 0;
        string checkDigit='';
        //0. must be numeric
        if (value != null && value != '' && Pattern.matches('\\d*', value))
        {
            for (integer i = 0; i < value.length(); i++) {
                System.debug('ABC');
                System.debug(integer.valueOf(value.substring(i, i + 1)));
                System.debug(value.length()-i);
                weightedSum += (integer.valueOf(value.substring(i, i + 1))) * (value.length()-i);
            }
            System.debug('weightedsum');
            System.debug(weightedSum);
            integer remainder = math.mod(weightedSum, 11);
            integer checkdigitnumeric;
            if (remainder>0) {
                checkdigitnumeric = 11 - remainder;
                if (checkdigitnumeric == 10)
                    checkdigitnumeric = 5;
            } else
                checkdigitnumeric = 0;

            checkDigit = checkdigitnumeric.format();
        }
        return checkDigit;
    }

    private static TestMethod void testme() {
        System.assertEquals('2', CheckDigit.CalculateBAcctCheckDigit('372658'));
        System.assertEquals('6', CheckDigit.CalculateBAcctCheckDigit('635701'));
        System.assertEquals('0', CheckDigit.CalculateBAcctCheckDigit('635766'));
        System.assertEquals('1', CheckDigit.CalculateBAcctCheckDigit('635714'));
        System.assertEquals('5', CheckDigit.CalculateBAcctCheckDigit('635724'));
        System.assertEquals('4', CheckDigit.CalculateBAcctCheckDigit('635800'));
        System.assertEquals('5', CheckDigit.CalculateBAcctCheckDigit('635745'));
        System.assertEquals('8', CheckDigit.CalculateBAcctCheckDigit('1645687'));
        System.assertEquals('9', CheckDigit.CalculateBAcctCheckDigit('1115237'));
        System.assertEquals('5', CheckDigit.CalculateBAcctCheckDigit('1256980'));

        // create account
        Account a = new Account(name='ABC');
        insert a;

        // create contacts
        Contact c1 = new Contact(LastName = '1', AccountId = a.id);
        Contact c2 = new Contact(LastName = '2', AccountId = a.id);
        insert c1;
        insert c2;

        // create property
        Property__c p = new Property__c();
        p.Universal_Id_c__c = 'test';
        insert p;

        // create billing account
        Billing_Account__c ba = new Billing_Account__c();
        ba.Customer__c = a.id;
        ba.Property__c = p.id;
        ba.HiAF_Account_Number__c = '372658';
        insert ba;

        System.assertEquals('3726582', [select HiAF_Account_Number_Check_Digit__c from Billing_Account__c
                                        where id = :ba.id LIMIT 1].HiAF_Account_Number_Check_Digit__c);

    }
}