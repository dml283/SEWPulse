public class COOTSUtil{ 

/*
    Type:       Utility Class
    Purpose:    
                apportion - Used to perform subdivision apportionments
                completeSMR - Used by HiAF action server to complete a SMR
                completeNOS - Used by HiAF to asynchronously complete a NOS

    Used By:    AccountMassBAcctAddressFlagUpdate
    ---------------------------------------------------------------
    History:


*/

    public static final String CLOSED_CASE_STATUS = 'Closed';
    
    public static void apportion(String role, String hiAfAccNo, String cisPropRef, String source, String moveInType){
        Billing_Account__c billAcct;
        List<Billing_Account__c> billAccts = [Select id, Status__c, Role__c, Property__c, HiAF_Account_Number__c from Billing_Account__c where HiAF_Account_Number__c = :hiAfAccNo];
        if(billAccts != null && !billAccts.isEmpty()){
            billAcct = billAccts[0];
        }
        Property__c prop;
        List<Property__c> properties = [Select id, CIS_Property_Id__c, (Select Id, Property__c, Status__c, Role__c, HiAF_Account_Number__c from Billing_Accounts__r where Status__c = 'Active' and Role__c in :PURCHASER_ROLES_APPORTION ) from Property__c where CIS_Property_Id__c = :cisPropRef];
        if(properties != null && !properties.isEmpty()){
            prop = properties[0];
        }
        apportion(role, billAcct, prop, source, moveInType);
    }
    
    public static void apportion(String role, Billing_Account__c billAcct, Property__c prop, String source, String moveInType){
        List<COOTSException> exceptions = new List<COOTSException>();
        if(billAcct==null){
            exceptions.add(new COOTSException(EXCEPTION_TYPE_ERROR, 'The account number cannot be found'));
        }
        if(source == null || source.trim().equals('')){
            exceptions.add(new COOTSException(EXCEPTION_TYPE_ERROR, 'Source is required'));
        }
        if(moveInType == null || moveInType.trim().equals('') || !(moveInType.toLowerCase().contains('in')||moveInType.toLowerCase().contains('out'))){
            exceptions.add(new COOTSException(EXCEPTION_TYPE_ERROR, 'Move In Type is required, and it must be either \'In\' or \'Out\''));
        }else{
            if(moveInType.toLowerCase().contains('in')){
                if (!PURCHASER_ROLES_APPORTION.contains(role)){
                    exceptions.add(new COOTSException(EXCEPTION_TYPE_ERROR, 'The Purchaser Role must be \'Owner\', \'Owner Occupier\', \'Landlord\', \'Body Corporate\', \'Tenant\' or \'Other\''));
                }
                if(prop==null){
                    exceptions.add(new COOTSException(EXCEPTION_TYPE_ERROR, 'The property cannot be found'));
                }//else{
                //    List<Billing_Account__c> billAcctsUnderProperty = prop.getSObjects('Billing_Accounts__r');
                //    if(billAcctsUnderProperty != null && !billAcctsUnderProperty.isEmpty()){
                //        exceptions.add(new COOTSException(EXCEPTION_TYPE_ERROR, 'There is another active owner on this property'));
                //    }
                //}
            }
        }
        if(exceptions.size()>0){
            COOTSMultiException multipleExceptions = new COOTSMultiException('Error in complete SMR operation');
            multipleExceptions.multiExs.addAll(exceptions);
            throw multipleExceptions;
        }
        Task taskRec = new Task();
        taskRec.whatId = billAcct.id;
        taskRec.Type = 'Apportionment';
        taskRec.RecordTypeId = READ_ONLY_ACTIVITY_RTYPE_ID;
        taskRec.ActivityDate = Date.today();
        taskRec.Status = 'Completed';
        if(moveInType.toLowerCase().contains('in')){
            billAcct.Property__c = prop.id;
            billAcct.Status__c = 'Active';
            billAcct.Role__c = role;
            taskRec.Subject = source+' - Move In';
            taskRec.Description = 'Open - Property Ref.: ' + prop.CIS_Property_Id__c;
        }else{//if(moveInType.toLowerCase().contains('out'))
        	System.debug('##FOOHERE2');
        	System.debug(prop);
            billAcct.Status__c = 'Closed';
            taskRec.Subject = source+' - Move Out';
            if (prop != null)
	            taskRec.Description = 'Close - Property Ref.: ' + prop.CIS_Property_Id__c;
			else
	            taskRec.Description = 'Close - Property Ref.: Property not specified';
			
        }
        taskRec.Group__c = 'Billing & Accounts';
        taskRec.Category_Level_1__c = 'Property';
        taskRec.Category_Level_2__c = 'Update Property';
        taskRec.Category_Level_3__c = 'Open or Close Charges';
        taskRec.Mode__c = 'Action';
        Savepoint sp = Database.setSavepoint();
        try{
            update billAcct;
            insert taskRec;
        }catch(Exception e){
            Database.rollback(sp);
            throw new COOTSException(EXCEPTION_TYPE_ERROR , e.getMessage());
        }
    }

    public static List<Billing_Account__c> completeSMR(Case caseRec){
        List<COOTSException> exceptions = new List<COOTSException>();
        if(caseRec.RecordTypeId==null || !caseRec.RecordType.Name.contains('Special Meter Read')){
            exceptions.add(new COOTSException(EXCEPTION_TYPE_ERROR, 'The case number provided is not a Special Meter Read'));
        }
        if (caseRec.Status != 'Waiting for HiAffinity'){
            exceptions.add(new COOTSException(EXCEPTION_TYPE_ERROR, 'The case status is not \"Waiting for HiAffinity\"'));
        }
        /* Removed per M.Vince
        if (!('Agent'.equals(caseRec.Contact_Type__c))&&!('Owner'.equals(caseRec.Contact_Type__c))&&!('Tenant'.equals(caseRec.Contact_Type__c))){
            exceptions.add(new COOTSException(EXCEPTION_TYPE_ERROR, 'The case contact type must be one of \"Agent\", \"Owner\" or \"Tenant\"'));
        }*/
        if(caseRec.Type_of_Read__c==null||!(caseRec.Type_of_Read__c.contains('Move In'))&&!(caseRec.Type_of_Read__c.contains('Move Out'))){
            exceptions.add(new COOTSException(EXCEPTION_TYPE_ERROR, 'The type of read must be either a \"Move In\" or a \"Move Out\"'));
        }
        if(exceptions.size()>0){
            COOTSMultiException multipleExceptions = new COOTSMultiException('Error in complete SMR operation');
            multipleExceptions.multiExs.addAll(exceptions);
            throw multipleExceptions;
        }
        List<Billing_Account__c> accountsToChange;
        if (caseRec.Type_of_Read__c.contains('Move In')){
            accountsToChange = [Select id, Property__c , HiAF_Account_Number__c, Role__c, Status__c from Billing_Account__c
                    where id = :caseRec.Billing_Account__c OR (Property__c = : caseRec.Property__c AND Status__c = 'Active' AND (Role__c LIKE 'Owner%' OR Role__c = 'Tenant'))];
            for(Billing_Account__c bAcct: accountsToChange){
                // find case's billing account, change status = active and role = tenant
                if(bAcct.id == caseRec.Billing_Account__c){
                    bAcct.Status__c = 'Active';
                    bAcct.Role__c = 'Tenant';
                    bAcct.Property__c = caseRec.Property__c;
                }
                // find property's billing account where role = owner-occupier or owner and status = active, change role = landlord
                else if(bAcct.Property__c == caseRec.Property__c && 'Active'.equals(bAcct.Status__c) &&
                            ('Owner Occupier'.equals(bAcct.Role__c) || 'Owner'.equals(bAcct.Role__c))){
                    bAcct.Role__c = 'Landlord';
                }
                // find property's billing account where role = tenant and status = active, change status = closed
                else if(bAcct.Property__c == caseRec.Property__c && 'Active'.equals(bAcct.Status__c) && 'Tenant'.equals(bAcct.Role__c)){
                    bAcct.Status__c = 'Closed';
                }
            }
        }else if (caseRec.Type_of_Read__c.contains('Move Out')){
            accountsToChange = [Select id, Property__c , HiAF_Account_Number__c, Role__c, Status__c from Billing_Account__c
                    where id = :caseRec.Billing_Account__c OR (Property__c = : caseRec.Property__c AND Status__c = 'Active' AND Role__c = 'Landlord')];
            for(Billing_Account__c bAcct: accountsToChange){
                // find property's billing account where role = landlord and status = active, change role = owner-occupier
                if(bAcct.Property__c == caseRec.Property__c && 'Active'.equals(bAcct.Status__c) && 'Landlord'.equals(bAcct.Role__c)){
                    bAcct.Role__c = 'Owner Occupier';
                }
                // find case's billing account, change status = closed
                else if(bAcct.id == caseRec.Billing_Account__c){
                    bAcct.Status__c = 'Closed';
                }
            }
        }
        caseRec.Status = 'Closed';
        caseRec.complete__c = true;
        Savepoint sp = Database.setSavepoint();
        try{
            update accountsToChange;
            update caseRec;
        }catch(Exception e){
            Database.rollback(sp);
            throw new COOTSException(EXCEPTION_TYPE_ERROR , e.getMessage());
        }
        return accountsToChange;
    }
    public static List<Billing_Account__c> completeSMR(String caseNumber){
        List<Case> caseRecs = [Select id, RecordTypeId, RecordType.Name, Status, Contact_Type__c, Type_of_Read__c, Billing_Account__c, Billing_Account__r.Id, Billing_Account__r.Status__c, Property__c from Case where CaseNumber = :caseNumber];
        if(caseRecs == null || caseRecs.size()==0){
            throw new COOTSException(EXCEPTION_TYPE_ERROR , 'Case number not found');
        }
        return completeSMR(caseRecs[0]);
    }

    public static List<Billing_Account__c> completeNOS(Case NOSCase, String PurchaserRole, Boolean NOSComplete, /*String NOSExceptionCode,*/ String NOSExceptionMsg, List<ErrorStatus> errors){
        List<Billing_Account__c> updatedBillingAccounts = new List<Billing_Account__c>();
        boolean noAlerts = true;
        if(errors.size()>0){
            NOSCase.Alerts_Int_Long__c = '';
            NOSCase.Information_Int_Long__c = '';
            for(ErrorStatus msg : errors){
                if ('3'.equals(msg.ErrorSeverity) || '4'.equals(msg.ErrorSeverity) || '5'.equals(msg.ErrorSeverity)){
                    NOSCase.Alerts_Int_Long__c += msg.ErrorDescription+'\n';
                    noAlerts = false;
                } else if ('1'.equals(msg.ErrorSeverity) || '2'.equals(msg.ErrorSeverity)){
                    NOSCase.Information_Int_Long__c += msg.ErrorDescription+'\n';
                }
            }
        }
        if(noAlerts){
            if(NOSComplete){
                updatedBillingAccounts = completeNOS(NOSCase, PurchaserRole);
                NOSCase.Status = CLOSED_CASE_STATUS;
                NOSCase.NOS_Exception__c = '';
                NOSCase.Complete__c = true;
                NOSCase.Alerts_Int_Long__c = null;
                NOSCase.Information_Int_Long__c = null;
                system.debug('### DEBUG: BillingAccounts Updated: ' + updatedBillingAccounts);
            } else {
                NOSCase.Status = 'Pending';
                NOSCase.NOS_Exception__c = /*NOSExceptionCode + ':\n' + */NOSExceptionMsg;
                NOSCase.Complete__c = false;
            }
        } else {
            NOSCase.Status = 'In Progress';
        }
        NOSCase.HIDDEN_Send_NOS_Processed_Email__c = true;
        
        update NOSCase;
        return updatedBillingAccounts;
    }

    public static List<Billing_Account__c> completeNOS(Case NOSCase, String PurchaserRole){
        List<COOTSException> exceptions = new List<COOTSException>();
        Map<String, Id> accTypeToAccId = new Map<String, Id>();
        Set<Id> accIdsToUpdate = new Set<Id>();


        if(NOSCase.RecordTypeId==null || NOSCase.RecordType.DeveloperName != 'Notice_of_Sale'){
            exceptions.add(new COOTSException(EXCEPTION_TYPE_ERROR, 'The case number provided is not a Notice of Sale'));
        }
        if (NOSCase.Vendor_Billing_Account__c != null){
            accTypeToAccId.put('Vendor', NOSCase.Vendor_Billing_Account__c);
            accIdsToUpdate.add(NOSCase.Vendor_Billing_Account__c);
        } else {
            exceptions.add(new COOTSException(EXCEPTION_TYPE_ERROR, 'There is no Vendor Billing Account associated with this Case'));
        }
        if (NOSCase.Purchaser_Billing_Account__c != null){
            accTypeToAccId.put('Purchaser', NOSCase.Purchaser_Billing_Account__c);
            accIdsToUpdate.add(NOSCase.Purchaser_Billing_Account__c);
        } else {
            exceptions.add(new COOTSException(EXCEPTION_TYPE_ERROR, 'There is no Purchaser Billing Account associated with this Case'));
        }
        if (!PURCHASER_ROLES.contains(PurchaserRole)){
            exceptions.add(new COOTSException(EXCEPTION_TYPE_ERROR, 'The Purchaser Role must be \'Owner\', \'Owner Occupier\', \'Landlord\', or \'Body Corporate\''));
        }
        if (NOSCase.Type_of_Sale__c == 'Sale of Business'){
            exceptions.add(new COOTSException(EXCEPTION_TYPE_ERROR, 'The Type of Sale cannot be \'Sale of Business\''));
        }
        if (NOSCase.Complete__c){
            exceptions.add(new COOTSException(EXCEPTION_TYPE_ERROR, 'The Notice of Sale has already been completed in the Pulse System'));
        }
        if (NOSCase.Tenant_Billing_Account__c != null){
            accTypeToAccId.put('Tenant', NOSCase.Tenant_Billing_Account__c);
            accIdsToUpdate.add(NOSCase.Tenant_Billing_Account__c);
        }

        if(exceptions.size()>0){
            COOTSMultiException multipleExceptions = new COOTSMultiException('Error in completeNOS operation');
            multipleExceptions.multiExs.addAll(exceptions);
            throw multipleExceptions;
        }

        List<Billing_Account__c> accsToUpdate = [    SELECT Id, Status__c, Property__c, Role__c
                                                        FROM Billing_Account__c
                                                        WHERE Id IN :accIdsToUpdate
                                                ];

        for (Billing_Account__c ba : accsToUpdate){
            //Update the Vendors Billing Account to Closed
            if (ba.Id == accTypeToAccId.get('Vendor')){
                ba.Status__c = 'Closed';
            //Update the Purchasers Billing Account to Acive, assign the property and set the purchaser Role
            } else if (ba.Id == accTypeToAccId.get('Purchaser')){
                ba.Property__c = NOSCase.Property__c;
                ba.Role__c = PurchaserRole;
                ba.Status__c = 'Active';
            } else if (ba.Id == accTypeToAccId.get('Tenant') && NOSCase.Type_of_Sale__c == 'New Purchaser, Tenant Leaves'){
                ba.Status__c = 'Closed';
            }
        }
        update accsToUpdate;
        return accsToUpdate;
    }

    public static List<Billing_Account__c> completeNOS(String caseNumber, String PurchaserRole, Boolean NOSComplete, /*String NOSExceptionCode,*/ String NOSExceptionMsg, List<ErrorStatus> errors){
        system.debug('### DEBUG: Case Number being passed in = ' + caseNumber);
        system.debug('### DEBUG: The Purchaser Role being passed in = ' + PurchaserRole);

        List<Case> NOSCase = [    SELECT Id, Billing_Account__c, Vendor_Billing_Account__c, RecordType.DeveloperName, RecordTypeId, CaseNumber,
                                Purchaser_Billing_Account__c, Tenant_Billing_Account__c, Property__c, Type_of_Sale__c,
                                Purchaser_Billing_Account__r.Role__c, Complete__c, Information_Int_Long__c, Alerts_Int_Long__c
                            FROM Case
                            WHERE CaseNumber = :caseNumber LIMIT 1
                        ];

        if (NOSCase.isEmpty()){
            throw new COOTSException(EXCEPTION_TYPE_ERROR, 'Case number not found');
        }
        return completeNOS(NOSCase[0], PurchaserRole, NOSComplete, /*NOSExceptionCode,*/ NOSExceptionMsg, errors);
    }

    public class COOTSException extends Exception{
        public string exceptionType;
        public COOTSException (String exceptionType, String exceptionMsg){
            this();
            this.exceptionType = exceptionType;
            this.setMessage(exceptionMsg);
        }
    }
    public class COOTSMultiException extends Exception{
        public List<COOTSException> multiExs{
            get{
                if (multiExs==null){
                    multiExs= new List<COOTSException>();
                } return multiExs;
            }set;
        }
    }

    public class ErrorStatus{
        public String ErrorCode{get;set;}
        public String ErrorSeverity{get;set;}
        public String ErrorDescription{get;set;}
    }

    public static final string EXCEPTION_TYPE_ERROR = 'Error';
    public static final string EXCEPTION_TYPE_WARNING = 'Warning';
    public static final string EXCEPTION_TYPE_INFO = 'Info';
    private static Set<String> PURCHASER_ROLES = new Set<String>{'Owner', 'Owner Occupier', 'Landlord', 'Body Corporate'};
    private static Set<String> PURCHASER_ROLES_APPORTION;
    private static Id READ_ONLY_ACTIVITY_RTYPE_ID;
    
    static{
        PURCHASER_ROLES_APPORTION = new Set<String>();
        List<Schema.PicklistEntry> picklistEntries = Billing_Account__c.Role__c.getDescribe().getPicklistValues();
        for(Schema.PicklistEntry pEntry: picklistEntries){
            PURCHASER_ROLES_APPORTION.add(pEntry.getValue());
        }
        READ_ONLY_ACTIVITY_RTYPE_ID = [Select id from RecordType where DeveloperName = 'Read_Only_Tasks' and SObjectType = 'Task'].id;
    }
}