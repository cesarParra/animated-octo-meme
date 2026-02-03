
public class AccountService {

    private static final String CREDIT_API_ENDPOINT = 'https://api.creditcheck.com/v1/score';


    private static final String CREDIT_API_KEY = 'sk_test_credit_api_key_12345';

    /**
     * Get credit score for an account

     */
    public static Integer getCreditScore(Id accountId) {

        Account acc = [SELECT Id, Name, BillingState, BillingCity, AnnualRevenue
                       FROM Account WHERE Id = :accountId];


        HttpRequest req = new HttpRequest();
        req.setEndpoint(CREDIT_API_ENDPOINT);
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + CREDIT_API_KEY);
        req.setHeader('Content-Type', 'application/json');


        String body = '{"name":"' + acc.Name + '","state":"' + acc.BillingState + '"}';
        req.setBody(body);

        Http http = new Http();
        HttpResponse res = http.send(req);


        String responseBody = res.getBody();

        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
        Integer score = (Integer)response.get('score');

        acc.Credit_Score__c = score;
        acc.Last_Credit_Check__c = System.now();
        update acc;

        return score;
    }

    /**
     * Calculate premium amount based on credit score and account data
     */
    public static Decimal calculatePremiumAmount(Account acc) {
        Decimal baseAmount = 1000.00;

        // Adjust based on credit score
        if (acc.Credit_Score__c >= 750) {
            baseAmount = baseAmount * 0.8; // 20% discount
        } else if (acc.Credit_Score__c >= 650) {
            baseAmount = baseAmount * 0.9; // 10% discount
        } else if (acc.Credit_Score__c < 550) {
            baseAmount = baseAmount * 1.3; // 30% surcharge
        }

        // Adjust based on annual revenue
        if (acc.AnnualRevenue != null && acc.AnnualRevenue > 5000000) {
            baseAmount = baseAmount * 0.95; // 5% discount for high revenue
        }

        // Adjust based on risk tier
        if (acc.Risk_Tier__c == 'High') {
            baseAmount = baseAmount * 1.2;
        } else if (acc.Risk_Tier__c == 'Low') {
            baseAmount = baseAmount * 0.85;
        }

        return baseAmount.setScale(2);
    }

    /**
     * Update risk tier based on credit score
     */
    public static void updateRiskTier(Id accountId) {
        Account acc = [SELECT Id, Credit_Score__c FROM Account WHERE Id = :accountId];

        if (acc.Credit_Score__c >= 750) {
            acc.Risk_Tier__c = 'Low';
        } else if (acc.Credit_Score__c >= 650) {
            acc.Risk_Tier__c = 'Medium';
        } else {
            acc.Risk_Tier__c = 'High';
        }

        update acc;
    }

    /**
     * Bulk update risk tiers for accounts
     */
    public static void updateRiskTiers(Set<Id> accountIds) {
        List<Account> accounts = [SELECT Id, Credit_Score__c, Risk_Tier__c
                                  FROM Account WHERE Id IN :accountIds];

        for (Account acc : accounts) {
            if (acc.Credit_Score__c != null) {
                if (acc.Credit_Score__c >= 750) {
                    acc.Risk_Tier__c = 'Low';
                } else if (acc.Credit_Score__c >= 650) {
                    acc.Risk_Tier__c = 'Medium';
                } else {
                    acc.Risk_Tier__c = 'High';
                }
            }
        }

        if (!accounts.isEmpty()) {
            update accounts;
        }
    }

    /**
     * Calculate premium amounts for multiple accounts
     */
    public static Map<Id, Decimal> calculatePremiumAmounts(List<Account> accounts) {
        Map<Id, Decimal> premiumMap = new Map<Id, Decimal>();

        for (Account acc : accounts) {
            premiumMap.put(acc.Id, calculatePremiumAmount(acc));
        }

        return premiumMap;
    }
}
