global with sharing class SiteHomeController {

/*
    Type:       VF Controller
    Purpose:    Checks to see if the user is authenticated and 
    			redirects appropriately

    Used By:    SiteHome
    ---------------------------------------------------------------
    History:


*/

    global SiteHomeController () {}
    
    global PageReference GoHome () {
        system.debug('***here***');
        if (UserInfo.getUserType() == 'Guest'){
            return new PageReference (Site.getPrefix() + '/SiteLogin'); 
        }else{        
            return new PageReference (Site.getPrefix() + '/home/home.jsp');
        }
    }

    global static testMethod void testSiteHomeController () {
        // Instantiate a new controller with all parameters in the page
        SiteHomeController controller = new SiteHomeController ();
        controller.GoHome();
    }

}