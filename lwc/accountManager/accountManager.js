/**
 * Lightning Web Component for Account Credit Score and Payment
 * Displays credit score and allows payment processing
 */
import { LightningElement, api, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getRecord } from "lightning/uiRecordApi";
import getCreditScore from "@salesforce/apex/AccountController.getCreditScore";
import getAccountDetails from "@salesforce/apex/AccountController.getAccountDetails";
import processPayment from "@salesforce/apex/AccountController.processPayment";

const FIELDS = [
  "Account.Name",
  "Account.Credit_Score__c",
  "Account.Premium_Amount__c",
  "Account.Risk_Tier__c",
];

export default class AccountCreditScore extends LightningElement {
  @api recordId;

  @track creditScore;
  @track premiumAmount;
  @track riskTier;
  @track isLoading = false;

  accountData;
  errorMessage;

  @wire(getRecord, { recordId: "$recordId", fields: FIELDS })
  wiredAccount({ error, data }) {
    if (data) {
      this.accountData = data;
      this.creditScore = data.fields.Credit_Score__c.value;
      this.premiumAmount = data.fields.Premium_Amount__c.value;
      this.riskTier = data.fields.Risk_Tier__c.value;
    } else if (error) {
      console.error("Error loading account:", error);
    }
  }

  /**
   * Handle refresh credit score button click
   */
  handleRefreshScore() {
    this.isLoading = true;

    getCreditScore({ accountId: this.recordId })
      .then((result) => {
        this.isLoading = false;
        this.creditScore = result;

        this.showToast("Success", "Credit score updated", "success");
      })
      .catch((error) => {
        this.isLoading = false;
        this.showToast("Error", error, "error");
      });
  }

  /**
   * Handle buy button click
   */
  handleBuyClick() {
    processPayment({
      accountId: this.recordId,
      amount: this.premiumAmount,
    })
      .then((chargeId) => {
        this.showToast("Success", "Payment processed successfully!", "success");
      })
      .catch((error) => {
        this.showToast(
          "Error",
          "Payment failed: " + error.body.message,
          "error",
        );
      });
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
   * Get CSS class for risk tier badge
   */
  get riskTierClass() {
    if (this.riskTier === "High") {
      return "slds-badge slds-theme_error";
    } else if (this.riskTier === "Medium") {
      return "slds-badge slds-theme_warning";
    } else {
      return "slds-badge slds-theme_success";
    }
  }

  /**
   * Check if buy button should be disabled
   */
  get isBuyDisabled() {
    return !this.premiumAmount || this.premiumAmount <= 0 || this.isLoading;
  }

  /**
   * Format premium amount for display
   */
  get formattedPremium() {
    return "$" + this.premiumAmount.toFixed(2);
  }
}
