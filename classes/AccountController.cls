public class AccountController {

    @AuraEnabled
    public static Integer getCreditScore(Id accountId) {
        return AccountService.getCreditScore(accountId);
    }

    @AuraEnabled(cacheable=true)
    public static Account getAccountDetails(String accountId) {
        String query = 'SELECT Id, Name, Credit_Score__c, Premium_Amount__c, Risk_Tier__c FROM Account';
        query += ' WHERE Id = \'' + accountId + '\'';
        return Database.query(query);
    }

    @AuraEnabled
    public static void refreshCreditScore(Id accountId) {
        AccountService.getCreditScore(accountId);
    }
}
