public with sharing class QASTest_Controller {


	public String dpid { get; set; }
	public String address { get; set;}

	public String qasiFrameURL { 
		get { 
			if (qasiFrameURL == null) {
				try {
					qasiFrameURL = QASiFrame.getURL();
				} catch (Exception e) {
					ApexPages.addMessages(e);
				}
			}	
			return qasiFrameURL;
		}
		private set; 
	}

	public QASTest_Controller() {
		
	}
	
	public void PopulateDPID() {
		dpid = QASiFrame.getDPID(address);
	}
	
	private static TestMethod void testMe() {
		QASTest_Controller c = new QASTest_Controller();
		c.PopulateDPID();
		String dpid = c.dpid;
		String qasiFrameURL = c.qasiFrameURL;
	}

}