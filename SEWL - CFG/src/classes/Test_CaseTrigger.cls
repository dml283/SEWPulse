/*
    Type:       Test Class
    Purpose:    
				Performs Testing for Case

    ---------------------------------------------------------------
    History:


*/
@isTest
private class Test_CaseTrigger {
    static TestMethod void testNewNOSCaseWFlags(){
        Set<String> legalFlags = new Set<String>{'LT', 'LS', 'L1', 'L2'};
        Set<String> caveatFlags = new Set<String>{'CV'};
        Set<String> dialysisFlags = new Set<String>{'DL', 'DM'};
        
        Account testCustomer1 = SObjectCreator.createAccountResidentialCustomer();
        insert testCustomer1;
        
        Billing_Account__c testBillAcc1 = SObjectCreator.createBillingAccountBillingAccount();
        testBillAcc1.Customer__c = testCustomer1.Id;
        insert testBillAcc1;
        
        Account testCustomer2 = SObjectCreator.createAccountResidentialCustomer();
        insert testCustomer2;
        
        Billing_Account__c testBillAcc2 = SObjectCreator.createbillingAccountBillingAccount();
        testBillAcc2.Customer__c = testCustomer2.Id;
        
        //Set<String> classCodes = [SELECT Id, Name FROM Classification_Code__c];
        List<Classification_Code__c> legalCodes = new List<Classification_Code__c>();
        List<Classification_Code__c> caveatCodes = new List<Classification_Code__c>();
        List<Classification_Code__c> dialysisCodes = new List<Classification_Code__c>();
        
        List<Classification_Code__c> classCodes = [SELECT Id, Name FROM Classification_Code__c WHERE Name IN :legalFlags OR Name IN :caveatFlags OR Name IN :dialysisFlags];
        for (Classification_Code__c cc : classCodes){
            if (legalFlags.contains(cc.Name)){
                legalCodes.add(cc);
            } else if (caveatFlags.contains(cc.Name)){
                caveatCodes.add(cc);
            } else if (dialysisFlags.contains(cc.Name)){
                dialysisCodes.add(cc);
            }
        }
        List<Classification_Code__c> classificationCodesToCreate = new List<Classification_Code__c>();
        Boolean needToReQuery = FALSE;
        if (legalCodes.size() == 0){
            Classification_Code__c legalClassCode = SObjectCreator.createClassificationCode();
            legalClassCode.Name = 'LT';
            classificationCodesToCreate.add(legalClassCode);   
            needToReQuery = TRUE;         
        }
        if (caveatCodes.size() == 0){
            Classification_Code__c caveatClassCode = SObjectCreator.createClassificationCode();
            caveatClassCode.Name = 'CV';
            classificationCodesToCreate.add(caveatClassCode);
            needToReQuery = TRUE;
        }
        if (dialysisCodes.size() == 0){
            Classification_Code__c dialysisClassCode = SObjectCreator.createClassificationCode();
            dialysisClassCode.Name = 'DM';
            classificationCodesToCreate.add(dialysisClassCode);
            needToReQuery = TRUE;
        }
        if (classificationCodesToCreate.size() > 0){
            insert classificationCodesToCreate;
            classCodes.addAll(classificationCodesToCreate);
       }
       List<Customer_Classification__c> custClasses = new List<Customer_Classification__c>();
       for (Classification_Code__c cc : classCodes){
           Customer_Classification__c custClass = SObjectCreator.createCustomerClassification();
           custClass.Classification__c = cc.Id;
           custClass.Customer__c = testCustomer1.Id;
           custClasses.add(custClass);
       }
       insert custClasses;
       
       Case NOSCase = SObjectCreator.createCaseNoticeOfSale();
       NOSCase.Billing_Account__c = testBillAcc1.Id;
       insert NOSCase;
       
       Case verifyCase = [SELECT Id, Legal_Customer__c, Dialysis_Customer__c, Caveat_Customer__c, Billing_Account__c, Billing_Account__r.Customer__c, AccountId FROM Case WHERE Id = :NOSCase.Id];
       system.debug('### DEBUG Verify Case Details = ' + verifyCase);
       system.assert(verifyCase.Legal_Customer__c);
       system.assert(verifyCase.Dialysis_Customer__c);
       system.assert(verifyCase.Caveat_Customer__c);
       system.assertEquals(verifyCase.Billing_Account__r.Customer__c, verifyCase.AccountId);
       
    }
}