/*
    Type:       VF Controller
    Purpose:    Exposes Site Forgot password functionality. 

    Used By:    ForgotPassword page
    ---------------------------------------------------------------
    History:


*/
public with sharing class ForgotPasswordController {
    public String username {get; set;}

    public ForgotPasswordController() {}

    public PageReference forgotPassword() {

        String newusername = username;
        /*
        // append site prefix + .sewl.com.au if no @ in the username
        if (!newusername.contains('@')) {
            String prefix = Site.getPrefix();
            if (prefix != null) {
                prefix=prefix.replace('/', '');
                newusername = newusername + '@' + prefix + '.sewl.com.au';
            } else {
                newusername = newusername + '@sewl.com.au';
            }

                        // append the sandbox name if any
            String sandbox = PortalSettings__c.getInstance().Sandbox_Name__c;
            if (sandbox != null && sandbox != '')
                newusername += '.' + sandbox;
        }
        */
        newusername = PortalUtil.convertUsername(newusername );

        boolean success = Site.forgotPassword(newusername);
        PageReference pr = Page.ForgotPasswordConfirm;
        pr.setRedirect(true);

        if (success) {
            return pr;
        }
        return null;
    }

     public static testMethod void testForgotPasswordController() {
        // Instantiate a new controller with all parameters in the page
        ForgotPasswordController controller = new ForgotPasswordController();
        controller.username = 'test@salesforce.com';

        System.assertEquals(controller.forgotPassword(),null);

        controller.username = 'test';

        System.assertEquals(controller.forgotPassword(),null);
    }
}