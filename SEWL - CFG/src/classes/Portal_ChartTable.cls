public with sharing virtual class Portal_ChartTable {

/*
    Type:       Virtual Controller Extension
    Purpose:    Super class that contains common methods for charting
    			and tables

    Used By:    
    ---------------------------------------------------------------
    History:

    23-Jun-2011 D.Thong (Salesforce)    Created

*/

	/* PUBLIC PROPERTIES */
	
	/* PRIVATE PROPERTIES */
	private AggregateResult[] consumptionYear {
		get {
			// Used to calculate the min and max consumption
			if (bAcct != null && bAcct.Id != null && consumptionYear != null) {
				consumptionYear
					= [SELECT Financial_Year__c 
						FROM Consumption_and_Charge__c
						WHERE Billing_Account__c = :bAcct.Id
						GROUP BY Financial_Year__c ];
			}
			return consumptionYear;
		}
		private set;
	}
	
	private Decimal minConsumptionYear { get; set; }
	private Decimal maxConsumptionYear { get; set; }
	
	/* CONSTRUCTOR */
    public Billing_Account__c bAcct {get; set;}

    public Portal_ChartTable(ApexPages.StandardController controller) {
        bAcct = (Billing_Account__c) controller.getRecord();
    }


}