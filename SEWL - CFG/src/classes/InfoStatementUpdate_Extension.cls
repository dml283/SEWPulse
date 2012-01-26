public with sharing class InfoStatementUpdate_Extension {
    
    public static final String CLOSED_CASE_STATUS = 'Closed';
    public static final String CANCELLED_CASE_STATUS = 'Cancelled';
    
    private Case isuCase;

    /* Constuctor */
    public InfoStatementUpdate_Extension(ApexPages.StandardController controller) {
        this.isuCase = (Case)controller.getRecord();
    }
 
    public PageReference performInfoStatementUpdate(){
        if (isuCase.Status == CLOSED_CASE_STATUS || isuCase.Status == CANCELLED_CASE_STATUS){
            ApexPages.Message closedCaseError = new ApexPages.Message(ApexPages.Severity.ERROR, 'You cannot Perform and Information Statement Update for a Closed or Cancelled Case');
            ApexPages.addMessage(closedCaseError);
            return null;
        } else {
            resetInfoAndAlerts();
            try {
                WSUtil_InfoStatementUpdate.InfoStatementUpdateResponse response = new WSUtil_InfoStatementUpdate.InfoStatementUpdateResponse();
                WSUtil_InfoStatementUpdate ws = new WSUtil_InfoStatementUpdate();
                
                ws.requestDetail.PropertyReference = isuCase.Property__r.CIS_Property_Id__c;
                if (isuCase.Billing_Account_Quoted__c){
                    ws.requestDetail.AccountQuoted = '1';
                } else {
                    ws.requestDetail.AccountQuoted = '0';
                }
                if (isuCase.Address_Available__c){
                    ws.requestDetail.RadioSet = '1';
                } else {
                    ws.requestDetail.RadioSet = '0';
                }
                ws.requestDetail.PurchaserName = isuCase.Attention_Of__c;
                ws.requestDetail.LineAddress1 = isuCase.Street__c;
                ws.requestDetail.LineAddress2 = isuCase.City__c;
                ws.requestDetail.LineAddress3 = isuCase.State__c;
                ws.requestDetail.LineAddress4 = isuCase.Postcode__c;
                
                response = ws.infoStatementUpdate();  
                
                
                if (response.UpdateGiven){
                    isuCase.Update_Given__c = true;
                    isuCase.Information_Statement_Advice__c = 'INFORMATION STATEMENT ADVICE PROVIDED:\n';
                    if (response.CurrentDrainage != null){
                        isuCase.Information_Statement_Advice__c += 'CURRENT DRAINAGE:  $' + response.CurrentDrainage + '\t';
                        isuCase.Information_Statement_Advice__c += 'PERIOD TO:  ' + response.DrainagePeriodTo.format() + '\n';
                    }
                    if (response.DrainageUnpaid != null){
                        isuCase.Information_Statement_Advice__c += 'DRAINAGE UNPAID:  $' + response.DrainageUnpaid + '\n';
                    }
                    if (response.CurrentParks != null){
                        isuCase.Information_Statement_Advice__c += 'CURRENT PARKS:  $' + response.CurrentParks + '\t';
                        isuCase.Information_Statement_Advice__c += 'PERIOD TO:  ' + response.ParksPeriodTo.format() + '\n';
                    }
                    if (response.ParksUnpaid != null){
                        isuCase.Information_Statement_Advice__c += 'PARKS UNPAID:  $' + response.ParksUnpaid + '\n';
                    }
                    if (response.Pre_01_01_98 != null){
                        isuCase.Information_Statement_Advice__c += 'PRE 01/01/98:  $' + response.Pre_01_01_98 + '\t';
                        isuCase.Information_Statement_Advice__c += 'LEGAL COSTS:  $' + response.LegalCosts + '\n';
                    }
                    if (response.TotalOwning != null){
                        isuCase.Information_Statement_Advice__c += 'TOTAL OWING:  $' + response.TotalOwning + '\n';
                    }
                    if (isuCase.Billing_Account_Quoted__c){
                        isuCase.Information_Statement_Advice__c += 'CUSTOMER NO. QUOTED';
                    } else {
                        isuCase.Information_Statement_Advice__c += 'CUSTOMER NO. [NOT] QUOTED';
                    }
                } else {
                    isuCase.Update_Given__c = false;
                }
                
                if(response.messages.size()>0){
                    for(WSUtil.SingleWebServiceBusinessException msg : response.messages){
                        if ('3'.equals(msg.ErrorSeverity) || '4'.equals(msg.ErrorSeverity) || '5'.equals(msg.ErrorSeverity)){
                            isuCase.Alerts_Int_Long__c += msg.getMessage()+'\n';
                        } else if ('1'.equals(msg.ErrorSeverity) || '2'.equals(msg.ErrorSeverity)){
                            isuCase.Information_Int_Long__c += msg.getMessage()+'\n';
                        }
                    }   
                }
                if(response.noAlerts){
                    if (response.ManualCheck){
                        isuCase.Manual_Check__c = true;
                        isuCase.Status = 'Pending'; 
                    } else{
                        isuCase.Manual_Check__c = false;
                        isuCase.Status = CLOSED_CASE_STATUS; 
                    }
                } else {
                    isuCase.Status = 'In Progress';
                }       
                
                update isuCase;
            } catch (system.Calloutexception ex) { // SOAP Error
                ApexPages.addmessage(
                    new ApexPages.message(ApexPages.severity.ERROR,'There was a problem getting the Information Statement Update Details - please contact system administrator. Error message:'+ex.getMessage())
                );  
                return null;
            } catch (WSUtil.MultipleWebServiceBusinessException e) {   // Error return from webservice - Business level
                for (WSUtil.SingleWebServiceBusinessException err: e.multiEx) {
                    ApexPages.addmessage(
                        new ApexPages.message(ApexPages.severity.ERROR,err.getMessage())
                    );
                }
                return null;
            }
        }
        return new PageReference('/' + isuCase.Id);
        //return null;  
    }
    
    /* Reset Info and Alert Fields before Performing operation */
    private void resetInfoAndAlerts(){
        isuCase.Information_Int_Long__c = '';
        isuCase.Alerts_Int_Long__c = '';
        isuCase.Information_Statement_Advice__c = '';
    }
    
    public PageReference back(){
        return new PageReference('/' + isuCase.Id);
    }
    
    public static testMethod void test_InfoStatementUpdate_Extension_BillAccountNotQuoted(){
        Account testAccount = SObjectCreator.createAccountResidentialCustomer();
        insert testAccount;
        
        Contact testContact = SObjectCreator.createContact();
        testContact.AccountId = testAccount.Id;
        insert testContact;
        
        Property__c testProperty = SObjectCreator.createProperty();
        insert testProperty;
        
        Billing_Account__c testBillingAccount = SObjectCreator.createBillingAccountBillingAccount();
        testBillingAccount.Customer__c = testAccount.Id;
        testBillingAccount.Property__c = testProperty.Id;
        insert testBillingAccount;
        
        Case testInfoStatementUpdateCase = SObjectCreator.createCaseInfoStatementUpdate();
        testInfoStatementUpdateCase.AccountId = testAccount.Id;
        testInfoStatementUpdateCase.Billing_Account__c = testBillingAccount.Id;
        insert testInfoStatementUpdateCase;
        
        ApexPages.Standardcontroller stdCon = new ApexPages.Standardcontroller(testInfoStatementUpdateCase);
        InfoStatementUpdate_Extension extnCon = new InfoStatementUpdate_Extension(stdCon);
        
        Test.startTest();
        extnCon.performInfoStatementUpdate();
        extnCon.back();
        Test.stopTest();
        
        /*testInfoStatementUpdateCase.Billing_Account_Quoted__c = true;
        update testInfoStatementUpdateCase;
        
        ApexPages.Standardcontroller stdCon = new ApexPages.Standardcontroller(testInfoStatementUpdateCase);
        InfoStatementUpdate_Extension extnCon = new InfoStatementUpdate_Extension(stdCon);
        
        Test.startTest();
        extnCon.performInfoStatementUpdate();
        Test.stopTest();
        
        testInfoStatementUpdateCase.Status = CLOSED_CASE_STATUS;
        update testInfoStatementUpdateCase;
        
        ApexPages.Standardcontroller stdCon = new ApexPages.Standardcontroller(testInfoStatementUpdateCase);
        InfoStatementUpdate_Extension extnCon = new InfoStatementUpdate_Extension(stdCon);
        
        Test.startTest();
        extnCon.performInfoStatementUpdate();
        Test.stopTest();*/
    }
    
    public static testMethod void test_InfoStatementUpdate_Extension_CaseAlreadyClosed(){
        Account testAccount = SObjectCreator.createAccountResidentialCustomer();
        insert testAccount;
        
        Contact testContact = SObjectCreator.createContact();
        testContact.AccountId = testAccount.Id;
        insert testContact;
        
        Property__c testProperty = SObjectCreator.createProperty();
        insert testProperty;
        
        Billing_Account__c testBillingAccount = SObjectCreator.createBillingAccountBillingAccount();
        testBillingAccount.Customer__c = testAccount.Id;
        testBillingAccount.Property__c = testProperty.Id;
        insert testBillingAccount;
        
        Case testInfoStatementUpdateCase = SObjectCreator.createCaseInfoStatementUpdate();
        testInfoStatementUpdateCase.AccountId = testAccount.Id;
        testInfoStatementUpdateCase.Billing_Account__c = testBillingAccount.Id;
        testInfoStatementUpdateCase.Status = CLOSED_CASE_STATUS;
        insert testInfoStatementUpdateCase;
        
        ApexPages.Standardcontroller stdCon = new ApexPages.Standardcontroller(testInfoStatementUpdateCase);
        InfoStatementUpdate_Extension extnCon = new InfoStatementUpdate_Extension(stdCon);
        
        Test.startTest();
        extnCon.performInfoStatementUpdate();
        Test.stopTest();
    }
    
    public static testMethod void test_InfoStatementUpdate_Extension_BillingAccountQuoted(){
        Account testAccount = SObjectCreator.createAccountResidentialCustomer();
        insert testAccount;
        
        Contact testContact = SObjectCreator.createContact();
        testContact.AccountId = testAccount.Id;
        insert testContact;
        
        Property__c testProperty = SObjectCreator.createProperty();
        testProperty.Recycled_Water_Available__c = true;
        insert testProperty;
        
        Billing_Account__c testBillingAccount = SObjectCreator.createBillingAccountBillingAccount();
        testBillingAccount.Customer__c = testAccount.Id;
        testBillingAccount.Property__c = testProperty.Id;
        insert testBillingAccount;
        
        Case testInfoStatementUpdateCase = SObjectCreator.createCaseInfoStatementUpdate();
        testInfoStatementUpdateCase.AccountId = testAccount.Id;
        testInfoStatementUpdateCase.Billing_Account__c = testBillingAccount.Id;
        testInfoStatementUpdateCase.Billing_Account_Quoted__c = true;
        testInfoStatementUpdateCase.Property__c = testProperty.Id;
        testInfoStatementUpdateCase.Street__c = 'Test Street';
        testInfoStatementUpdateCase.City__c = 'Test City';
        testInfoStatementUpdateCase.State__c = 'TestState';
        testInfoStatementUpdateCase.Postcode__c = '1234';
        testInfoStatementUpdateCase.Country__c = 'Test Country';
        testInfoStatementUpdateCase.Address_Available__c = true;
        insert testInfoStatementUpdateCase;
        
        ApexPages.Standardcontroller stdCon = new ApexPages.Standardcontroller(testInfoStatementUpdateCase);
        InfoStatementUpdate_Extension extnCon = new InfoStatementUpdate_Extension(stdCon);
        
        Test.startTest();
        extnCon.performInfoStatementUpdate();
        Test.stopTest();
        
        Tibco_InfoStatementUpdate_MessageTypes.ErrorStatus_element isu = new  Tibco_InfoStatementUpdate_MessageTypes.ErrorStatus_element();
    }
}