import { LightningElement, api } from "lwc";
import getPendingDiscountOrders from "@salesforce/apex/RestaurantDashboardController.getPendingDiscountOrders";
import approveDiscount from "@salesforce/apex/OrderService.approveDiscount";
import rejectDiscount from "@salesforce/apex/OrderService.rejectDiscount";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class DiscountApproval extends LightningElement {
  pendingOrders = [];
  hasPendingOrders = false;
  isLoading = true;

  connectedCallback() {
    this.fetchPendingApprovals();
  }

  @api
  refreshData() {
    this.fetchPendingApprovals();
  }

  async fetchPendingApprovals() {
    this.isLoading = true;
    try {
      const data = await getPendingDiscountOrders();
      this.pendingOrders = data || [];
      this.hasPendingOrders = this.pendingOrders.length > 0;
    } catch (error) {
      console.error("Error loading pending approvals:", error);
    } finally {
      this.isLoading = false;
    }
  }

  async handleApprove(event) {
    const orderId = event.target.dataset.id;
    this.isLoading = true;
    try {
      const res = await approveDiscount({ orderId });
      if (res.success) {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Discount Approved",
            message: res.message,
            variant: "success"
          })
        );
        this.dispatchEvent(
          new CustomEvent("approvalchange", { bubbles: true, composed: true }) // bubbles and composed ???
        );
        await this.fetchPendingApprovals();
      }
    } catch (error) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Approval Error",
          message: error.body ? error.body.message : error.message,
          variant: "error"
        })
      );
    } finally {
      this.isLoading = false;
    }
  }

  async handleReject(event) {
    const orderId = event.target.dataset.id;
    this.isLoading = true;
    try {
      const res = await rejectDiscount({ orderId });
      if (res.success) {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Discount Rejected",
            message: res.message,
            variant: "info"
          })
        );
        this.dispatchEvent(
          new CustomEvent("approvalchange", { bubbles: true, composed: true })
        );
        await this.fetchPendingApprovals();
      }
    } catch (error) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Rejection Error",
          message: error.body ? error.body.message : error.message,
          variant: "error"
        })
      );
    } finally {
      this.isLoading = false;
    }
  }
}
