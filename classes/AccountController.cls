public class AccountController {

    /**
     * Get credit score for an account
     * @param accountId The account record ID
     * @return Credit score value
     */
    @AuraEnabled
    public static Integer getCreditScore(Id accountId) {
        try {
            return AccountService.getCreditScore(accountId);
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving credit score: ' + e.getMessage());
        }
    }

    /**
     * Get account details including premium amount
     * @param accountId The account record ID
     * @return Account with premium details
     */
    @AuraEnabled(cacheable=true)
    public static Account getAccountDetails(Id accountId) {

        try {
            return [SELECT Id, Name, Credit_Score__c, Premium_Amount__c, Risk_Tier__c,
                    Last_Credit_Check__c, Stripe_Customer_Id__c
                    FROM Account
                    WHERE Id = :accountId
                    LIMIT 1];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving account: ' + e.getMessage());
        }
    }

    /**
     * Process payment for account premium
     * @param accountId The account record ID
     * @param amount The payment amount
     * @return Stripe charge ID
     */
    @AuraEnabled
    public static String processPayment(Id accountId, Decimal amount) {

        try {
            return StripeIntegrationService.processPayment(accountId, amount);
        } catch (Exception e) {
            throw new AuraHandledException('Payment processing failed: ' + e.getMessage());
        }
    }

    /**
     * Refresh credit score (calls API and updates account)
     */
    @AuraEnabled
    public static void refreshCreditScore(Id accountId) {
        Integer score = AccountService.getCreditScore(accountId);
    }
}
