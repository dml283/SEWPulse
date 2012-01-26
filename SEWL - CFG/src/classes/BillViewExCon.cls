/*
    Type:       Controller Extension
    Purpose:    Controls the Bill View VF page
    Used By:    BillView
    ---------------------------------------------------------------
    History:

    24-Nov-2011 M.Watson (Salesforce)		Created
    01-Dec-2011 Ji Zhang (Coretec Solutions)Updated add new parameters to redirect page

*/

public with sharing class BillViewExCon {
	
	public Billing_Account__c billingAcc {get; set;}

    public BillViewExCon(ApexPages.StandardController stdController) {
    	billingAcc = (Billing_Account__c)stdController.getRecord();
    }
    
    public PageReference billView(){
 		ABNote_Settings__c ab = ABnote_Settings__c.getOrgDefaults();
 		String baseURL;
 		
 		if (!Test.isRunningTest())
 			baseURL = ab.Server_Base_URL__c;
 		else
 			baseURL = 'http://foo.com';
 		
 		//PageReference pageRef = new PageReference('http://172.31.80.28/sewcustservice.aspx');
 		PageReference pageRef = new PageReference(baseURL);
 		Map<String, String> param = Apexpages.currentPage().getParameters();
        String CustNumber = param.get('CustNumber');
 		String billNumber1 = param.get('billNumber1');
 		
 		if(billNumber1 == '' || billNumber1 == null) {
                ApexPages.addmessage(
                new ApexPages.message(ApexPages.severity.ERROR,'Billing account has no Last Bill Number')
                );
                return null;     			
 		}
 		billNumber1 = formatBillNumber(billNumber1);
 		
 		pageRef.getParameters().put('CustNumber', CustNumber);
 		pageRef.getParameters().put('UserId', 'SEWUSER');
 		pageRef.getParameters().put('Password', 'sewuser');
 		pageRef.getParameters().put('BillNumber1', billNumber1);
 		
 		incrementTrackingCounter();
		
 		//CustNumber=10002018&UserId=SEWUSER&Password=sewuser&BillNumber1=Inv000049		
 		pageRef.setRedirect(true);
 		return pageRef;

    }
    
    // private method to format bill number
    private String formatBillNumber(String bn){
    	String retVal = 'Inv';
    	Integer wholeLen = 6;
    	Integer len = bn.length();
    	
    	for(Integer i = 0; i < wholeLen - len; i++){
    		retVal = retVal + '0';
    	}
    	return (retVal = retVal + bn);
    }
    
    // ensures that all views are tracked in the Track_Bill_View__c custom object
	public Boolean incrementTrackingCounter() {
		String currentMonth = string.valueOf(date.today().month());
		String currentYear = string.valueOf(date.today().year());
		Track_Bill_View__c trackView;

		// check to see if existing master tracking record exists for this month
		List <Track_Bill_View__c> trackViews = [SELECT Id, Counter__c FROM Track_Bill_View__c WHERE Year__c = :currentYear AND Period__c = :currentMonth LIMIT 1];
		Integer listSize = trackViews.size();
		
		// if no tracking record exists then create one
		if(listSize == 0) {
			trackView = new Track_Bill_View__c();
			trackView.Period__c = currentMonth;
			trackView.Year__c = currentYear;
			trackView.Counter__c = 1;
		}
		// else increment the counter
		else {
			trackView = trackViews[0];
			trackView.Counter__c = trackView.Counter__c + 1;				
		}			
		
		// insert/update tracking record
		try {
			upsert trackView;
			return true;			
		}
		catch (DmlException e) {
			ApexPages.addMessages(e);
			return false;
		}
	}

    public static testmethod void testBillView() {
        Account acc = new Account(name='test parent');
        insert acc;
        Billing_Account__c ba = new Billing_Account__c(name='test', customer__c=acc.Id, HiAF_Account_Number__c='1234', Last_Bill_Number__c='54');
        insert ba;  
        String CustNumber = '1234';
        String billNumber1 = '54';  	
		
		Test.startTest();
		
        PageReference pageRef = Page.billView;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('CustNumber', CustNumber); 

        ApexPages.StandardController sc = new ApexPages.StandardController(ba);
        BillViewExCon excon = new BillViewExCon(sc);        

        // run billView test with no bill number (error)
        excon.billView();
     
        // run billView test with correct parameters
        pageRef.getParameters().put('BillNumber1', billNumber1);    
        excon.billView();
        
        Test.stopTest();
    }
    
}