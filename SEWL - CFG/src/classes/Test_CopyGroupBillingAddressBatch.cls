/*
    Type:       Test Class
    Purpose:    
				Performs Testing for Copy Group Addresses

    ---------------------------------------------------------------
    History:


*/
@isTest
private class Test_CopyGroupBillingAddressBatch {

    static testMethod void updateStreetAddressOfGroupAccount() {
        Account AccountResidentialCustomerObject = SObjectCreator.createAccountResidentialCustomer();
        insert AccountResidentialCustomerObject;
        
        
        Billing_Account__c BillingAccountGroupBillingAccountObject = SObjectCreator.createBillingAccountGroupBillingAccount();
        BillingAccountGroupBillingAccountObject.Street_Address__c = 'Test Street Address';
        BillingAccountGroupBillingAccountObject.City__c = 'Test City';
        BillingAccountGroupBillingAccountObject.State__c = 'Test State';
        BillingAccountGroupBillingAccountObject.Country__c = 'Test Country';
        BillingAccountGroupBillingAccountObject.Postal_Code__c = '1234';
        BillingAccountGroupBillingAccountObject.Update_Sub_Account_Addresses__c = TRUE;
        BillingAccountGroupBillingAccountObject.Customer__c = AccountResidentialCustomerObject.Id;
        insert BillingAccountGroupBillingAccountObject;
        List<Billing_Account__c> BillingAccountObjectLIST = new List<Billing_Account__c>();
        Set<Id> billingAccountIds = new Set<Id>();
        for (Integer i = 0 ; i < 100 ; i++){
            Billing_Account__c BillingAccountBillingAccountObject = SObjectCreator.createBillingAccountBillingAccount();
            BillingAccountBillingAccountObject.Billing_Address_Same_As__c = 'Group Account';
            BillingAccountBillingAccountObject.Group_Billing_Account__c = BillingAccountGroupBillingAccountObject.Id;
            BillingAccountBillingAccountObject.Customer__c = AccountResidentialCustomerObject.Id;
            BillingAccountObjectLIST.add(BillingAccountBillingAccountObject);
        }
        insert BillingAccountObjectLIST;
        
        List<Billing_Account__c> groupBillingAccounts = new List<Billing_Account__c>();
        groupBillingAccounts.add(BillingAccountGroupBillingAccountObject);
        CopyGroupBillingAddress_BATCH copyGroupBillingAddress_TEST = new CopyGroupBillingAddress_BATCH(groupBillingAccounts);   
        
        Test.StartTest();
        ID batchprocessid = Database.executeBatch(copyGroupBillingAddress_TEST);
        Test.StopTest();          
        
        List<Billing_Account__c> subBillingAccounts = [ SELECT    Id
                                                                , Street_Address__c
                                                                , City__c
                                                                , State__c
                                                                , Country__c
                                                                , Postal_Code__c
                                                                , Attention__c
                                                                , Care_Of__c
                                                                , Billing_Address_Same_As__c
                                                                , Group_Billing_Account__c
                                                        FROM    Billing_Account__c
                                                        WHERE   Group_Billing_Account__c = :BillingAccountGroupBillingAccountObject.Id];
                                                        
        for(Billing_Account__c b : subBillingAccounts){
            system.assertEquals(BillingAccountGroupBillingAccountObject.Street_Address__c, b.Street_Address__c);
            system.assertEquals(BillingAccountGroupBillingAccountObject.City__c, b.City__c);
            system.assertEquals(BillingAccountGroupBillingAccountObject.State__c, b.State__c);
            system.assertEquals(BillingAccountGroupBillingAccountObject.Country__c, b.Country__c);
            system.assertEquals(BillingAccountGroupBillingAccountObject.Postal_Code__c, b.Postal_Code__c);
            system.assertEquals(BillingAccountGroupBillingAccountObject.Attention__c, b.Attention__c);
            system.assertEquals(BillingAccountGroupBillingAccountObject.Care_Of__c, b.Care_Of__c);
        }                                                           
        
    }
}