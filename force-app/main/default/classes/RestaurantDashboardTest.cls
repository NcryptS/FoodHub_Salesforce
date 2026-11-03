@isTest
private class RestaurantDashboardTest {
  @testSetup
  static void setupDashboardData() {
    Customer__c cust = new Customer__c(Name = 'Charlie Brown');
    insert cust;

    Restaurant_Table__c tbl = new Restaurant_Table__c(
      Name = 'Table 3',
      Table_Number__c = '3',
      Capacity__c = 4,
      Status__c = 'Available'
    );
    insert tbl;

    Menu_Item__c mi = new Menu_Item__c(
      Name = 'Steak',
      Category__c = 'Main Course',
      Price__c = 30.00,
      Available__c = true
    );
    insert mi;

    Order__c ord = new Order__c(
      Customer__c = cust.Id,
      Table__c = tbl.Id,
      Subtotal__c = 60.00,
      Discount_Percent__c = 15.0,
      Discount_Status__c = 'Pending Approval',
      Status__c = 'Draft'
    );
    insert ord;

    Order_Item__c oi = new Order_Item__c(
      Order__c = ord.Id,
      Menu_Item__c = mi.Id,
      Quantity__c = 2,
      Unit_Price__c = 30.00
    );
    insert oi;
  }

  @isTest
  static void testGetDashboardSummary() {
    Test.startTest();
    RestaurantDashboardController.DashboardSummaryWrapper summary = RestaurantDashboardController.getDashboardSummary();
    Test.stopTest();

    System.assertNotEquals(null, summary);
    System.assert(summary.todaysOrderCount >= 1);
    System.assertEquals(1, summary.pendingApprovalCount);
  }

  @isTest
  static void testGetPendingDiscountOrders() {
    Test.startTest();
    List<RestaurantDashboardController.OrderDetailWrapper> pending = RestaurantDashboardController.getPendingDiscountOrders();
    Test.stopTest();

    System.assertEquals(1, pending.size());
    System.assertEquals('Pending Approval', pending[0].discountStatus);
  }

  @isTest
  static void testGetRecentOrdersAndTopSelling() {
    Test.startTest();
    List<RestaurantDashboardController.OrderDetailWrapper> recent = RestaurantDashboardController.getRecentOrders();
    List<RestaurantDashboardController.TopSellingItemWrapper> topSelling = RestaurantDashboardController.getTopSellingMenuItems();
    Test.stopTest();

    System.assert(recent.size() >= 1);
    System.assertNotEquals(null, topSelling);
  }

  @isTest
  static void testUpdateTableAndMenuItemStatus() {
    Restaurant_Table__c tbl = [SELECT Id FROM Restaurant_Table__c LIMIT 1];
    Menu_Item__c mi = [SELECT Id FROM Menu_Item__c LIMIT 1];

    Test.startTest();
    RestaurantDashboardController.updateTableStatus(tbl.Id, 'Occupied');
    RestaurantDashboardController.updateMenuItemPrice(mi.Id, 45.00);
    RestaurantDashboardController.updateMenuItemAvailability(mi.Id, false);
    Test.stopTest();

    Restaurant_Table__c updatedTbl = [
      SELECT Status__c
      FROM Restaurant_Table__c
      WHERE Id = :tbl.Id
    ];
    Menu_Item__c updatedMi = [
      SELECT Price__c, Available__c
      FROM Menu_Item__c
      WHERE Id = :mi.Id
    ];

    System.assertEquals('Occupied', updatedTbl.Status__c);
    System.assertEquals(45.00, updatedMi.Price__c);
    System.assertEquals(false, updatedMi.Available__c);
  }
}
