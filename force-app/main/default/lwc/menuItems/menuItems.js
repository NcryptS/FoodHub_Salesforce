import { LightningElement, wire } from "lwc";
import getMenuItems from "@salesforce/apex/OrderService.getMenuItems";

export default class MenuItems extends LightningElement {
  menuList = [];
  searchKey = "";
  selectedCategory = "All";
  isLoading = false; // ?????
  categoryTabs = [];
  filteredMenuItems = [];
  hasFilteredItems = false;

  connectedCallback() {
    this.updateCategoryTabs();
  }

  @wire(getMenuItems)
  wiredMenuItems({ error, data }) {
    if (data) {
      this.menuList = data;
      this.isLoading = false;
      this.updateFilteredItems();
    } else if (error) {
      this.isLoading = false;
      console.error("Error fetching menu items:", error);
    }
  }

  // category button active status set
  updateCategoryTabs() {
    const categories = [
      "All",
      "Starters",
      "Main Course",
      "Desserts",
      "Beverages"
    ];
    this.categoryTabs = categories.map((cat) => ({
      label: cat,
      value: cat,
      buttonCssClass: `category-tab-btn ${this.selectedCategory === cat ? "active" : ""}`
    }));
  }

  handleSearchChange(event) {
    this.searchKey = event.target.value.toLowerCase();
    this.updateFilteredItems();
  }

  handleCategorySelect(event) {
    this.selectedCategory = event.target.dataset.value;
    this.updateCategoryTabs();
    this.updateFilteredItems();
  }

  updateFilteredItems() {
    this.filteredMenuItems = this.menuList.filter((item) => {
      const matchesSearch =
        !this.searchKey || item.Name.toLowerCase().includes(this.searchKey);
      const matchesCategory =
        this.selectedCategory === "All" ||
        item.Category__c === this.selectedCategory;
      return matchesSearch && matchesCategory;
    });
    this.hasFilteredItems = this.filteredMenuItems.length > 0;
  }

  handleAddToCart(event) {
    const itemId = event.target.dataset.id;
    const selectedItem = this.menuList.find((item) => item.Id === itemId);
    if (selectedItem) {
      this.dispatchEvent(
        new CustomEvent("addtocart", {
          detail: selectedItem,
          bubbles: true,
          composed: true
        })
      );
    }
  }
}
