public class AccountController {

    @AuraEnabled
    public static Integer getCreditScore(Id accountId) {
        return AccountService.getCreditScore(accountId);
    }

    @AuraEnabled(cacheable=true)
    public static Account getAccountDetails(Id accountId) {
        return [SELECT Id, Name, Credit_Score__c, Premium_Amount__c, Risk_Tier__c
                FROM Account
                WHERE Id = :accountId];
    }

    @AuraEnabled
    public static void refreshCreditScore(Id accountId) {
        AccountService.getCreditScore(accountId);
    }
}
