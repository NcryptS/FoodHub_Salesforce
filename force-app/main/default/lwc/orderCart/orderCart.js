import { LightningElement, api, wire } from "lwc";
import getTables from "@salesforce/apex/OrderService.getTables";
import createOrder from "@salesforce/apex/OrderService.createOrder";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class OrderCart extends LightningElement {
  @api cartItems = [];
  customerName = "";
  customerPhone = "";
  customerType = "Regular";
  selectedTableId = "";
  discountPercent = 0;
  estTaxRate = 10;
  isSubmitting = false;

  tableOptions = [];
  customerTypeOptions = [
    { label: "Regular", value: "Regular" },
    { label: "VIP", value: "VIP" }
  ];

  hasCartItems = false;
  isVipType = false;
  selectedTableDisplay = "";
  subtotal = 0;
  discountAmount = 0;
  estTaxAmount = 0;
  grandTotal = 0;
  requiresApproval = false;

  renderedCallback() {
    this.recalculateTotals();
  }

  @wire(getTables)
  wiredTables({ error, data }) {
    if (data) {
      this.tableOptions = data.map((t) => {
        const tableNumStr =
          t.Table_Number__c != null
            ? `Table ${t.Table_Number__c}`
            : t.Name
              ? t.Name
              : "Table N/A";
        const statusStr = t.Status__c ? t.Status__c : "Available";
        return {
          label: `${tableNumStr} (${statusStr})`,
          value: t.Id,
          tableNum: tableNumStr
        };
      });
      this.recalculateTotals();
    } else if (error) {
      console.error("Error fetching tables:", error);
    }
  }

  recalculateTotals() {
    this.hasCartItems = this.cartItems && this.cartItems.length > 0;
    this.isVipType = this.customerType === "VIP";
    let sum = 0;
    if (this.cartItems) {
      for (let i = 0; i < this.cartItems.length; i++) {
        sum += this.cartItems[i].Price__c * this.cartItems[i].quantity;
      }
    }
    this.subtotal = sum;
    this.discountAmount = this.subtotal * (this.discountPercent / 100);
    const afterDiscount = this.subtotal - this.discountAmount;
    this.estTaxAmount = afterDiscount * (this.estTaxRate / 100);
    this.grandTotal = this.subtotal - this.discountAmount + this.estTaxAmount;
    this.requiresApproval = this.discountPercent > 10;

    const tbl = this.tableOptions.find((t) => t.value === this.selectedTableId);
    this.selectedTableDisplay = tbl ? tbl.label : "";
  }

  handleCustomerNameChange(event) {
    this.customerName = event.detail.value;
  }

  handleCustomerPhoneChange(event) {
    this.customerPhone = event.detail.value;
  }

  handleCustomerTypeChange(event) {
    this.customerType = event.detail.value;
    if (this.customerType === "VIP") {
      this.discountPercent = 20;
      this.dispatchEvent(
        new ShowToastEvent({
          title: "VIP Discount Applied",
          message:
            "⭐ 20% VIP discount automatically applied! Order will require Manager Approval.",
          variant: "info"
        })
      );
    } else {
      this.discountPercent = 0;
    }
    this.recalculateTotals();
  }

  handleTableChange(event) {
    this.selectedTableId = event.detail.value;
    this.recalculateTotals();
  }

  handleDiscountChange(event) {
    this.discountPercent = parseFloat(event.detail.value) || 0;
    this.recalculateTotals();
  }

  handleIncrementQty(event) {
    const itemId = event.target.dataset.id;
    this.dispatchEvent(
      new CustomEvent("updateqty", {
        detail: { itemId, delta: 1 },
        bubbles: true,
        composed: true
      })
    );
  }

  handleDecrementQty(event) {
    const itemId = event.target.dataset.id;
    this.dispatchEvent(
      new CustomEvent("updateqty", {
        detail: { itemId, delta: -1 },
        bubbles: true,
        composed: true
      })
    );
  }

  handleRemoveItem(event) {
    const itemId = event.target.dataset.id;
    this.dispatchEvent(
      new CustomEvent("removeitem", {
        detail: { itemId },
        bubbles: true,
        composed: true
      })
    );
  }

  async handlePlaceOrder() {
    if (!this.hasCartItems) return;

    this.isSubmitting = true;
    try {
      const itemsPayload = this.cartItems.map((item) => ({
        menuItemId: item.Id,
        quantity: item.quantity,
        unitPrice: item.Price__c
      }));

      const result = await createOrder({
        customerId: null,
        tableId: this.selectedTableId || null,
        discountPercent: this.discountPercent,
        itemsJson: JSON.stringify(itemsPayload),
        customerName: this.customerName,
        customerPhone: this.customerPhone,
        customerType: this.customerType
      });

      if (result.success) {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Order Placed",
            message:
              result.message +
              (this.requiresApproval
                ? " 20% VIP discount order sent for Manager Approval."
                : ""),
            variant: this.requiresApproval ? "warning" : "success"
          })
        );

        this.dispatchEvent(
          new CustomEvent("orderplaced", {
            detail: result.order,
            bubbles: true,
            composed: true
          })
        );
        this.customerName = "";
        this.customerPhone = "";
        this.customerType = "Regular";
        this.discountPercent = 0;
        this.recalculateTotals();
      }
    } catch (error) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error Placing Order",
          message: error.body ? error.body.message : error.message,
          variant: "error"
        })
      );
    } finally {
      this.isSubmitting = false;
    }
  }
}
