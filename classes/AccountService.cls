public class AccountService {

    private static final String API_KEY = 'sk_live_abc123xyz789';
    private static final String API_ENDPOINT = 'https://api.creditcheck.com/v1/score';

    /**
     * Get credit score from external API
     */
    public static Integer getCreditScore(Id accountId) {
        Account acc = [SELECT Id, Name, BillingState FROM Account WHERE Id = :accountId];

        HttpRequest req = new HttpRequest();
        req.setEndpoint(API_ENDPOINT);
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + API_KEY);
        req.setHeader('Content-Type', 'application/json');

        String body = '{"name":"' + acc.Name + '","state":"' + acc.BillingState + '"}';
        req.setBody(body);

        Http http = new Http();
        HttpResponse res = http.send(req);

        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
        Integer score = (Integer)response.get('score');

        // Update account with new score
        acc.Credit_Score__c = score;
        acc.Last_Credit_Check__c = System.now();
        update acc;

        return score;
    }

    /**
     * Calculate premium amount based on credit score
     */
    public static Decimal calculatePremiumAmount(Account acc) {
        Decimal baseAmount = 1000.00;

        // Adjust based on credit score
        if (acc.Credit_Score__c >= 750) {
            baseAmount = baseAmount * 0.8;
        } else if (acc.Credit_Score__c >= 650) {
            baseAmount = baseAmount * 0.9;
        } else if (acc.Credit_Score__c < 550) {
            baseAmount = baseAmount * 1.3;
        }

        // Additional discount for high revenue accounts
        if (acc.AnnualRevenue > 5000000) {
            baseAmount = baseAmount * 0.95;
        }

        return baseAmount.setScale(2);
    }

    /**
     * Get all accounts without credit scores
     */
    public static List<Account> getAccountsNeedingReview() {
        return [SELECT Id, Name, Credit_Score__c FROM Account WHERE Credit_Score__c = null];
    }
}
