/*
    Type:       Utilities
    Purpose:    Allows users to access the CaseTypeSettings custom setting

    Used By:    Too much to mention
    ---------------------------------------------------------------
    History:

    13-Oct-2011 J.Pe (Davanti Consulting)    Created

*/
public without sharing class CaseTypeSettingUtil{

    /* PUBLIC METHOD */
    public static List<RecordType> getAutoSuspendCaseType(){
        return getCaseTypesBasedOnSetting(CaseTypeSettings__c.Is_Auto_Suspend__c.getDescribe().getName());
    }

    public static List<RecordType> getCreateCaseType(){
        return getCaseTypesBasedOnSetting(CaseTypeSettings__c.Is_Create_Case__c.getDescribe().getName());
    }
    
    public static List<RecordType> getProcessCaseType(){
        return getCaseTypesBasedOnSetting(CaseTypeSettings__c.Is_Process__c.getDescribe().getName());
    }
    
    public static List<RecordType> getQuickNotesCaseType(){
        return getCaseTypesBasedOnSetting(CaseTypeSettings__c.Is_Quick_Notes__c.getDescribe().getName());
    }
    
    public static List<RecordType> getCaseTypesBasedOnSetting(String fieldName){
        Map<Decimal, RecordType> createCaseTypeMap = new Map<Decimal, RecordType>();
        for(CaseTypeSettings__c ctsRec: CaseTypeSettings__c.getAll().values()){
            if(ctsRec.get(fieldName)!= null && ((boolean)ctsRec.get(fieldName))){
                RecordType rt = allCaseRecordTypesMap.get(ctsRec.Name);
                if (rt==null || (ctsRec.Visualforce_Page__c!=null && !ctsRec.Visualforce_Page__c.trim().equals(''))){
                    createCaseTypeMap.put(ctsRec.Order__c, new RecordType(Name = ctsRec.Name, DeveloperName = new PageReference('/apex/'+ctsRec.Visualforce_Page__c).getURL()));
                }else{
                    createCaseTypeMap.put(ctsRec.Order__c, rt);
                }
            }
        }
        List<Decimal> keysOrdered = new List<Decimal>(createCaseTypeMap.keySet());
        keysOrdered.sort();
        List<RecordType> temp = new List<RecordType>();
        for(Decimal key:keysOrdered){
            temp.add(createCaseTypeMap.get(key));
        }
        return temp;
    }
    
    /* PRIVATE METHOD */
    private static Map<String, RecordType> allCaseRecordTypesMap{
        get{
            if(allCaseRecordTypesMap==null){
                allCaseRecordTypesMap = new Map<String, RecordType>();
                List<RecordType> allCaseRecordTypes = [Select id, Name, DeveloperName, SobjectType from RecordType where SobjectType = 'Case'];
                for(RecordType rType: allCaseRecordTypes ){
                    allCaseRecordTypesMap.put(rType.DeveloperName, rType);
                }
            }return allCaseRecordTypesMap;
        }set;
    }
}