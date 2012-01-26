/*
    Type:       Extension Controller
    Purpose:    Portal page to call meter readings history

    Used By:    VF PortalMeterReadingsHistory
    ---------------------------------------------------------------
    History:
    			18-Dec-11 Ji Zhang (CoreTech Solutions) created

*/

public class PortalMeterReadingsHistoryExCon {
	
	private ApexPages.StandardController stdCon;
    private MeterReadingsHistoryExCon meterReadingsHistoryExCon;
    
    // current selected Meter_Details__c instance for passing to make wsutil out call
    public Meter_Details__c currentMeter{
    	get{
    		if(currentMeter == null){
                currentMeter = new Meter_Details__c();
            }
            return currentMeter;
    	}
    	set;
    }
    
 	// current selected Meter_Details__c id
    public Id currentMeterId{get;set;}
    
    // number meter details of one property
    // control render part content of VF page
    public Integer meterListNum{
    	get{
    		if(meterList!=null)meterListNum = meterList.size();
    		return meterListNum;
    	}
    	set;
    }
    
    private Billing_Account__c billingAcct {
        get{
            return (Billing_Account__c)stdCon.getRecord();
        }
    }
    
 	private Property__c property {
 		get{
 			if(property == null){
	 			List<Property__c> pList = [SELECT Id FROM Property__c WHERE Id =: billingAcct.Property__c];
	 			if(!pList.isEmpty()){
	 				property = pList[0];
	 			}
 			}
 			return property;
 		}
 		set;
 	}
    
    public List<Meter_Details__c> meterList {get;set;}
    
    public Map<Id, Meter_Details__c> meterMap {
    	get{
    		if(meterMap == null & meterList != null){
    			meterMap = new Map<Id, Meter_Details__c>();
    			for(Meter_Details__c m : meterList){
    				meterMap.put(m.id, m);
    			}	
    		}
    		return meterMap;
    	}
    	set;
    }
    
    public List<WSUtil_Property.MeterReading> meterReadings{
    	get{
    		if(currentMeterid != null){
	    		currentMeter = meterMap.get(currentMeterId);
	    		this.meterReadingsHistoryExCon = new MeterReadingsHistoryExCon(new ApexPages.StandardController(currentMeter));	
	    		meterReadings = this.meterReadingsHistoryExCon.meterReadings;
	    	}else{
	    		meterReadings = null;
	    	}
	    	System.debug('### meterReadings:' + meterReadings);
	    	return meterReadings;
    	}
    	set;
   	}
    
    public PortalMeterReadingsHistoryExCon(ApexPages.StandardController controller) {
        this.stdCon = controller; 
        currentMeterId = ApexPages.currentPage().getParameters().get('cid');
        if(meterList == null && property != null){
    			meterList = new List<Meter_Details__c>();
    			meterList = [SELECT Name, Meter_Type__c, Pit_Reference__c FROM Meter_Details__c WHERE Property__c =: this.property.Id];
    	}
    	
    	if(meterList.size()== 1 && currentMeterId == null){	
	        currentMeterId = meterList[0].Id;
	    	this.meterReadingsHistoryExCon = new MeterReadingsHistoryExCon(new ApexPages.StandardController(currentMeter));	
		    meterReadings = this.meterReadingsHistoryExCon.meterReadings;
    	}
    }
    
    public List<SelectOption> getMeterListOption() {
        List<SelectOption> options = new List<SelectOption>();
        // if only one meter object, select it as default and display its history 
        if(meterList.size()==1){
	        currentMeter = meterList[0];
        	options.add(new SelectOption(meterList[0].Id, meterList[0].Name));
        }else{
	        options.add(new SelectOption('', '--None--'));
	        for (Integer i = 0; i < meterList.size(); i++){
	            options.add(new SelectOption(meterList[i].Id, meterList[i].Name));
	        }
        }
        return options;
    }
    
    public static testmethod void test_PortalMeterReadingsHistoryExCon(){
    	Account testAcct = new Account(name='test account');
        insert testAcct;
        
        Property__c testProperty = new Property__c(name='test property');
        insert testProperty;
        
        Billing_Account__c testBa = new Billing_Account__c
        						(name='test',
        						 customer__c=testAcct.Id, 
        						 HiAF_Account_Number__c='1234',
        						 property__c = testProperty.Id);
        insert testBa;
        
        Meter_Details__c testMeter = new Meter_Details__c(name='test meter', property__c = testProperty.Id);
        insert testMeter;
        
    	PortalMeterReadingsHistoryExCon excon = new PortalMeterReadingsHistoryExCon(new ApexPages.StandardController(testBa));
    	excon.currentMeter = null;
    	System.assert(excon.currentMeter!=null);
    	excon.currentMeterId = testMeter.Id;
    	//excon.meterList = null;

    	System.assert(excon.meterList!=null);
    	System.assert(excon.meterListNum == 1);
    	excon.meterReadings = null;
    	System.assert(excon.meterReadings!=null);
    	excon.getMeterListOption();
    	
    	Meter_Details__c testMeter2 = new Meter_Details__c(name='test meter2', property__c = testProperty.Id);
        insert testMeter2;
        
    	excon = new PortalMeterReadingsHistoryExCon(new ApexPages.StandardController(testBa));

    	System.assert(excon.meterListNum == 2);
    	excon.getMeterListOption();
    	excon.currentMeterId = null;
    	System.assert(excon.meterReadings==null);
    }
}