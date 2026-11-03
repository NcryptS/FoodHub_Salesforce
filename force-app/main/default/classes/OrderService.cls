public with sharing class OrderService {
  public class OrderItemInput {
    @AuraEnabled
    public String menuItemId { get; set; }
    @AuraEnabled
    public Integer quantity { get; set; }
    @AuraEnabled
    public Decimal unitPrice { get; set; }
  }

  @AuraEnabled
  public static Map<String, Object> createOrder(
    String customerId,
    String tableId,
    Decimal discountPercent,
    String itemsJson,
    String customerName,
    String customerPhone,
    String customerType
  ) {
    Map<String, Object> result = new Map<String, Object>();
    try {
      if (String.isBlank(itemsJson)) {
        throw new AuraHandledException(
          'Cannot place an empty order. Please add at least one menu item.'
        );
      }

      List<OrderItemInput> itemInputs = (List<OrderItemInput>) JSON.deserialize(
        itemsJson,
        List<OrderItemInput>.class
      );
      if (itemInputs == null || itemInputs.isEmpty()) {
        throw new AuraHandledException('Cart contains no items.');
      }

      Id targetCustomerId = null;
      if (String.isNotBlank(customerId)) {
        targetCustomerId = (Id) customerId;
      } else if (String.isNotBlank(customerName)) {
        Boolean isVip = (customerType == 'VIP');
        List<Customer__c> existingCust = [
          SELECT Id, Name, Phone__c, VIP_Customer__c
          FROM Customer__c
          WHERE Name = :customerName
          LIMIT 1
        ];
        if (!existingCust.isEmpty()) {
          targetCustomerId = existingCust[0].Id;
          Customer__c cToUpdate = existingCust[0];
          Boolean updated = false;
          if (
            String.isNotBlank(customerPhone) &&
            cToUpdate.Phone__c != customerPhone
          ) {
            cToUpdate.Phone__c = customerPhone;
            updated = true;
          }
          if (cToUpdate.VIP_Customer__c != isVip) {
            cToUpdate.VIP_Customer__c = isVip;
            updated = true;
          }
          if (updated) {
            update cToUpdate;
          }
        } else {
          Customer__c newCust = new Customer__c(
            Name = customerName,
            Phone__c = customerPhone,
            VIP_Customer__c = isVip
          );
          insert newCust;
          targetCustomerId = newCust.Id;
        }
      }

      Set<Id> menuItemIds = new Set<Id>();
      for (OrderItemInput item : itemInputs) {
        if (String.isNotBlank(item.menuItemId)) {
          menuItemIds.add((Id) item.menuItemId);
        }
      }
      Map<Id, Menu_Item__c> menuItemsMap = new Map<Id, Menu_Item__c>(
        [SELECT Id, Name, Price__c FROM Menu_Item__c WHERE Id IN :menuItemIds]
      );

      Decimal subtotal = 0.0;
      for (OrderItemInput item : itemInputs) {
        Menu_Item__c mi = menuItemsMap.get((Id) item.menuItemId);
        Decimal price = (item.unitPrice != null)
          ? item.unitPrice
          : (mi != null ? mi.Price__c : 0.0);
        subtotal += (price * item.quantity);
      }

      Order__c newOrder = new Order__c(
        Customer__c = targetCustomerId,
        Table__c = (String.isNotBlank(tableId)) ? (Id) tableId : null,
        Order_Date__c = System.now(),
        Status__c = 'Draft',
        Subtotal__c = subtotal,
        Discount_Percent__c = (discountPercent != null) ? discountPercent : 0.0
      );

      insert newOrder;

      List<Order_Item__c> orderItemsToInsert = new List<Order_Item__c>();
      for (OrderItemInput item : itemInputs) {
        Menu_Item__c mi = menuItemsMap.get((Id) item.menuItemId);
        Decimal unitPriceToStore = (mi != null &&
          mi.Price__c != null)
          ? mi.Price__c
          : 0.0;

        orderItemsToInsert.add(
          new Order_Item__c(
            Order__c = newOrder.Id,
            Menu_Item__c = (Id) item.menuItemId,
            Quantity__c = item.quantity,
            Unit_Price__c = unitPriceToStore
          )
        );
      }
      insert orderItemsToInsert;

      Order__c createdOrder = [
        SELECT
          Id,
          Name,
          Status__c,
          Subtotal__c,
          Discount_Percent__c,
          Discount_Amount__c,
          Discount_Status__c,
          Tax__c,
          Grand_Total__c
        FROM Order__c
        WHERE Id = :newOrder.Id
      ];

      result.put('success', true);
      result.put('order', createdOrder);
      result.put('message', 'Order placed successfully!');
      return result;
    } catch (Exception ex) {
      throw new AuraHandledException(ex.getMessage());
    }
  }

  public static Map<String, Object> createOrder(
    String customerId,
    String tableId,
    Decimal discountPercent,
    String itemsJson
  ) {
    return createOrder(
      customerId,
      tableId,
      discountPercent,
      itemsJson,
      null,
      null,
      null
    );
  }

  @AuraEnabled
  public static Map<String, Object> updateOrderStatus(
    Id orderId,
    String newStatus,
    String cancellationReason
  ) {
    Map<String, Object> response = new Map<String, Object>();
    try {
      Order__c ord = [
        SELECT Id, Status__c, Cancellation_Reason__c
        FROM Order__c
        WHERE Id = :orderId
      ];
      ord.Status__c = newStatus;
      if (newStatus == 'Cancelled' && String.isNotBlank(cancellationReason)) {
        ord.Cancellation_Reason__c = cancellationReason;
      }
      update ord;
      response.put('success', true);
      response.put('message', 'Order status updated to ' + newStatus);
      return response;
    } catch (Exception ex) {
      throw new AuraHandledException(ex.getMessage());
    }
  }

  @AuraEnabled
  public static Map<String, Object> approveDiscount(Id orderId) {
    Map<String, Object> response = new Map<String, Object>();
    try {
      Order__c ord = [
        SELECT Id, Discount_Status__c
        FROM Order__c
        WHERE Id = :orderId
      ];
      ord.Discount_Status__c = 'Approved';
      update ord;
      response.put('success', true);
      response.put('message', 'Discount request approved successfully.');
      return response;
    } catch (Exception ex) {
      throw new AuraHandledException(ex.getMessage());
    }
  }

  @AuraEnabled
  public static Map<String, Object> rejectDiscount(Id orderId) {
    Map<String, Object> response = new Map<String, Object>();
    try {
      Order__c ord = [
        SELECT Id, Discount_Status__c, Discount_Percent__c
        FROM Order__c
        WHERE Id = :orderId
      ];
      ord.Discount_Status__c = 'Rejected';
      ord.Discount_Percent__c = 0.0;
      update ord;
      response.put('success', true);
      response.put(
        'message',
        'Discount request rejected. Discount reset to 0%.'
      );
      return response;
    } catch (Exception ex) {
      throw new AuraHandledException(ex.getMessage());
    }
  }

  @AuraEnabled
  public static Map<String, Object> fetchTaxRateAndConfirmOrder(Id orderId) {
    Map<String, Object> response = new Map<String, Object>();
    try {
      Order__c ord = [
        SELECT
          Id,
          Status__c,
          Tax_Rate__c,
          Discount_Percent__c,
          Discount_Status__c
        FROM Order__c
        WHERE Id = :orderId
      ];

      if (
        ord.Discount_Percent__c > 10.0 &&
        ord.Discount_Status__c != 'Approved'
      ) {
        throw new AuraHandledException(
          'Cannot confirm order: Discount exceeds 10% and has not been approved by a manager.'
        );
      }

      Decimal taxRate = TaxService.getTaxRate();
      ord.Tax_Rate__c = taxRate;
      ord.Status__c = 'Confirmed';

      update ord;

      response.put('success', true);
      response.put('taxRate', taxRate);
      response.put(
        'message',
        'Order confirmed! External tax rate of ' + taxRate + '% applied.'
      );
      return response;
    } catch (Exception ex) {
      throw new AuraHandledException(ex.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<Customer__c> getCustomers() {
    return [
      SELECT
        Id,
        Name,
        Phone__c,
        Email__c,
        VIP_Customer__c,
        Total_Orders__c,
        Total_Amount_Spent__c
      FROM Customer__c
      ORDER BY Name ASC
      LIMIT 100
    ];
  }

  @AuraEnabled(cacheable=true)
  public static List<Restaurant_Table__c> getTables() {
    return [
      SELECT Id, Name, Table_Number__c, Capacity__c, Status__c
      FROM Restaurant_Table__c
      ORDER BY Table_Number__c ASC
      LIMIT 50
    ];
  }

  @AuraEnabled(cacheable=true)
  public static List<Menu_Item__c> getMenuItems() {
    return [
      SELECT
        Id,
        Name,
        Category__c,
        Price__c,
        Description__c,
        Vegetarian__c,
        Available__c,
        Preparation_Time__c
      FROM Menu_Item__c
      ORDER BY Category__c, Name ASC
      LIMIT 200
    ];
  }
}
