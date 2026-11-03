public with sharing class RestaurantDashboardController {
  public class DashboardSummaryWrapper {
    @AuraEnabled
    public Integer todaysOrderCount { get; set; }
    @AuraEnabled
    public Integer pendingApprovalCount { get; set; }
    @AuraEnabled
    public Integer preparingOrderCount { get; set; }
    @AuraEnabled
    public Integer servedOrderCount { get; set; }
    @AuraEnabled
    public Decimal todaysSales { get; set; }
    @AuraEnabled
    public Integer availableTablesCount { get; set; }
    @AuraEnabled
    public Integer occupiedTablesCount { get; set; }
    @AuraEnabled
    public Integer cleaningTablesCount { get; set; }
  }

  public class TopSellingItemWrapper {
    @AuraEnabled
    public String itemName { get; set; }
    @AuraEnabled
    public String category { get; set; }
    @AuraEnabled
    public Decimal totalQuantity { get; set; }
    @AuraEnabled
    public Decimal totalRevenue { get; set; }
  }

  public class OrderDetailWrapper {
    @AuraEnabled
    public Id id { get; set; }
    @AuraEnabled
    public String orderNumber { get; set; }
    @AuraEnabled
    public String customerName { get; set; }
    @AuraEnabled
    public Boolean isVipCustomer { get; set; }
    @AuraEnabled
    public String tableName { get; set; }
    @AuraEnabled
    public Datetime orderDate { get; set; }
    @AuraEnabled
    public String status { get; set; }
    @AuraEnabled
    public Decimal subtotal { get; set; }
    @AuraEnabled
    public Decimal discountPercent { get; set; }
    @AuraEnabled
    public Decimal discountAmount { get; set; }
    @AuraEnabled
    public String discountStatus { get; set; }
    @AuraEnabled
    public Decimal taxRate { get; set; }
    @AuraEnabled
    public Decimal grandTotal { get; set; }
    @AuraEnabled
    public String cancellationReason { get; set; }
    @AuraEnabled
    public List<String> itemNames { get; set; }
  }

  @AuraEnabled
  public static DashboardSummaryWrapper getDashboardSummary() {
    DashboardSummaryWrapper summary = new DashboardSummaryWrapper();

    summary.todaysOrderCount = [SELECT COUNT() FROM Order__c];
    summary.pendingApprovalCount = [
      SELECT COUNT()
      FROM Order__c
      WHERE Discount_Status__c = 'Pending Approval'
    ];
    summary.preparingOrderCount = [
      SELECT COUNT()
      FROM Order__c
      WHERE Status__c = 'Preparing'
    ];
    summary.servedOrderCount = [
      SELECT COUNT()
      FROM Order__c
      WHERE Status__c = 'Served'
    ];

    AggregateResult[] salesAgg = [
      SELECT SUM(Grand_Total__c) totalSales
      FROM Order__c
      WHERE Status__c = 'Served'
    ];
    if (
      salesAgg != null &&
      !salesAgg.isEmpty() &&
      salesAgg[0].get('totalSales') != null
    ) {
      summary.todaysSales = (Decimal) salesAgg[0].get('totalSales');
    } else {
      summary.todaysSales = 0.0;
    }

    summary.availableTablesCount = [
      SELECT COUNT()
      FROM Restaurant_Table__c
      WHERE Status__c = 'Available'
    ];
    summary.occupiedTablesCount = [
      SELECT COUNT()
      FROM Restaurant_Table__c
      WHERE Status__c = 'Occupied'
    ];
    summary.cleaningTablesCount = [
      SELECT COUNT()
      FROM Restaurant_Table__c
      WHERE Status__c = 'Cleaning'
    ];

    return summary;
  }

  @AuraEnabled
  public static List<OrderDetailWrapper> getRecentOrders() {
    List<Order__c> orders = [
      SELECT
        Id,
        Name,
        Customer__r.Name,
        Customer__r.VIP_Customer__c,
        Table__r.Name,
        Table__r.Table_Number__c,
        Order_Date__c,
        Status__c,
        Subtotal__c,
        Discount_Percent__c,
        Discount_Amount__c,
        Discount_Status__c,
        Tax_Rate__c,
        Grand_Total__c,
        Cancellation_Reason__c,
        (
          SELECT Id, Menu_Item__r.Name, Quantity__c, Unit_Price__c
          FROM Order_Items__r
        )
      FROM Order__c
      ORDER BY CreatedDate DESC
      LIMIT 50
    ];

    List<OrderDetailWrapper> result = new List<OrderDetailWrapper>();
    for (Order__c ord : orders) {
      OrderDetailWrapper wrap = new OrderDetailWrapper();
      wrap.id = ord.Id;
      wrap.orderNumber = ord.Name;
      wrap.customerName = (ord.Customer__r != null)
        ? ord.Customer__r.Name
        : 'Walk-in Customer';
      wrap.isVipCustomer = (ord.Customer__r != null &&
      ord.Customer__r.VIP_Customer__c == true);

      String tDisplay = 'N/A';
      if (ord.Table__r != null) {
        if (ord.Table__r.Table_Number__c != null) {
          tDisplay = 'Table ' + ord.Table__r.Table_Number__c;
        } else if (String.isNotBlank(ord.Table__r.Name)) {
          tDisplay = ord.Table__r.Name;
        }
      }
      wrap.tableName = tDisplay;

      wrap.orderDate = ord.Order_Date__c;
      wrap.status = ord.Status__c;
      wrap.subtotal = ord.Subtotal__c;
      wrap.discountPercent = ord.Discount_Percent__c;
      wrap.discountAmount = ord.Discount_Amount__c;
      wrap.discountStatus = ord.Discount_Status__c;
      wrap.taxRate = ord.Tax_Rate__c;
      wrap.grandTotal = ord.Grand_Total__c;
      wrap.cancellationReason = ord.Cancellation_Reason__c;

      wrap.itemNames = new List<String>();
      if (ord.Order_Items__r != null) {
        for (Order_Item__c oi : ord.Order_Items__r) {
          if (oi.Menu_Item__r != null) {
            wrap.itemNames.add(
              oi.Menu_Item__r.Name + ' (x' + oi.Quantity__c + ')'
            );
          }
        }
      }
      result.add(wrap);
    }
    return result;
  }

  @AuraEnabled
  public static List<OrderDetailWrapper> getPendingDiscountOrders() {
    List<Order__c> orders = [
      SELECT
        Id,
        Name,
        Customer__r.Name,
        Customer__r.VIP_Customer__c,
        Table__r.Name,
        Table__r.Table_Number__c,
        Order_Date__c,
        Status__c,
        Subtotal__c,
        Discount_Percent__c,
        Discount_Amount__c,
        Discount_Status__c,
        Tax_Rate__c,
        Grand_Total__c,
        (
          SELECT Id, Menu_Item__r.Name, Quantity__c, Unit_Price__c
          FROM Order_Items__r
        )
      FROM Order__c
      WHERE Discount_Status__c = 'Pending Approval'
      ORDER BY CreatedDate DESC
    ];

    List<OrderDetailWrapper> result = new List<OrderDetailWrapper>();
    for (Order__c ord : orders) {
      OrderDetailWrapper wrap = new OrderDetailWrapper();
      wrap.id = ord.Id;
      wrap.orderNumber = ord.Name;
      wrap.customerName = (ord.Customer__r != null)
        ? ord.Customer__r.Name
        : 'Walk-in Customer';
      wrap.isVipCustomer = (ord.Customer__r != null &&
      ord.Customer__r.VIP_Customer__c == true);

      String tDisplay = 'N/A';
      if (ord.Table__r != null) {
        if (ord.Table__r.Table_Number__c != null) {
          tDisplay = 'Table ' + ord.Table__r.Table_Number__c;
        } else if (String.isNotBlank(ord.Table__r.Name)) {
          tDisplay = ord.Table__r.Name;
        }
      }
      wrap.tableName = tDisplay;

      wrap.orderDate = ord.Order_Date__c;
      wrap.status = ord.Status__c;
      wrap.subtotal = ord.Subtotal__c;
      wrap.discountPercent = ord.Discount_Percent__c;
      wrap.discountAmount = ord.Discount_Amount__c;
      wrap.discountStatus = ord.Discount_Status__c;
      wrap.grandTotal = ord.Grand_Total__c;

      wrap.itemNames = new List<String>();
      if (ord.Order_Items__r != null) {
        for (Order_Item__c oi : ord.Order_Items__r) {
          if (oi.Menu_Item__r != null) {
            wrap.itemNames.add(
              oi.Menu_Item__r.Name + ' (x' + oi.Quantity__c + ')'
            );
          }
        }
      }
      result.add(wrap);
    }
    return result;
  }

  @AuraEnabled
  public static List<TopSellingItemWrapper> getTopSellingMenuItems() {
    AggregateResult[] agg = [
      SELECT
        Menu_Item__r.Name itemName,
        Menu_Item__r.Category__c category,
        SUM(Quantity__c) totalQty,
        SUM(Total_Price__c) totalRev
      FROM Order_Item__c
      WHERE Order__r.Status__c != 'Cancelled'
      GROUP BY Menu_Item__r.Name, Menu_Item__r.Category__c
      ORDER BY SUM(Quantity__c) DESC
      LIMIT 5
    ];

    List<TopSellingItemWrapper> result = new List<TopSellingItemWrapper>();
    for (AggregateResult ar : agg) {
      TopSellingItemWrapper wrap = new TopSellingItemWrapper();
      wrap.itemName = (String) ar.get('itemName');
      wrap.category = (String) ar.get('category');
      wrap.totalQuantity = (Decimal) ar.get('totalQty');
      wrap.totalRevenue = (Decimal) ar.get('totalRev');
      result.add(wrap);
    }
    return result;
  }

  @AuraEnabled
  public static void updateTableStatus(Id tableId, String newStatus) {
    try {
      Restaurant_Table__c tbl = new Restaurant_Table__c(
        Id = tableId,
        Status__c = newStatus
      );
      update tbl;
    } catch (Exception ex) {
      throw new AuraHandledException(ex.getMessage());
    }
  }

  @AuraEnabled
  public static void updateMenuItemPrice(Id menuItemId, Decimal newPrice) {
    try {
      Menu_Item__c mi = new Menu_Item__c(Id = menuItemId, Price__c = newPrice);
      update mi;
    } catch (Exception ex) {
      throw new AuraHandledException(ex.getMessage());
    }
  }

  @AuraEnabled
  public static void updateMenuItemAvailability(
    Id menuItemId,
    Boolean isAvailable
  ) {
    try {
      Menu_Item__c mi = new Menu_Item__c(
        Id = menuItemId,
        Available__c = isAvailable
      );
      update mi;
    } catch (Exception ex) {
      throw new AuraHandledException(ex.getMessage());
    }
  }
}
