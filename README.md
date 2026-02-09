# Account Credit Management System - Code Review Exercise

## Project Overview

This Salesforce application manages credit scores and premium calculations for customer accounts. The system integrates with an external credit check API and calculates insurance premiums based on credit scores and risk tiers.

## Key Features

1. **Credit Score Management**
   - Fetches credit scores from external API
   - Automatically calculates premium amounts based on credit score
   - Assigns risk tiers (Low, Medium, High) based on credit score ranges

2. **Premium Calculation**
   - Base premium: $1,000
   - Discounts for higher credit scores
   - Surcharges for lower credit scores
   - Additional adjustments based on account revenue and risk tier

3. **User Interface**
   - Lightning Web Component for viewing and refreshing credit scores
   - One-click premium purchase functionality
   - Visual risk tier indicators

## Data Model

### Custom Fields on Account
- `Credit_Score__c` (Number) - Credit score from API
- `Premium_Amount__c` (Currency) - Calculated premium amount
- `Risk_Tier__c` (Picklist) - Low, Medium, or High
- `Last_Credit_Check__c` (DateTime) - Last API check timestamp

## Code Structure

- **AccountTrigger** - Handles credit score changes and risk tier updates
- **AccountService** - Business logic for credit checks and premium calculations
- **AccountController** - LWC controller for UI operations
- **accountManager** - LWC component for displaying credit info and processing payments
- **TestAccountService** - Test coverage for service layer

## Your Task

Review the code in this pull request as if you were reviewing a teammate's work. Look for:
- Code quality and best practices
- Potential bugs or issues
- Governor limit considerations
- Security concerns
- Test coverage quality
- Performance optimizations

Provide constructive feedback on what you find.
