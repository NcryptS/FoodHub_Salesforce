import { LightningElement, api } from "lwc";

export default class OrderSummary extends LightningElement {
  @api summaryData;

  summary = {
    todaysOrderCount: 0,
    pendingApprovalCount: 0,
    preparingOrderCount: 0,
    servedOrderCount: 0,
    todaysSales: 0.0,
    availableTablesCount: 0,
    occupiedTablesCount: 0,
    cleaningTablesCount: 0
  };

  renderedCallback() {
    if (this.summaryData) {
      this.summary = this.summaryData;
    }
  }
}
