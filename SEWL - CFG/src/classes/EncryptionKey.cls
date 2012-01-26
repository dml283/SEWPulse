public without sharing class EncryptionKey {

    public static String getKey(String keyType) {
        try {
            EncryptedKey__c key = [select key1__c, key2__c, key3__c, key4__c, key5__c, key6__c from EncryptedKey__c 
                                    where name = :keyType LIMIT 1];
            
            if (key != null) {
                String keyValue = key.key1__c;
                if (key.key2__c != null)
                    keyValue += key.key2__c;
                if (key.key3__c != null)
                    keyValue += key.key3__c;
                if (key.key4__c != null)
                    keyValue += key.key4__c;
                if (key.key5__c != null)
                    keyValue += key.key5__c;
                if (key.key6__c != null)
                    keyValue += key.key6__c;
                return keyValue;
            }


            return null;        
                                     
        } catch (QueryException e) {
            return null;
        }       
    }
    
    public static testmethod void TestMe() {
        EncryptedKey__c key = new EncryptedKey__c();
        key.Name = 'TESTING123';
        key.Key1__c = 'ABC';
        key.Key2__c = 'DEF';
        key.Key3__c = 'GHI';
        key.Key4__c = 'JKL';
        key.Key5__c = 'MNO';
        key.Key6__c = 'PQR';
        insert key;
        System.assertEquals(EncryptionKey.getKey('TESTING123'), 'ABCDEFGHIJKLMNOPQR');
    }
}