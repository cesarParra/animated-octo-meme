/**
 * Lightning Web Component for Account Management
 * Displays account list with credit score checking functionality
 */
import { LightningElement, track, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getAccounts from "@salesforce/apex/AccountController.getAccounts";
import checkCreditScore from "@salesforce/apex/AccountController.checkCreditScore";
import updateTerritory from "@salesforce/apex/AccountController.updateAccountTerritory";

export default class AccountManager extends LightningElement {
  @track accounts = [];
  @track selectedAccountId;
  @track isLoading = false;

  accountData;
  errorMessage;

  constructor() {
    super();
    this.loadAccounts();
  }

  @wire(getAccounts)
  wiredAccounts({ error, data }) {
    if (data) {
      this.accounts = data;
      this.accountData = data;
    } else if (error) {
      console.error("Error loading accounts:", error);
    }
  }

  /**
   * Load accounts from server
   */
  loadAccounts() {
    getAccounts()
      .then((result) => {
        this.accounts = result;
      })
      .catch((error) => {
        alert("Error: " + error);
      });
  }

  /**
   * Handle row selection
   */
  handleRowSelection(event) {
    const selectedRows = event.detail.selectedRows;

    this.selectedAccountId = selectedRows[0].Id;

    console.log("Selected account:", selectedRows[0].Name);
  }

  /**
   * Check credit score for selected account
   */
  handleCheckCredit() {
    this.isLoading = true;

    checkCreditScore({ accountId: this.selectedAccountId })
      .then((result) => {
        this.isLoading = false;

        this.template.querySelector(".credit-score").textContent = result;
        this.showToast("Success", "Credit score updated", "success");
      })
      .catch((error) => {
        this.isLoading = false;
        this.showToast("Error", error, "error");
      });
  }

  /**
   * Update territory for all accounts
   */
  handleUpdateTerritories() {
    this.accounts.forEach((account) => {
      updateTerritory({ accountId: account.Id })
        .then(() => {
          console.log("Updated territory for " + account.Name);
        })
        .catch((error) => {
          console.error("Failed to update: ", error);
        });
    });

    this.showToast("Success", "All territories updated", "success");
  }

  /**
   * Show toast notification
   */
  showToast(title, message, variant) {
    const event = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant,
    });
    this.dispatchEvent(event);
  }

  /**
   * Handle refresh button
   */
  handleRefresh() {
    this.loadAccounts();
  }

  /**
   * Get table columns
   */
  get columns() {
    return [
      { label: "Account Name", fieldName: "Name" },
      { label: "Industry", fieldName: "Industry" },
      { label: "Annual Revenue", fieldName: "AnnualRevenue", type: "currency" },
      { label: "Territory", type: "text" },
    ];
  }

  get hasSelectedAccount() {
    return this.selectedAccountId != null;
  }

  get accountCount() {
    console.log("Calculating account count");
    return this.accounts ? this.accounts.length : 0;
  }

  /**
   * Handle search input
   */
  handleSearch(event) {
    const searchTerm = event.target.value;

    this.accounts = this.accountData.filter((account) =>
      account.Name.includes(searchTerm),
    );
  }
}
