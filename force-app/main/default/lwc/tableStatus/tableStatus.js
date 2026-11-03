import { LightningElement, api } from "lwc";
import getTables from "@salesforce/apex/OrderService.getTables";
import updateTableStatus from "@salesforce/apex/RestaurantDashboardController.updateTableStatus";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class TableStatus extends LightningElement {
  rawTables = [];
  tables = [];
  isLoading = true;

  connectedCallback() {
    this.fetchTables();
  }

  @api
  refreshData() {
    this.fetchTables();
  }

  async fetchTables() {
    this.isLoading = true;
    try {
      const data = await getTables();
      this.rawTables = data || [];
      this.processTables();
    } catch (error) {
      console.error("Error fetching tables:", error);
    } finally {
      this.isLoading = false;
    }
  }

  processTables() {
    this.tables = this.rawTables.map((t) => {
      let cardCssClass = "table-card ";
      let statusBadgeCssClass = "status-pill ";

      switch (t.Status__c) {
        case "Available":
          cardCssClass += "table-available";
          statusBadgeCssClass += "badge-available";
          break;
        case "Occupied":
          cardCssClass += "table-occupied";
          statusBadgeCssClass += "badge-occupied";
          break;
        case "Reserved":
          cardCssClass += "table-reserved";
          statusBadgeCssClass += "badge-reserved";
          break;
        case "Cleaning":
          cardCssClass += "table-cleaning";
          statusBadgeCssClass += "badge-cleaning";
          break;
        default:
          cardCssClass += "table-default";
          statusBadgeCssClass += "badge-default";
      }

      return {
        ...t,
        cardCssClass,
        statusBadgeCssClass
      };
    });
  }

  async handleStatusChangeSelect(event) {
    const tableId = event.target.dataset.id;
    const newStatus = event.detail.value;

    this.isLoading = true;
    try {
      await updateTableStatus({ tableId, newStatus });
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Table Updated",
          message: `Table status updated to ${newStatus}`,
          variant: "success"
        })
      );
      this.dispatchEvent(
        new CustomEvent("tablestatuschange", { bubbles: true, composed: true })
      );
      await this.fetchTables();
    } catch (error) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Update Error",
          message: error.body ? error.body.message : error.message,
          variant: "error"
        })
      );
    } finally {
      this.isLoading = false;
    }
  }
}
