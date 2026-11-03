@isTest
private class OrderTriggerTest {
  @testSetup
  static void setupTestData() {
    Customer__c cust = new Customer__c(
      Name = 'Alice Johnson',
      Phone__c = '555-0199',
      Email__c = 'alice@example.com'
    );
    insert cust;

    Restaurant_Table__c tbl = new Restaurant_Table__c(
      Name = 'Table 1',
      Table_Number__c = '1',
      Capacity__c = 4,
      Status__c = 'Available'
    );
    insert tbl;

    Menu_Item__c item = new Menu_Item__c(
      Name = 'Gourmet Burger',
      Category__c = 'Main Course',
      Price__c = 15.00,
      Available__c = true
    );
    insert item;
  }

  @isTest
  static void testNormalOrderCreationWithSmallDiscount() {
    Customer__c cust = [SELECT Id FROM Customer__c LIMIT 1];
    Restaurant_Table__c tbl = [SELECT Id FROM Restaurant_Table__c LIMIT 1];

    Test.startTest();
    Order__c ord = new Order__c(
      Customer__c = cust.Id,
      Table__c = tbl.Id,
      Subtotal__c = 100.00,
      Discount_Percent__c = 5.0
    );
    insert ord;
    Test.stopTest();

    Order__c queried = [
      SELECT Discount_Status__c, Discount_Amount__c, Grand_Total__c
      FROM Order__c
      WHERE Id = :ord.Id
    ];
    System.assertEquals(
      'None',
      queried.Discount_Status__c,
      'Discount <= 10% should not require approval'
    );
    System.assertEquals(5.00, queried.Discount_Amount__c);
  }

  @isTest
  static void testOrderCreationWithHighDiscountPendingApproval() {
    Customer__c cust = [SELECT Id FROM Customer__c LIMIT 1];
    Restaurant_Table__c tbl = [SELECT Id FROM Restaurant_Table__c LIMIT 1];

    Test.startTest();
    Order__c ord = new Order__c(
      Customer__c = cust.Id,
      Table__c = tbl.Id,
      Subtotal__c = 100.00,
      Discount_Percent__c = 20.0
    );
    insert ord;
    Test.stopTest();

    Order__c queried = [
      SELECT Discount_Status__c
      FROM Order__c
      WHERE Id = :ord.Id
    ];
    System.assertEquals(
      'Pending Approval',
      queried.Discount_Status__c,
      'Discount > 10% must enter Pending Approval'
    );
  }

  @isTest
  static void testValidStatusProgressionAndTableAutomation() {
    Customer__c cust = [SELECT Id FROM Customer__c LIMIT 1];
    Restaurant_Table__c tbl = [SELECT Id FROM Restaurant_Table__c LIMIT 1];

    Order__c ord = new Order__c(
      Customer__c = cust.Id,
      Table__c = tbl.Id,
      Subtotal__c = 50.00,
      Discount_Percent__c = 0
    );
    insert ord;

    Test.startTest();
    ord.Status__c = 'Confirmed';
    update ord;

    Restaurant_Table__c tblConfirmed = [
      SELECT Status__c
      FROM Restaurant_Table__c
      WHERE Id = :tbl.Id
    ];
    System.assertEquals(
      'Occupied',
      tblConfirmed.Status__c,
      'Table should become Occupied on order confirmation'
    );

    ord.Status__c = 'Preparing';
    update ord;

    ord.Status__c = 'Ready';
    update ord;

    ord.Status__c = 'Served';
    update ord;
    Test.stopTest();

    Restaurant_Table__c tblServed = [
      SELECT Status__c
      FROM Restaurant_Table__c
      WHERE Id = :tbl.Id
    ];
    System.assertEquals(
      'Cleaning',
      tblServed.Status__c,
      'Table should become Cleaning when order is served'
    );

    Customer__c updatedCust = [
      SELECT Total_Orders__c, Total_Amount_Spent__c
      FROM Customer__c
      WHERE Id = :cust.Id
    ];
    System.assertEquals(1, updatedCust.Total_Orders__c);
  }

  @isTest
  static void testInvalidStatusTransitionBlocked() {
    Customer__c cust = [SELECT Id FROM Customer__c LIMIT 1];
    Restaurant_Table__c tbl = [SELECT Id FROM Restaurant_Table__c LIMIT 1];

    Order__c ord = new Order__c(
      Customer__c = cust.Id,
      Table__c = tbl.Id,
      Subtotal__c = 50.00,
      Discount_Percent__c = 0
    );
    insert ord;

    Test.startTest();
    try {
      ord.Status__c = 'Served';
      update ord;
      System.assert(
        false,
        'Exception should have been thrown for invalid status transition'
      );
    } catch (DmlException ex) {
      System.assert(
        ex.getMessage().contains('Invalid status transition'),
        'Error message should complain about invalid status transition'
      );
    }
    Test.stopTest();
  }

  @isTest
  static void testCancellationRules() {
    Customer__c cust = [SELECT Id FROM Customer__c LIMIT 1];
    Restaurant_Table__c tbl = [SELECT Id FROM Restaurant_Table__c LIMIT 1];

    Order__c ord = new Order__c(
      Customer__c = cust.Id,
      Table__c = tbl.Id,
      Subtotal__c = 50.00,
      Status__c = 'Draft'
    );
    insert ord;

    ord.Status__c = 'Confirmed';
    update ord;

    ord.Status__c = 'Preparing';
    update ord;

    Test.startTest();
    try {
      ord.Status__c = 'Cancelled';
      update ord;
      System.assert(
        false,
        'Exception should be thrown when attempting to cancel Preparing order'
      );
    } catch (DmlException ex) {
      System.assert(
        ex.getMessage().contains('Invalid status transition'),
        'Expected status transition error'
      );
    }
    Test.stopTest();
  }
}
