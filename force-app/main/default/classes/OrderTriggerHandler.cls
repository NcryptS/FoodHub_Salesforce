public with sharing class OrderTriggerHandler {
  private static Boolean isExecuting = false;

  public static void beforeInsert(List<Order__c> newOrders) {
    for (Order__c ord : newOrders) {
      if (ord.Order_Date__c == null) {
        ord.Order_Date__c = System.now();
      }
      if (ord.Discount_Percent__c == null) {
        ord.Discount_Percent__c = 0;
      }
      if (ord.Status__c == null) {
        ord.Status__c = 'Draft';
      }

      if (ord.Discount_Percent__c > 10.0) {
        ord.Discount_Status__c = 'Pending Approval';
      } else if (
        ord.Discount_Status__c == null ||
        ord.Discount_Status__c == 'Pending Approval'
      ) {
        ord.Discount_Status__c = 'None';
      }

      recalculateOrderFields(ord);
    }
  }

  public static void beforeUpdate(
    List<Order__c> newOrders,
    Map<Id, Order__c> oldMap
  ) {
    for (Order__c ord : newOrders) {
      Order__c oldOrd = oldMap.get(ord.Id);

      if (ord.Discount_Percent__c != oldOrd.Discount_Percent__c) {
        if (
          ord.Discount_Percent__c > 10.0 &&
          ord.Discount_Status__c != 'Approved'
        ) {
          ord.Discount_Status__c = 'Pending Approval';
        } else if (
          ord.Discount_Percent__c <= 10.0 &&
          ord.Discount_Status__c == 'Pending Approval'
        ) {
          ord.Discount_Status__c = 'None';
        }
      }

      if (
        ord.Discount_Status__c == 'Rejected' &&
        oldOrd.Discount_Status__c != 'Rejected'
      ) {
        ord.Discount_Percent__c = 0.0;
      }

      if (ord.Status__c != oldOrd.Status__c) {
        validateStatusTransition(ord, oldOrd);
      }

      recalculateOrderFields(ord);
    }
  }

  public static void afterUpdate(
    List<Order__c> newOrders,
    Map<Id, Order__c> oldMap
  ) {
    if (isExecuting)
      return;
    isExecuting = true;

    try {
      Map<Id, String> tableStatusUpdates = new Map<Id, String>();
      Set<Id> customerIdsToUpdate = new Set<Id>();

      for (Order__c ord : newOrders) {
        Order__c oldOrd = oldMap.get(ord.Id);

        if (ord.Status__c != oldOrd.Status__c && ord.Table__c != null) {
          if (ord.Status__c == 'Confirmed') {
            tableStatusUpdates.put(ord.Table__c, 'Occupied');
          } else if (ord.Status__c == 'Served') {
            tableStatusUpdates.put(ord.Table__c, 'Cleaning');
          }
        }

        if (
          ord.Status__c != oldOrd.Status__c &&
          (ord.Status__c == 'Served' ||
          oldOrd.Status__c == 'Served') &&
          ord.Customer__c != null
        ) {
          customerIdsToUpdate.add(ord.Customer__c);
        }
      }

      if (!tableStatusUpdates.isEmpty()) {
        List<Restaurant_Table__c> tablesToUpdate = new List<Restaurant_Table__c>();
        for (Id tableId : tableStatusUpdates.keySet()) {
          tablesToUpdate.add(
            new Restaurant_Table__c(
              Id = tableId,
              Status__c = tableStatusUpdates.get(tableId)
            )
          );
        }
        update tablesToUpdate;
      }

      if (!customerIdsToUpdate.isEmpty()) {
        updateCustomerTotals(customerIdsToUpdate);
      }
    } finally {
      isExecuting = false;
    }
  }

  private static void validateStatusTransition(
    Order__c newOrd,
    Order__c oldOrd
  ) {
    String fromStatus = oldOrd.Status__c;
    String toStatus = newOrd.Status__c;

    if (
      toStatus == 'Confirmed' &&
      newOrd.Discount_Percent__c > 10.0 &&
      newOrd.Discount_Status__c != 'Approved'
    ) {
      newOrd.addError(
        'Order discount of ' +
          newOrd.Discount_Percent__c +
          '% exceeds 10% limit. Manager approval is required before confirmation.'
      );
      return;
    }

    Boolean isValid = false;
    if (fromStatus == 'Draft') {
      isValid = (toStatus == 'Confirmed' || toStatus == 'Cancelled');
    } else if (fromStatus == 'Confirmed') {
      isValid = (toStatus == 'Preparing' || toStatus == 'Cancelled');
    } else if (fromStatus == 'Preparing') {
      isValid = (toStatus == 'Ready');
    } else if (fromStatus == 'Ready') {
      isValid = (toStatus == 'Served');
    } else if (fromStatus == 'Served' || fromStatus == 'Cancelled') {
      isValid = false;
    }

    if (!isValid) {
      newOrd.addError(
        'Invalid status transition from ' +
          fromStatus +
          ' to ' +
          toStatus +
          '. Valid progression: Draft -> Confirmed -> Preparing -> Ready -> Served.'
      );
      return;
    }

    if (toStatus == 'Cancelled') {
      if (fromStatus != 'Draft' && fromStatus != 'Confirmed') {
        newOrd.addError(
          'Cannot cancel order in ' +
            fromStatus +
            ' state. Only Draft or Confirmed orders may be cancelled.'
        );
      }
    }
  }

  public static void recalculateOrderFields(Order__c ord) {
    Decimal subtotal = (ord.Subtotal__c != null) ? ord.Subtotal__c : 0.0;
    Decimal discountPct = (ord.Discount_Percent__c != null)
      ? ord.Discount_Percent__c
      : 0.0;
    Decimal taxRatePct = (ord.Tax_Rate__c != null) ? ord.Tax_Rate__c : 0.0;

    Decimal discountAmount = subtotal * (discountPct / 100.0);
    Decimal subtotalAfterDiscount = subtotal - discountAmount;
    Decimal taxAmount = subtotalAfterDiscount * (taxRatePct / 100.0);
    Decimal grandTotal = subtotalAfterDiscount + taxAmount;

    ord.Discount_Amount__c = discountAmount.setScale(
      2,
      System.RoundingMode.HALF_UP
    );
    ord.Tax__c = taxAmount.setScale(2, System.RoundingMode.HALF_UP);
    ord.Grand_Total__c = grandTotal.setScale(2, System.RoundingMode.HALF_UP);
  }

  private static void updateCustomerTotals(Set<Id> customerIds) {
    List<Customer__c> customers = [
      SELECT
        Id,
        Total_Orders__c,
        Total_Amount_Spent__c,
        (SELECT Id, Grand_Total__c FROM Orders__r WHERE Status__c = 'Served')
      FROM Customer__c
      WHERE Id IN :customerIds
    ];

    for (Customer__c cust : customers) {
      Decimal totalSpent = 0.0;
      Integer totalOrders = cust.Orders__r.size();
      for (Order__c ord : cust.Orders__r) {
        if (ord.Grand_Total__c != null) {
          totalSpent += ord.Grand_Total__c;
        }
      }
      cust.Total_Orders__c = totalOrders;
      cust.Total_Amount_Spent__c = totalSpent;
    }

    update customers;
  }
}
