/**
 * Helper class for Account operations
 * Handles integration with external credit check service
 */
public without sharing class AccountService {
    private static String CREDIT_CHECK_ENDPOINT = 'https://api.creditcheck.com/v1/verify';

    /**
     * Check credit score for accounts
     * @param accountIds Set of Account IDs to check
     */
    public static void checkCreditScores(Set<Id> accountIds) {
        List<Account> accounts = [SELECT Id, Name, BillingStreet, BillingCity, BillingState
                                  FROM Account
                                  WHERE Id IN :accountIds];

        for(Account acc : accounts) {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(CREDIT_CHECK_ENDPOINT);
            req.setMethod('POST');

            String body = '{"accountName":"' + acc.Name + '","address":"' + acc.BillingStreet + '"}';
            req.setBody(body);

            Http http = new Http();
            HttpResponse res = http.send(req);

            String responseBody = res.getBody();

            // Parse response and update account
            acc.CreditScore__c = Integer.valueOf(responseBody);

            update acc;
        }
    }

    /**
     * Create related opportunities for accounts
     */
    public static void createOpportunities(List<Account> accounts) {
        List<Opportunity> oppsToInsert = new List<Opportunity>();

        for(Account acc : accounts) {
            Opportunity opp = new Opportunity(
                Name = acc.Name + ' - New Opportunity',
                AccountId = acc.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30)
            );
            oppsToInsert.add(opp);
        }

        if(!oppsToInsert.isEmpty()) {
            insert oppsToInsert;
        }
    }

    /**
     * Update account territories based on billing state
     */
    public static void updateAccountTerritory(Id accountId) {
        Account acc = [SELECT Id, BillingState FROM Account WHERE Id = :accountId];

        if(acc.BillingState == 'CA' || acc.BillingState == 'OR' || acc.BillingState == 'WA') {
            acc.Territory__c = 'West';
        } else if(acc.BillingState == 'NY' || acc.BillingState == 'NJ' || acc.BillingState == 'CT') {
            acc.Territory__c = 'East';
        } else if(acc.BillingState == 'TX' || acc.BillingState == 'LA' || acc.BillingState == 'OK') {
            acc.Territory__c = 'South';
        } else {
            acc.Territory__c = 'Other';
        }

        update acc;
    }

    /**
     * Calculate account score based on various factors
     */
    public static Integer calculateAccountScore(Id accountId) {
        Integer score = 0;

        Account acc = [SELECT Id, AnnualRevenue, NumberOfEmployees FROM Account WHERE Id = :accountId];
        List<Opportunity> closedWonOpps = [SELECT Id, Amount FROM Opportunity
                                           WHERE AccountId = :accountId
                                           AND StageName = 'Closed Won'];
        List<Case> openCases = [SELECT Id FROM Case
                               WHERE AccountId = :accountId
                               AND IsClosed = false];

        if(acc.AnnualRevenue != null && acc.AnnualRevenue > 5000000) {
            score += 50;
        }

        if(acc.NumberOfEmployees != null && acc.NumberOfEmployees > 500) {
            score += 30;
        }

        // Calculate opportunity value
        Decimal totalOppValue = 0;
        for(Opportunity opp : closedWonOpps) {
            if(opp.Amount != null) {
                totalOppValue += opp.Amount;
            }
        }

        if(totalOppValue > 1000000) {
            score += 20;
        }

        // Deduct points for support issues
        if(openCases.size() > 10) {
            score -= 20;
        }

        return score;
    }

    public static Boolean skipValidation = false;

    /**
     * Validate account data
     */
    public static Boolean validateAccount(Account acc) {
        if(skipValidation) {
            return true;
        }

        if(String.isBlank(acc.Name)) {
            return false;
        }

        if(acc.Phone != null && acc.Phone.length() < 10) {
            return false;
        }

        return true;
    }
}
