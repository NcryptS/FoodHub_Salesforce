@isTest
private class OrderServiceTest {
  @testSetup
  static void setupData() {
    Customer__c cust = new Customer__c(
      Name = 'Bob Smith',
      Phone__c = '555-1234'
    );
    insert cust;

    Restaurant_Table__c tbl = new Restaurant_Table__c(
      Name = 'Table 2',
      Table_Number__c = '2',
      Capacity__c = 2,
      Status__c = 'Available'
    );
    insert tbl;

    Menu_Item__c item1 = new Menu_Item__c(
      Name = 'Pizza',
      Category__c = 'Main Course',
      Price__c = 20.00,
      Available__c = true
    );
    Menu_Item__c item2 = new Menu_Item__c(
      Name = 'Soda',
      Category__c = 'Beverages',
      Price__c = 4.00,
      Available__c = true
    );
    insert new List<Menu_Item__c>{ item1, item2 };
  }

  @isTest
  static void testCreateOrderAndHistoricalPriceRetention() {
    Customer__c cust = [SELECT Id FROM Customer__c LIMIT 1];
    Restaurant_Table__c tbl = [SELECT Id FROM Restaurant_Table__c LIMIT 1];
    List<Menu_Item__c> items = [SELECT Id, Price__c FROM Menu_Item__c];

    List<OrderService.OrderItemInput> inputItems = new List<OrderService.OrderItemInput>();
    OrderService.OrderItemInput itemInput1 = new OrderService.OrderItemInput();
    itemInput1.menuItemId = items[0].Id;
    itemInput1.quantity = 2;
    itemInput1.unitPrice = items[0].Price__c;
    inputItems.add(itemInput1);

    OrderService.OrderItemInput itemInput2 = new OrderService.OrderItemInput();
    itemInput2.menuItemId = items[1].Id;
    itemInput2.quantity = 1;
    itemInput2.unitPrice = items[1].Price__c;
    inputItems.add(itemInput2);

    String itemsJson = JSON.serialize(inputItems);

    Test.startTest();
    Map<String, Object> result = OrderService.createOrder(
      cust.Id,
      tbl.Id,
      10.0,
      itemsJson
    );
    Test.stopTest();

    System.assertEquals(true, result.get('success'));
    Order__c createdOrder = (Order__c) result.get('order');

    List<Order_Item__c> orderItems = [
      SELECT Unit_Price__c, Menu_Item__c
      FROM Order_Item__c
      WHERE Order__c = :createdOrder.Id
    ];
    System.assertEquals(2, orderItems.size());

    items[0].Price__c = 35.00;
    update items[0];

    Order_Item__c historicalOrderItem = [
      SELECT Unit_Price__c
      FROM Order_Item__c
      WHERE Order__c = :createdOrder.Id AND Menu_Item__c = :items[0].Id
    ];
    System.assertEquals(
      20.00,
      historicalOrderItem.Unit_Price__c,
      'Historical unit price on Order_Item__c must be preserved when Menu Item price changes'
    );
  }

  @isTest
  static void testDiscountApprovalAndRejectionFlow() {
    Customer__c cust = [SELECT Id FROM Customer__c LIMIT 1];
    Restaurant_Table__c tbl = [SELECT Id FROM Restaurant_Table__c LIMIT 1];
    Menu_Item__c mi = [SELECT Id, Price__c FROM Menu_Item__c LIMIT 1];

    List<OrderService.OrderItemInput> inputItems = new List<OrderService.OrderItemInput>();
    OrderService.OrderItemInput itemInput = new OrderService.OrderItemInput();
    itemInput.menuItemId = mi.Id;
    itemInput.quantity = 1;
    itemInput.unitPrice = mi.Price__c;
    inputItems.add(itemInput);

    Map<String, Object> createRes = OrderService.createOrder(
      cust.Id,
      tbl.Id,
      25.0,
      JSON.serialize(inputItems)
    );
    Order__c ord = (Order__c) createRes.get('order');

    Test.startTest();
    Map<String, Object> approveRes = OrderService.approveDiscount(ord.Id);
    System.assertEquals(true, approveRes.get('success'));

    Order__c approvedOrd = [
      SELECT Discount_Status__c
      FROM Order__c
      WHERE Id = :ord.Id
    ];
    System.assertEquals('Approved', approvedOrd.Discount_Status__c);

    Map<String, Object> rejectRes = OrderService.rejectDiscount(ord.Id);
    System.assertEquals(true, rejectRes.get('success'));

    Order__c rejectedOrd = [
      SELECT Discount_Status__c, Discount_Percent__c
      FROM Order__c
      WHERE Id = :ord.Id
    ];
    System.assertEquals('Rejected', rejectedOrd.Discount_Status__c);
    System.assertEquals(
      0.0,
      rejectedOrd.Discount_Percent__c,
      'Rejected discount should reset to 0%'
    );
    Test.stopTest();
  }

  @isTest
  static void testFetchTaxRateAndConfirmOrderSuccess() {
    Customer__c cust = [SELECT Id FROM Customer__c LIMIT 1];
    Restaurant_Table__c tbl = [SELECT Id FROM Restaurant_Table__c LIMIT 1];
    Menu_Item__c mi = [SELECT Id, Price__c FROM Menu_Item__c LIMIT 1];

    List<OrderService.OrderItemInput> inputItems = new List<OrderService.OrderItemInput>();
    OrderService.OrderItemInput itemInput = new OrderService.OrderItemInput();
    itemInput.menuItemId = mi.Id;
    itemInput.quantity = 1;
    itemInput.unitPrice = mi.Price__c;
    inputItems.add(itemInput);

    Map<String, Object> createRes = OrderService.createOrder(
      cust.Id,
      tbl.Id,
      5.0,
      JSON.serialize(inputItems)
    );
    Order__c ord = (Order__c) createRes.get('order');

    Test.setMock(
      HttpCalloutMock.class,
      new TaxCalloutMock(200, '{"country": "Mexico", "taxRate": 16.0}')
    );

    Test.startTest();
    Map<String, Object> confirmRes = OrderService.fetchTaxRateAndConfirmOrder(
      ord.Id
    );
    Test.stopTest();

    System.assertEquals(true, confirmRes.get('success'));

    Order__c confirmedOrd = [
      SELECT Status__c, Tax_Rate__c
      FROM Order__c
      WHERE Id = :ord.Id
    ];
    System.assertEquals('Confirmed', confirmedOrd.Status__c);
    System.assertEquals(16.0, confirmedOrd.Tax_Rate__c);
  }
}
