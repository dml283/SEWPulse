public with sharing class PortalAvgDailyUsage_ChartExCon extends Portal_ChartTable{

/*
    Type:       Controller Extension
    Purpose:    

    Used By:    
    ---------------------------------------------------------------
    History:

    18-Jan-2011 Ji Zhang (Coretec Solutions)    Created

*/

	
	private List<Consumption_and_Charge__c> consumptionCharges {
		get {
			if (bAcct != null && bAcct.Id != null && consumptionCharges == null) {
				consumptionCharges = [SELECT Name, Water_Volume__c, Number_of_Days__c, End_Date__c 
										 FROM Consumption_and_Charge__c 
										 WHERE Billing_Account__c =: bAcct.Id];
			}
			return consumptionCharges;
		}
		private set;
	}
	
	public PortalAvgDailyUsage_ChartExCon(ApexPages.StandardController controller){
		super(controller);
		System.debug('###bacc' + bAcct.id);
		
		//consumptionChargeList = [SELECT Name, Water_Volume__c, Number_of_Days__c FROM Consumption_and_Charge__c WHERE Billing_Account__c =: bAcct.Id];
		System.debug('###consuption' + consumptionCharges);
	}
	
	private Integer maxAverage{
		get{
			if(maxAverage == null){
				maxAverage = 0;
			}
			return maxAverage;
		}
		set;
	}
	
	public List<Data> getData(){
		List<Data> data = new List<Data>();
		for(Consumption_and_Charge__c c : consumptionCharges){
			Integer average = 0;
			if(c.Water_Volume__c != null && c.Number_of_Days__c != null){
				average = Integer.valueOf(Math.Round(c.Water_Volume__c * 1000 / c.Number_of_Days__c));
			}
			if(average > maxAverage) maxAverage = average;
			String period = c.Name;
			period = period.substring(0, period.length()-7);
			period = period + ' ' + (String.valueOf(c.End_Date__c)).substring(0,4);
			data.add(new Data(period, average));
		}
		return data;
	}
	
	
	//wrap class
	public class Data {
		public String period {get; set;}
		public Integer averageDailyUsage {get; set;}
		public Data (String period, Integer averageDailyUsage){
			this.period = period;
			this.averageDailyUsage = averageDailyUsage;
		}	
	}
	
	public String googleChartURL {
        get {
            return GetChartURL();
        }
    }
	
	private String GetChartURL(){
		
		List<Data> tempData = getData();
		
	 	String url = 'http://chart.apis.google.com/chart?';
	 	// 0 to max
	 	url += 'chxr=0,0,' + (maxAverage+1000);
	 	// label
	 	url += '&chxl=1:';
	 	
	 	for(Data d : tempData){
	 		url += '|' + d.period;
	 		//system.debug(d.period);
	 	}
   		url += '&chxt=y,x';
   		url += '&chbh=a';
   		url += '&chs=700x400';
   		url += '&cht=bvs';
   		url += '&chco=4D89F9';
   		url += '&chds=0,' + maxAverage;
   		
   		url += '&chd=t:';
   		
   		for(Data d : tempData){
	 		url += d.averageDailyUsage + ',';
	 	}
	 	url = url.substring(0, url.length()-1);
	 	
   		url += '&chtt=Average+Daily+Usage';
		return url;
	}
}