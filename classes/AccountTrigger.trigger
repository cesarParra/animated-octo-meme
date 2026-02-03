trigger AccountTrigger on Account (before update, after update) {

    if (Trigger.isBefore && Trigger.isUpdate) {
        // Calculate premium amount based on credit score and other factors
        for (Account acc : Trigger.new) {
            Account oldAccount = Trigger.oldMap.get(acc.Id);

            if (acc.Credit_Score__c != oldAccount.Credit_Score__c && acc.Credit_Score__c != null) {

                Decimal premium = AccountService.calculatePremiumAmount(acc);
                acc.Premium_Amount__c = premium;

                // Set the tier based on credit score
                if (acc.Credit_Score__c >= 750) {
                    acc.Risk_Tier__c = 'Low';
                } else if (acc.Credit_Score__c >= 650) {
                    acc.Risk_Tier__c = 'Medium';
                } else {
                    acc.Risk_Tier__c = 'High';
                }
            }
        }
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        // When we update Risk_Tier__c, it triggers this again

        Set<Id> accountsToUpdate = new Set<Id>();

        for (Account acc : Trigger.new) {
            Account oldAccount = Trigger.oldMap.get(acc.Id);

            // Check if premium amount changed significantly
            if (acc.Premium_Amount__c != oldAccount.Premium_Amount__c) {
                accountsToUpdate.add(acc.Id);
            }
        }

        if (!accountsToUpdate.isEmpty()) {
            for (Id accountId : accountsToUpdate) {
                AccountService.updateRiskTier(accountId);
            }
        }

        // Create task for high-risk accounts
        List<Task> tasksToCreate = new List<Task>();

        for (Account acc : Trigger.new) {
            Account oldAccount = Trigger.oldMap.get(acc.Id);

            if (acc.Risk_Tier__c == 'High' && oldAccount.Risk_Tier__c != 'High') {
                Task t = new Task(
                    Subject = 'Review High Risk Account',
                    WhatId = acc.Id,
                    Status = 'Not Started',
                    Priority = 'High',
                    ActivityDate = Date.today().addDays(7)
                );
                insert t;
            }
        }

        if (!tasksToCreate.isEmpty()) {
            insert tasksToCreate;
        }
    }
}
