trigger TaskTrigger on Task (before insert, before update, after update) {
    if(Trigger.isBefore && (Trigger.isInsert)){
        for(Task taskRec: Trigger.new){
            if (taskRec.Interaction_Type__c != null && !(taskRec.Interaction_Type__c.equals(taskRec.Type))
                    && taskRec.Type == null){
                taskRec.Type = taskRec.Interaction_Type__c;
            }
        }
    }
    if(Trigger.isAfter && Trigger.isUpdate){
        List<Task> directDebitTasksChangedToComplete = new List<Task>();
        for(Task taskRec: Trigger.new){
            if('Direct Debit'.equals(taskRec.Type) && 'Completed'.equals(taskRec.Status) 
                    && !('Completed'.equals(Trigger.oldmap.get(taskRec.id).Status))){
                directDebitTasksChangedToComplete.add(taskRec);
            }
        }
        if(!directDebitTasksChangedToComplete.isEmpty()){
            TaskUtil.updateDDFieldsOnBillAcct(directDebitTasksChangedToComplete);
        }
    }
}