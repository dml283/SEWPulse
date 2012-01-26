public without sharing class WSUtil_Task extends WSUtil{
	
	public class taskDetails {
        public String Subject {get;set;}
        public date ActivityDate {get;set;}
        public String Type {get;set;}
        public String WhatId {get;set;}
        public String Status {get;set;}
        public Boolean IsVisibleInSelfService{get;set;}
    }
    
    
	
	public Id createTask(taskDetails t){
		Task taskRec = new Task();
		
		taskRec.Subject = t.Subject;
        taskRec.ActivityDate = t.ActivityDate;
        taskRec.Type = t.Type;
        taskRec.WhatId = t.WhatId;
        taskRec.Status = t.Status;
        taskRec.IsVisibleInSelfService = t.IsVisibleInSelfService;
        taskRec.OwnerId = '00590000000OosiAAC';
        
        try{
        	insert taskRec;
        	System.debug('#### taskRec:' + taskRec);
        }catch(Exception ex){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Unknown error: '+ex.getMessage()));
        }
        
        
        return taskRec.Id; 
		
	}
}