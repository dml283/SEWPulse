public with sharing class PortalHomeKAMController {
    /*
    Type:       Controller
    Purpose:    Gets the key customer manager details

    ---------------------------------------------------------------
    History:

    01-Jun-2011 D.Thong (Salesforce)    Created

    */
    public User keyAccountMgr {
        get {
            return WaterMAPUtil.GetKeyAccountMgrForPortalUser();
        }
        private set;
    }

    public Boolean IsKeyAccount {
        get {
            // assume that the user is always there!
            User user = [Select ContactId, AccountId
                        From  User
                        Where Id = :UserInfo.getUserId() LIMIT 1];

            If (user.AccountId != null) {
                Account account = [Select OwnerId, Is_Key_Customer__c from Account
                                    Where Id = :user.AccountId LIMIT 1];

                return account.Is_Key_Customer__c;
            }
            return false;
        }
        private set;
    }

    public PortalHomeKAMController() {
    }

    private static TestMethod void testme() {
        Account a;
        Contact c;
        Id uid = UserInfo.getUserId();
        a = new Account(name = 'TEST ACCOUNT');
        Database.insert(a);
        c = new Contact(AccountId = a.id, lastname = 'lastname');
        Database.insert(c);

        Profile p = [select id from profile where name = 'SEW WaterMAP Portal User'];

        String testemail = 'puser000@amamama.com';
        User pu = new User(profileId = p.id, username = testemail, email = testemail,
                           emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                           languagelocalekey = 'en_US', timezonesidkey = 'America/Los_Angeles',
                           alias='cspu', lastname='lastname', contactId = c.id);

        Database.insert(pu);
        System.runAs(pu) {
            PortalHomeKAMController controller = new PortalHomeKAMController();
            System.assertEquals(uid, controller.keyAccountMgr.id);
            boolean isKAM = controller.IsKeyAccount;
        }
    }

}