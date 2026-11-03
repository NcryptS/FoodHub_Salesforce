import { LightningElement, api } from "lwc";
import getRecentOrders from "@salesforce/apex/RestaurantDashboardController.getRecentOrders";
import updateOrderStatus from "@salesforce/apex/OrderService.updateOrderStatus";
import fetchTaxRateAndConfirmOrder from "@salesforce/apex/OrderService.fetchTaxRateAndConfirmOrder";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class OrderList extends LightningElement {
  rawOrders = [];
  orders = [];
  hasOrders = false;
  isLoading = true;

  connectedCallback() {
    this.fetchOrders();
  }

  @api
  refreshData() {
    this.fetchOrders();
  }

  async fetchOrders() {
    this.isLoading = true;
    try {
      const data = await getRecentOrders();
      this.rawOrders = data || [];
      this.processOrders();
    } catch (error) {
      console.error("Error loading orders:", error);
    } finally {
      this.isLoading = false;
    }
  }

  processOrders() {
    this.orders = this.rawOrders.map((ord) => {
      let statusBadgeClass = "status-pill ";
      switch (ord.status) {
        case "Draft":
          statusBadgeClass += "status-draft";
          break;
        case "Confirmed":
          statusBadgeClass += "status-confirmed";
          break;
        case "Preparing":
          statusBadgeClass += "status-preparing";
          break;
        case "Ready":
          statusBadgeClass += "status-ready";
          break;
        case "Served":
          statusBadgeClass += "status-served";
          break;
        case "Cancelled":
          statusBadgeClass += "status-cancelled";
          break;
        default:
          statusBadgeClass += "status-default";
      }

      return {
        ...ord,
        statusBadgeClass,
        isDraft: ord.status === "Draft",
        isConfirmed: ord.status === "Confirmed",
        isPreparing: ord.status === "Preparing",
        isReady: ord.status === "Ready",
        isServed: ord.status === "Served",
        isCancelled: ord.status === "Cancelled",
        itemNamesText:
          ord.itemNames && ord.itemNames.length > 0
            ? ord.itemNames.join(", ")
            : "No items"
      };
    });
    this.hasOrders = this.orders.length > 0;
  }

  async handleConfirmOrder(event) {
    const orderId = event.target.dataset.id;
    this.isLoading = true;
    try {
      const res = await fetchTaxRateAndConfirmOrder({ orderId });
      if (res.success) {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Order Confirmed",
            message: res.message,
            variant: "success"
          })
        );
        this.notifyStateChange();
      }
    } catch (error) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Confirmation Error",
          message: error.body ? error.body.message : error.message,
          variant: "error"
        })
      );
    } finally {
      this.isLoading = false;
    }
  }

  async handleStartPreparing(event) {
    await this.changeStatus(event.target.dataset.id, "Preparing");
  }

  async handleMarkReady(event) {
    await this.changeStatus(event.target.dataset.id, "Ready");
  }

  async handleServeOrder(event) {
    await this.changeStatus(event.target.dataset.id, "Served");
  }

  async handleCancelOrder(event) {
    await this.changeStatus(
      event.target.dataset.id,
      "Cancelled",
      "Customer requested cancellation"
    );
  }

  async changeStatus(orderId, newStatus, reason = "") {
    this.isLoading = true;
    try {
      const res = await updateOrderStatus({
        orderId,
        newStatus,
        cancellationReason: reason
      });
      if (res.success) {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Status Updated",
            message: res.message,
            variant: "success"
          })
        );
        this.notifyStateChange();
      }
    } catch (error) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Status Transition Error",
          message: error.body ? error.body.message : error.message,
          variant: "error"
        })
      );
    } finally {
      this.isLoading = false;
    }
  }

  notifyStateChange() {
    this.fetchOrders();
    this.dispatchEvent(
      new CustomEvent("orderstatuschange", { bubbles: true, composed: true })
    );
  }
}
