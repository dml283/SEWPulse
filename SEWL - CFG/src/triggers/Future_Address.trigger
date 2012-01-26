trigger Future_Address on Future_Address__c (after update) {
/*
    Type:       Trigger
    Purpose:    (i) Process Flag is 'Y', then
    				- update the address on account
    				- set process flag = 'n'
    				- set done flag = 'Y'

    ---------------------------------------------------------------
    History:
        22-Sep-2011 - D.Thong (SFDC)    Created
*/

	List <Id> futureAddressIdList = new List <Id>();

	for (Future_Address__c fa : trigger.new) {
		if (fa.Process__c) {
			futureAddressIdList.add(fa.id);
		}
	}

	if (!futureAddressIdList.isEmpty()) {
		Future_Address.ProcessFutureAddress(futureAddressIdList);
	}


}