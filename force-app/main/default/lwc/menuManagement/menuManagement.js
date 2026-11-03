import { LightningElement } from "lwc";
import getMenuItems from "@salesforce/apex/OrderService.getMenuItems";
import updateMenuItemPrice from "@salesforce/apex/RestaurantDashboardController.updateMenuItemPrice";
import updateMenuItemAvailability from "@salesforce/apex/RestaurantDashboardController.updateMenuItemAvailability";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class MenuManagement extends LightningElement {
  menuItems = [];
  isLoading = true;

  isModalOpen = false;
  editingItemId = null;
  editingPrice = 0;

  connectedCallback() {
    this.fetchMenu();
  }

  async fetchMenu() {
    this.isLoading = true;
    try {
      const data = await getMenuItems();
      this.menuItems = data || [];
    } catch (error) {
      console.error("Error loading menu:", error);
    } finally {
      this.isLoading = false;
    }
  }

  async handleToggleAvailable(event) {
    const itemId = event.target.dataset.id;
    const isAvailable = event.target.checked;
    this.isLoading = true;
    try {
      await updateMenuItemAvailability({ menuItemId: itemId, isAvailable });
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Availability Updated",
          message: "Menu item availability status updated successfully",
          variant: "success"
        })
      );
      await this.fetchMenu();
    } catch (error) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Update Failed",
          message: error.body ? error.body.message : error.message,
          variant: "error"
        })
      );
    } finally {
      this.isLoading = false;
    }
  }

  handleOpenPriceModal(event) {
    this.editingItemId = event.target.dataset.id;
    this.editingPrice = parseFloat(event.target.dataset.price) || 0;
    this.isModalOpen = true;
  }

  handleCloseModal() {
    this.isModalOpen = false;
    this.editingItemId = null;
  }

  handleNewPriceChange(event) {
    this.editingPrice = parseFloat(event.detail.value) || 0;
  }

  async handleSavePrice() {
    if (!this.editingItemId || this.editingPrice <= 0) return;
    this.isLoading = true;
    try {
      await updateMenuItemPrice({
        menuItemId: this.editingItemId,
        newPrice: this.editingPrice
      });
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Price Updated",
          message:
            "Menu item price updated successfully. Past orders retain historical price.",
          variant: "success"
        })
      );
      this.handleCloseModal();
      await this.fetchMenu();
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
