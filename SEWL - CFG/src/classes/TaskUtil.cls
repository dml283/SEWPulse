/*
    Type:       Utilities
    Purpose:    Assist on Task related operations

    Used By:    Too much to mention
    ---------------------------------------------------------------
    History:

    07-Sep-2011 J.Pe (Davanti Consulting)    Created

*/
public class TaskUtil{

    public static void updateDDFieldsOnBillAcct(List<Task> tasks){
        Set<Id> billAcctIds = new Set<Id>();
        for(Task taskRec: tasks){
            billAcctIds.add(taskRec.whatId);
        }
        List<Billing_Account__c> billAcctToUpdate = new List<Billing_Account__c>();
        Map<Id, Billing_Account__c> billAcctMap = new Map<Id, Billing_Account__c>([Select id from Billing_Account__c where id in : billAcctIds ]);
        for(Task taskRec: tasks){
            Billing_Account__c billAcct = billAcctMap.get(taskRec.whatId);
            if(billAcct!=null){
                billAcct.Direct_Debit_Details__c = taskRec.Hidden_DD_Details__c;
                billAcct.Direct_Debit_Type__c = taskRec.Hidden_DD_Type__c;
                billAcct.Direct_Debit__c = taskRec.Hidden_Direct_Debit__c;
                billAcct.Direct_Debit_Commencement_Date__c = taskRec.Hidden_DD_Commencement_Date__c;
                billAcctToUpdate.add(billAcct);
            }
        }
        update billAcctToUpdate;
    }
    
    public static testmethod void test_updateDDFieldsOnBillAcct(){
        Account acc = new Account(name='test account');
        insert acc;
        
        Billing_Account__c baMailing = new Billing_Account__c(name='test', customer__c=acc.id,
                                            Billing_Address_Same_As__c='Customer Mailing'
                                            );
        insert baMailing;
        Task task1 = new Task(whatId = baMailing.id, Type = 'Direct Debit', Hidden_Direct_Debit__c = true, Hidden_DD_Type__c= 'test', Hidden_DD_Details__c = 'test', Hidden_DD_Commencement_Date__c = Date.today());
        insert task1;
        task1.Status = 'Completed';
        test.startTest();
        update task1;
        test.stopTest();
        baMailing = [Select id, Direct_Debit_Details__c, Direct_Debit_Type__c, Direct_Debit__c, Direct_Debit_Commencement_Date__c from Billing_Account__c where id = :baMailing.id];
        System.assertEquals(task1.Hidden_DD_Details__c, baMailing.Direct_Debit_Details__c);
        System.assertEquals(task1.Hidden_DD_Type__c, baMailing.Direct_Debit_Type__c );
        System.assertEquals(task1.Hidden_Direct_Debit__c, baMailing.Direct_Debit__c );
        System.assertEquals(task1.Hidden_DD_Commencement_Date__c, baMailing.Direct_Debit_Commencement_Date__c );
    }
}