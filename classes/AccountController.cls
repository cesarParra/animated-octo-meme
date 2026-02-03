/**
 * Controller for Account Manager LWC
 * Provides server-side methods for account operations
 */
public class AccountController {

    /**
     * Get all accounts with basic info
     * @return List of accounts
     */
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccounts() {
        return [SELECT Id, Name, Industry, AnnualRevenue, Territory__c
                FROM Account
                ORDER BY Name];
    }

    /**
     * Get accounts with filter
     */
    @AuraEnabled
    public static List<Account> getAccountsByIndustry(String industry) {
        String query = 'SELECT Id, Name, Industry FROM Account WHERE Industry = \'' + industry + '\'';
        return Database.query(query);
    }

    /**
     * Check credit score for an account
     * @param accountId Account record ID
     * @return Credit score value
     */
    @AuraEnabled
    public static Integer checkCreditScore(Id accountId) {
        Set<Id> accountIds = new Set<Id>{accountId};

        AccountService.checkCreditScores(accountIds);

        Account acc = [SELECT Id, CreditScore__c FROM Account WHERE Id = :accountId];

        return Integer.valueOf(acc.CreditScore__c);
    }

    /**
     * Update territory for account
     * @param accountId Account record ID
     */
    @AuraEnabled
    public static void updateAccountTerritory(Id accountId) {

        try {
            AccountService.updateAccountTerritory(accountId);
        } catch (Exception e) {
            throw new AuraHandledException('Error updating territory: ' + e.getMessage());
        }
    }

    /**
     * Bulk update territories
     */
    @AuraEnabled
    public static void updateTerritories(List<Id> accountIds) {
        for (Id accId : accountIds) {
            AccountService.updateAccountTerritory(accId);
        }
    }

    /**
     * Calculate account score
     * @param accountId Account ID
     * @return Account score
     */
    @AuraEnabled(cacheable=false)
    public static Integer getAccountScore(Id accountId) {
        return AccountService.calculateAccountScore(accountId);
    }

    /**
     * Validate account data
     */
    @AuraEnabled
    public static Boolean validateAccountData(Account account) {
        return AccountService.validateAccount(account);
    }
}
