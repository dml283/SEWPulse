trigger QAS_Future_Address_BIBU on Future_Address__c (before update) {
experianqas.QASTriggerHelper qas = new
experianqas.QASTriggerHelper(trigger.new[0].getSObjectType().getDescribe().getName());

if (qas.shouldPopup) {
for (Integer currentRecord= 0; currentRecord< trigger.new.size(); ++currentRecord) {
if (trigger.new[currentRecord].Updated_Touchpoints__c=='NullOut') {
trigger.new[currentRecord].Updated_Touchpoints__c='';
} else {
SObject old;
if (trigger.isInsert== false) {
old = trigger.old[currentRecord];
}
trigger.new[currentRecord].Updated_Touchpoints__c=
qas.getUpdatedTouchpointDelimited(old, trigger.new[currentRecord]);
if (trigger.new[currentRecord].Updated_Touchpoints__c!='') {
trigger.new[currentRecord].Updated_Touchpoints_Timestamp__c = datetime.now();
}
}
}
}
}