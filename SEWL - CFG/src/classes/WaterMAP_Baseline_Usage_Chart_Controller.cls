public with sharing class WaterMAP_Baseline_Usage_Chart_Controller {
  /* PUBLIC PROPERTIES */

  // the submission
  public WaterMAP_Submission__c wmapSub {get; set;}

  // the most recent year
  public String recentYear {
    get {
      if (wmapSub != null ) return WaterMAPUtil.getYearBeforePeriod(wmapSub.Year__c);
      return null;
    }
  }

  // number of years to display baseline usage
  public Integer noOfYearsToDisplayForBaseline{
    get{
      if(noOfYearsToDisplayForBaseline==null){
        noOfYearsToDisplayForBaseline = 2; // default to past 3 years
      }return noOfYearsToDisplayForBaseline;
    }set;
  }

  // List of ordered Baseline Lines ordered by period Name
  public List<BaselineLine> orderedBaselineLines {
    get {
      return getOrderedBaselineLines();

    } private set;
  }

  // Generates chart data for Google Charts
  public String googleChartURL {
    get {
      return GetChartURL();
    }
  }

  /* PRIVATE PROPERTIES */

  // which years are we displaying
  private String[] yearsToDisplay {
    get {
      return WaterMAPUtil.getLastNYearsInOrder(recentYear, noOfYearsToDisplayForBaseline);
    }
  }

  // the chart data
  private List<ChartSeries> chartSeriesData {
    get {
//      if (chartSeriesData == null) {
        // initialise based on yearsToDisplay
        List<ChartSeries> chartSeriesDataTemp = InitChartSeries();
        // populate with the information
        PopulateChartSeriesData(chartSeriesDataTemp);
        this.ChartSeriesData = chartSeriesDataTemp;
//      }
      return chartSeriesData;
    }
    set;
  }

  /* CONSTANTS */
  private static String[] MONTHSLABEL = new String[] {'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'};

  /* CONSTRUCTOR */
  public WaterMAP_Baseline_Usage_Chart_Controller () {}

  /* PUBLIC METHODS */
  // no op
  public PageReference NoOp() {return null;}

  /* INNER CLASSES */
  // class to represent a Baseline line fully, including the Baseline, usage and calculated average
  private class BaselineLine {
    public String  periodName {get; set;}
    public String  year {get; set;}
    public Decimal usage {get; set;}
    public Decimal klperBaseline {
      get {
        if (usage != null) {
          return (usage).setScale(2);
        }
        return null;
      }
    }

    public BaselineLine(String periodName, String year, Decimal usage) {
      this.periodName = periodName;
      this.year = year;
      this.usage = usage;
    }
  }

  // class to represent a chart line
  private class ChartLine {
    public String x { get; set; }
    public Decimal y { get; set; }

    public ChartLine(){}
    public ChartLine(String x, Decimal y) {
      this.x = x;
      this.y = y;
    }
  }

  // represents a whole series of data
  private class ChartSeries {
    public String serieslabel { get; set; }
    public List<ChartLine> chartdata { get; set; }

    public ChartSeries(String serieslabel){ this.serieslabel = serieslabel;}
    public ChartSeries(String serieslabel, List<ChartLine> chartdata){
      this.serieslabel = serieslabel;
      this.chartdata = chartdata;
    }
  }


  /* PRIVATE METHODS */
  private List<BaselineLine> GetOrderedBaselineLines() {
    // gets an ordered list of Baseline lines by
    // 1. Getting all consumption
    // 2. Matching the consumption period to the Baseline line
    // 3. Creating a Baseline line entry
    // n.b. if recent year Baselines is populated, then it is taken from there
    // rather than queried. This allows the page to not be saved before
    // generating the graph
    // assumes: that if no conumption is there, the Baseline is not valid!!

    // our final output
    List<BaselineLine> BaselineLines = new List<BaselineLine>();

    // get ordered consumption
    List <Consumption_and_Charge__c> orderedCharges = WaterMAPUtil.getWaterMAPAllChargesInOrder(wmapSub.WaterMAP__c, yearsToDisplay);

    // loop through the charges in order, matching the Baseline and building
    // the line as we go through
    for (Consumption_and_Charge__c charge : orderedCharges) {

      BaselineLine line = new BaselineLine(charge.Name, charge.Financial_Year__c, charge.Water_Volume__c != null ? charge.Water_Volume__c : 0);
      BaselineLines.add(line);
    }

    return BaselineLines;
  }

  // builds the google chart URL
  private String GetChartURL() {

    // base url
    String url = 'http://chart.apis.google.com/chart?';
    // chart size & type
    url += 'chs=500x300&cht=lc';

    String seriesLabel;
    String ydata;
    Decimal maxy=1;

    // series label and y data
    for (ChartSeries s : chartSeriesData) {
      // build the series label
      if (seriesLabel == null)
        seriesLabel = s.seriesLabel;
      else
        seriesLabel += '|' + s.seriesLabel;

      // build the y data
      String yseriesdata;
      for (ChartLine line : s.chartdata) {
        String formattedY;
        System.debug(line);
        if (line.y != null)
          formattedY = line.y.toPlainString();
        else
          formattedY = '_';
        if (yseriesdata != null)
          // _ indicates null
          yseriesdata += ',' + formattedY;
        else
          // _ indicates null
          yseriesdata = formattedY;

        if (maxy < line.y) maxy = line.y;
      }
      if (ydata == null)
        ydata = yseriesdata;
      else
        ydata += '|' + yseriesdata;

    }
    url += '&chdl='+seriesLabel; // series label
    url += '&chd=t:' + ydata; // data

    // chart x-label
    String xlabel='';
    for (String mth : MONTHSLABEL) {
      xlabel+= '|' + mth;
    }

    url += '&chxl=0:' + xlabel;

    maxy = maxy * 1.1;

    // format axes
    url += '&chxr=0,0,12|1,0,' + maxy.toPlainString() + '&chxs=0,676767,11.5,0,lt,676767&chxt=x,y&chco=005F98,FF0000,70BF49,00BBDE';
    // everything else
    url += '&chds=0,' + maxy.toPlainString() + '&chdlp=b&chls=2|2|2&chma=5,5,5,25';
    // chart title
    url += '&chtt=Annual Water Usage (kL) for ' + wmapSub.WaterMAP__r.Customer__r.Name;

    System.debug(url);

    return url;

  }

  // generates an empty chart series with 12 months worth of data in each
  private List<ChartSeries> InitChartSeries() {
    List<ChartSeries> series = new List<ChartSeries>();
    for (String year : yearsToDisplay) {
      // build 12 months of lines
      List<ChartLine> lines = new List<ChartLine>();
      for (String month : MONTHSLABEL) {
        lines.add(new ChartLine(month, null));
      }

      series.add(new ChartSeries(year, lines));
    }
    return series;
  }

  // populates the chart data with the real stuff!
  private void PopulateChartSeriesData(List<ChartSeries> chartSeriesData) {
    // loop through the ordered lines and build a two-level map
    // Series (Period, line)
    Map<String, Map<String, BaselineLine>> BaselineSeriesMap = new Map<String, Map<String, BaselineLine>>();

    for (BaselineLine k : orderedBaselineLines) {
      Map<String, BaselineLine> BaselineLineMap = BaselineSeriesMap.get(k.year);
      // the series is not there, therefore create it
      if (BaselineLineMap==null) {
        BaselineLineMap = new Map<String, BaselineLine>();
        BaselineSeriesMap.put(k.year, BaselineLineMap);
      }

      // quarterly data (may need to interpolate later!)
      if (k.periodName.startsWith('Jan-Mar') || k.periodName.startsWith('Q4')) {
        BaselineLineMap.put('Jan', k);
        BaselineLineMap.put('Feb', k);
        BaselineLineMap.put('Mar', k);
      } else if (k.periodName.startsWith('Apr-Jun') || k.periodName.startsWith('Q3')) {
        BaselineLineMap.put('Apr', k);
        BaselineLineMap.put('May', k);
        BaselineLineMap.put('Jun', k);
      } else if (k.periodName.startsWith('Jul-Sep') || k.periodName.startsWith('Q1')) {
        BaselineLineMap.put('Jul', k);
        BaselineLineMap.put('Aug', k);
        BaselineLineMap.put('Sep', k);
      } else if (k.periodName.startsWith('Oct-Dec') || k.periodName.startsWith('Q2')) {
        BaselineLineMap.put('Oct', k);
        BaselineLineMap.put('Nov', k);
        BaselineLineMap.put('Dec', k);
      } else { // monthly data
        BaselineLineMap.put(k.periodName.substring(0, 3), k);
      }
    }

    // loop through the chart series data and populate it
    for (ChartSeries series : chartSeriesData) {
      // get the Baseline line data for that year
      Map<String, BaselineLine> BaselineLineMap = BaselineSeriesMap.get(series.serieslabel);

      if (BaselineLineMap != null && !BaselineLineMap.isEmpty()) {
        for (ChartLine line : series.chartData){
          BaselineLine Baselineline = BaselineLineMap.get(line.x);
          if (Baselineline != null)
            line.y = Baselineline.klperBaseline;
        }
      }
    }
  }

  private static testmethod void TestMe() {
    // create test data
    Account account = new Account();
    account.name = 'foo';
    insert account;

    Contact contact = new Contact();
    contact.LastName = 'Foo';
    contact.AccountId = account.id;
    contact.Title = 'x';
    contact.Phone = 'x';
    contact.Email = 'x@x.com';
    insert contact;

    Property__c prop = new Property__c();
    prop.Universal_Id_c__c = 'sdgfsdgf';
    prop.Name = 'Test Property';
    insert prop;

    Billing_Account__c billAcc = new Billing_Account__c();
    billAcc.Name = 'asetwetwrt';
    billAcc.Customer__c = account.id;
    billAcc.Property__c = prop.id;
    insert billAcc;

    Watermap__c waterMap = new Watermap__c();
    waterMap.Name = 'Test Me';
    waterMap.Customer__c = account.id;
    waterMap.Status__c = 'Not Started';
    waterMap.Billing_Account__c = billAcc.id;
    waterMAP.KBAI_Type__c = 'Average';
    waterMAP.KBAI_Description__c = 'Widget';
    insert waterMap;

    WaterMAP_Submission__c waterMapSub = new WaterMAP_Submission__c();
    waterMapSub.Customer__c = account.id;
    waterMapSub.Prepared_By__c = contact.id;
    waterMapSub.Prepared_By__r = contact;
    waterMapSub.Authorised_By__c = contact.id;
    waterMapSub.Authorised_By__r = contact;
    waterMapSub.Status__c = 'Not Started';
    waterMapSub.Watermap__c = waterMap.id;
    waterMapSub.Watermap__r = waterMap;
    waterMapSub.Year__c = '2011/12';
    insert waterMapSub;

    Consumption_and_Charge__c charge = new Consumption_and_Charge__c();
    charge.Water_Volume__c = 1000;
    charge.Billing_Account__c = billAcc.id;
    charge.Financial_Year__c = '2010/11';
    charge.Name = 'Jan-Mar 2010/11';
    insert charge;

    charge = new Consumption_and_Charge__c();
    charge.Water_Volume__c = 2000;
    charge.Billing_Account__c = billAcc.id;
    charge.Financial_Year__c = '2010/11';
    charge.Name = 'Apr-Jun 2010/11';
    insert charge;

    charge = new Consumption_and_Charge__c();
    charge.Water_Volume__c = 3000;
    charge.Billing_Account__c = billAcc.id;
    charge.Financial_Year__c = '2010/11';
    charge.Name = 'Jul-Sep 2010/11';
    insert charge;

    charge = new Consumption_and_Charge__c();
    charge.Water_Volume__c = 4000;
    charge.Billing_Account__c = billAcc.id;
    charge.Financial_Year__c = '2010/11';
    charge.Name = 'Oct-Dec 2010/11';
    insert charge;

    charge = new Consumption_and_Charge__c();
    charge.Water_Volume__c = 1000;
    charge.Billing_Account__c = billAcc.id;
    charge.Financial_Year__c = '2009/10';
    charge.Name = 'Oct-Dec 2009/10';
    insert charge;

    List <Key_Business_Activity_Indicator__c> Baselines = new List<Key_Business_Activity_Indicator__c>();

    Key_Business_Activity_Indicator__c Baseline = new Key_Business_Activity_Indicator__c();
    Baseline.WaterMAP__c = waterMap.id;
    Baseline.Count__c = 100;
    Baseline.Period__c = 'Jan-Mar 2010/11';
    Baseline.Year__c = '2010/11';
    insert Baseline;
    Baselines.add(Baseline);

    Baseline = new Key_Business_Activity_Indicator__c();
    Baseline.WaterMAP__c = waterMap.id;
    Baseline.Count__c = 200;
    Baseline.Period__c = 'Apr-Jun 2010/11';
    Baseline.Year__c = '2010/11';
    insert Baseline;
    Baselines.add(Baseline);

    Baseline = new Key_Business_Activity_Indicator__c();
    Baseline.WaterMAP__c = waterMap.id;
    Baseline.Count__c = 300;
    Baseline.Period__c = 'Jul-Sep 2010/11';
    Baseline.Year__c = '2010/11';
    insert Baseline;
    Baselines.add(Baseline);

    Baseline = new Key_Business_Activity_Indicator__c();
    Baseline.WaterMAP__c = waterMap.id;
    Baseline.Count__c = 400;
    Baseline.Period__c = 'Oct-Dec 2010/11';
    Baseline.Year__c = '2010/11';
    insert Baseline;
    Baselines.add(Baseline);

    Baseline = new Key_Business_Activity_Indicator__c();
    Baseline.WaterMAP__c = waterMap.id;
    Baseline.Count__c = 400;
    Baseline.Period__c = 'Oct-Dec 2009/10';
    Baseline.Year__c = '2009/10';
    insert Baseline;
    Baselines.add(Baseline);


    WaterMAP_Baseline_Usage_Chart_Controller controller = new WaterMAP_Baseline_Usage_Chart_Controller();

    controller.wmapSub = waterMapSub;
    System.assertEquals('2010/11', controller.recentYear);
    System.assertEquals(2, controller.noOfYearsToDisplayForBaseline);

    List<BaselineLine> lines = controller.orderedBaselineLines;
    System.assertEquals(lines.size(), 5);
    String url =controller.googleChartURL;
    controller.NoOp();

    controller.wmapsub.WaterMAP__r.KBAI_Type__c = 'Sum';



  }
}