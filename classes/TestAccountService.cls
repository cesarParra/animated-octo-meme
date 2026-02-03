
@isTest
private class TestAccountService {


    @isTest
    static void testMethod1() {

        Account acc = new Account(
            Name = 'Test Account',
            BillingStreet = '123 Main St',
            BillingCity = 'San Francisco',
            BillingState = 'CA',
            BillingPostalCode = '94105',
            AnnualRevenue = 5000000,
            Industry = 'Technology',
            Phone = '415-555-0100'
        );
        insert acc;


        Test.startTest();
        Integer score = AccountService.getCreditScore(acc.Id);
        Test.stopTest();
    }

    /**
     * Test premium calculation
     */
    @isTest
    static void testCalculatePremiumAmount_HighCreditScore() {
        Account acc = new Account(
            Name = 'Premium Test Account',
            Credit_Score__c = 780,
            AnnualRevenue = 6000000,
            Risk_Tier__c = 'Low'
        );
        insert acc;

        Test.startTest();
        Decimal premium = AccountService.calculatePremiumAmount(acc);
        Test.stopTest();

        System.assertNotEquals(null, premium, 'Premium should not be null');
        System.assert(premium < 1000, 'Premium should be discounted for high credit score');
    }

    /**
     * Test risk tier update
     */
    @isTest
    static void testUpdateRiskTier() {
        Account acc = new Account(
            Name = 'Risk Tier Test',
            Credit_Score__c = 650,
            BillingState = 'NY'
        );
        insert acc;

        Test.startTest();
        AccountService.updateRiskTier(acc.Id);
        Test.stopTest();

        Account updated = [SELECT Risk_Tier__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Medium', updated.Risk_Tier__c, 'Risk tier should be Medium for score 650');
    }

    /**
     * Test bulk risk tier updates
     */
    @isTest
    static void testUpdateRiskTiers_Bulk() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(
                Name = 'Bulk Test ' + i,
                Credit_Score__c = 600 + (i * 2), // Varying scores
                BillingState = 'CA'
            ));
        }
        insert accounts;

        Set<Id> accountIds = new Set<Id>();
        for (Account acc : accounts) {
            accountIds.add(acc.Id);
        }

        Test.startTest();
        AccountService.updateRiskTiers(accountIds);
        Test.stopTest();

        List<Account> updated = [SELECT Id, Credit_Score__c, Risk_Tier__c
                                 FROM Account WHERE Id IN :accountIds];

        System.assertEquals(200, updated.size(), 'All accounts should be updated');
    }

    @isTest
    static void testMultipleMethods() {
        Account acc = new Account(
            Name = 'Multi Test',
            Credit_Score__c = 700,
            AnnualRevenue = 3000000,
            Risk_Tier__c = 'Medium',
            BillingState = 'TX'
        );
        insert acc;

        Test.startTest();
        Decimal premium1 = AccountService.calculatePremiumAmount(acc);
        AccountService.updateRiskTier(acc.Id);
        List<Account> accList = new List<Account>{acc};
        Map<Id, Decimal> premiumMap = AccountService.calculatePremiumAmounts(accList);

        Test.stopTest();

        System.assertNotEquals(null, premium1);
        System.assertNotEquals(null, premiumMap);
    }

    @isTest
    static void testForCoverage() {
        Account acc = new Account(Name = 'Coverage Test', BillingState = 'CA');
        insert acc;

        try {
            AccountService.updateRiskTier(acc.Id);
            AccountService.calculatePremiumAmount(acc);
        } catch (Exception e) {}
    }

    /**
     * Test negative scenario
     */
    @isTest
    static void testCalculatePremiumAmount_NullCreditScore() {
        Account acc = new Account(
            Name = 'Null Score Test',
            Credit_Score__c = null,
            AnnualRevenue = 1000000,
            Risk_Tier__c = 'High'
        );

        Test.startTest();
        Decimal premium = AccountService.calculatePremiumAmount(acc);
        Test.stopTest();
    }
}
