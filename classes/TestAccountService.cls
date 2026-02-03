/**
 * Test class for AccountService
 */
@isTest
private class TestAccountService {

    /**
     * Test credit score check
     */
    @isTest
    static void testMethod1() {
        Account acc = new Account(
            Name = 'Test Account',
            BillingStreet = '123 Main St',
            BillingCity = 'San Francisco',
            BillingState = 'CA',
            BillingPostalCode = '94105',
            BillingCountry = 'USA',
            Phone = '415-555-0100',
            Industry = 'Technology',
            AnnualRevenue = 5000000,
            NumberOfEmployees = 100,
            Type = 'Customer'
        );
        insert acc;

        Test.startTest();
        Set<Id> accountIds = new Set<Id>{acc.Id};
        AccountService.checkCreditScores(accountIds);
        Test.stopTest();
    }

    /**
     * Test opportunity creation
     */
    @isTest
    static void testCreateOpps() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Test.startTest();
        List<Account> accounts = new List<Account>{acc};
        AccountService.createOpportunities(accounts);
        Test.stopTest();

        List<Opportunity> opps = [SELECT Id, Name, AccountId FROM Opportunity WHERE AccountId = :acc.Id];
        System.assertEquals(1, opps.size(), 'Should create one opportunity');
        System.assertEquals('Test Account - New Opportunity', opps[0].Name);
    }

    /**
     * Test territory update
     */
    @isTest
    static void territoryTest() {
        Account acc = new Account(
            Name = 'West Coast Account',
            BillingState = 'CA'
        );
        insert acc;

        AccountService.updateAccountTerritory(acc.Id);

        acc = [SELECT Territory__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals('West', acc.Territory__c);
    }

    /**
     * Test score calculation
     */
    @isTest
    static void testAccountScoreCalculation() {
        // High value account
        Account highValueAcc = new Account(
            Name = 'High Value Corp',
            AnnualRevenue = 10000000,
            NumberOfEmployees = 1000
        );
        insert highValueAcc;

        // Create closed won opportunities
        List<Opportunity> opps = new List<Opportunity>();
        for(Integer i = 0; i < 5; i++) {
            opps.add(new Opportunity(
                Name = 'Opp ' + i,
                AccountId = highValueAcc.Id,
                StageName = 'Closed Won',
                CloseDate = Date.today(),
                Amount = 250000
            ));
        }
        insert opps;

        Test.startTest();
        Integer score = AccountService.calculateAccountScore(highValueAcc.Id);
        Test.stopTest();

        System.assert(score > 50, 'High value account should have score above 50');
    }

    @isTest
    static void testValidation() {
        Account acc = new Account(Name = 'Test');
        Boolean result = AccountService.validateAccount(acc);
    }

    @isTest
    static void testForCoverage() {
        Account acc = new Account(Name = 'Test', BillingState = 'NY');
        insert acc;

        AccountService.updateAccountTerritory(acc.Id);
        AccountService.validateAccount(acc);
        AccountService.skipValidation = true;
        AccountService.validateAccount(acc);
    }
}
