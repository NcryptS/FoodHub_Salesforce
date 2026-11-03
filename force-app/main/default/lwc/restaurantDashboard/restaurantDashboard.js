import { LightningElement } from "lwc";
import getDashboardSummary from "@salesforce/apex/RestaurantDashboardController.getDashboardSummary";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class RestaurantDashboard extends LightningElement {
  cartItems = [];
  currentRole = "Staff";
  activeTab = "staff_pos";

  dashboardSummary = null;
  isManagerMode = false;
  staffVariant = "brand";
  managerVariant = "neutral";

  connectedCallback() {
    this.fetchSummary();
    this.updateRoleState();
  }

  async fetchSummary() {
    try {
      const data = await getDashboardSummary();
      this.dashboardSummary = data;
    } catch (error) {
      console.error("Error fetching dashboard summary:", error);
    }
  }

  updateRoleState() {
    this.isManagerMode = this.currentRole === "Manager";
    this.staffVariant = this.currentRole === "Staff" ? "brand" : "neutral";
    this.managerVariant = this.currentRole === "Manager" ? "brand" : "neutral";
  }

  switchToStaffView() {
    this.currentRole = "Staff";
    this.activeTab = "staff_pos";
    this.updateRoleState();
    this.dispatchEvent(
      new ShowToastEvent({
        title: "Role Switched",
        message: "Switched to Restaurant Staff View",
        variant: "info"
      })
    );
  }

  switchToManagerView() {
    this.currentRole = "Manager";
    this.activeTab = "manager_approvals";
    this.updateRoleState();
    this.dispatchEvent(
      new ShowToastEvent({
        title: "Role Switched",
        message: "Switched to Restaurant Manager View",
        variant: "info"
      })
    );
  }

  handleAddToCart(event) {
    const item = event.detail;
    const existingIndex = this.cartItems.findIndex((ci) => ci.Id === item.Id);

    if (existingIndex > -1) {
      const updated = [...this.cartItems];
      updated[existingIndex].quantity += 1;
      updated[existingIndex].lineTotal =
        updated[existingIndex].quantity * updated[existingIndex].Price__c;
      this.cartItems = updated;
    } else {
      this.cartItems = [
        ...this.cartItems,
        {
          ...item,
          quantity: 1,
          lineTotal: item.Price__c
        }
      ];
    }

    this.dispatchEvent(
      new ShowToastEvent({
        title: "Added to Cart",
        message: `${item.Name} added to cart.`,
        variant: "success"
      })
    );
  }

  handleUpdateQty(event) {
    const { itemId, delta } = event.detail;
    const updated = this.cartItems
      .map((item) => {
        if (item.Id === itemId) {
          const newQty = item.quantity + delta;
          if (newQty <= 0) return null;
          return {
            ...item,
            quantity: newQty,
            lineTotal: newQty * item.Price__c
          };
        }
        return item;
      })
      .filter((item) => item !== null);

    this.cartItems = updated;
  }

  handleRemoveItem(event) {
    const { itemId } = event.detail;
    this.cartItems = this.cartItems.filter((item) => item.Id !== itemId);
  }

  handleOrderPlaced() {
    this.cartItems = [];
    this.handleStateRefresh();
  }

  handleStateRefresh() {
    this.fetchSummary();

    const orderListCmp = this.template.querySelector(".order-list-cmp");
    if (orderListCmp && orderListCmp.refreshData) {
      orderListCmp.refreshData();
    }

    const tableStatusCmp = this.template.querySelector(".table-status-cmp");
    if (tableStatusCmp && tableStatusCmp.refreshData) {
      tableStatusCmp.refreshData();
    }

    const approvalCmp = this.template.querySelector(".discount-approval-cmp");
    if (approvalCmp && approvalCmp.refreshData) {
      approvalCmp.refreshData();
    }
  }
}
