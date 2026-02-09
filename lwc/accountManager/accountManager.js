import { LightningElement, api, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getRecord } from "lightning/uiRecordApi";
import getCreditScore from "@salesforce/apex/AccountController.getCreditScore";

const FIELDS = [
  "Account.Name",
  "Account.Credit_Score__c",
  "Account.Premium_Amount__c",
  "Account.Risk_Tier__c",
];

export default class AccountManager extends LightningElement {
  @api recordId;

  creditScore;
  premiumAmount;
  riskTier;
  accountName;

  @wire(getRecord, { recordId: "$recordId", fields: FIELDS })
  wiredAccount({ error, data }) {
    if (data) {
      this.accountName = data.fields.Name.value;
      this.creditScore = data.fields.Credit_Score__c.value;
      this.premiumAmount = data.fields.Premium_Amount__c.value;
      this.riskTier = data.fields.Risk_Tier__c.value;
    }
  }

  handleRefreshScore() {
    getCreditScore({ accountId: this.recordId })
      .then((result) => {
        this.creditScore = result;
        this.showToast("Success", "Credit score refreshed", "success");
      })
      .catch((error) => {
        this.showToast("Error", error.message, "error");
      });
  }

  showToast(title, message, variant) {
    const event = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant,
    });
    this.dispatchEvent(event);
  }

  get riskTierClass() {
    if (this.riskTier === "High") return "slds-badge slds-theme_error";
    if (this.riskTier === "Medium") return "slds-badge slds-theme_warning";
    return "slds-badge slds-theme_success";
  }

  get formattedPremium() {
    return "$" + this.premiumAmount.toFixed(2);
  }
}
