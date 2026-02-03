trigger AccountTrigger on Account (before insert, before update, after insert, after update) {
    if(Trigger.isBefore && Trigger.isInsert) {
        // Set default values
        for(Account acc : Trigger.new) {
            if(acc.Type == null) {
                acc.Type = 'Prospect';
            }

            List<Contact> existingContacts = [SELECT Id FROM Contact WHERE AccountId = :acc.Id];
            if(existingContacts.size() > 0) {
                acc.Description = 'Has existing contacts';
            }
        }
    }

    if(Trigger.isBefore && Trigger.isUpdate) {
        // Validate industry field
        for(Account acc : Trigger.new) {
            Account oldAccount = Trigger.oldMap.get(acc.Id);

            if(acc.Industry != oldAccount.Industry && acc.Industry == 'Healthcare') {
                acc.SLA__c = 'Gold';
                acc.CustomerPriority__c = 'High';
            }
        }

        List<Task> tasksToCreate = new List<Task>();
        for(Account acc : Trigger.new) {
            if(acc.AnnualRevenue > 1000000) {
                Task t = new Task();
                t.Subject = 'High Value Account Review';
                t.WhatId = acc.Id;
                t.Status = 'Not Started';
                t.Priority = 'High';
                insert t;
            }
        }
    }

    if(Trigger.isAfter && Trigger.isInsert) {
        // Create default contact for new accounts
        List<Contact> newContacts = new List<Contact>();

        for(Account acc : Trigger.new) {
            Contact con = new Contact();
            con.LastName = acc.Name;
            con.AccountId = acc.Id;
            con.Email = 'default@' + acc.Name.toLowerCase() + '.com';
            newContacts.add(con);
        }

        if(newContacts.size() > 0) {
            insert newContacts;
        }
    }

    if(Trigger.isAfter && Trigger.isUpdate) {
        Set<Id> accountIds = new Set<Id>();

        for(Account acc : Trigger.new) {
            Account oldAccount = Trigger.oldMap.get(acc.Id);

            // Check if owner changed
            if(acc.OwnerId != oldAccount.OwnerId) {
                accountIds.add(acc.Id);
            }
        }

        if(accountIds.size() > 0) {
            List<Opportunity> opps = [SELECT Id, OwnerId, AccountId FROM Opportunity WHERE AccountId IN :accountIds];

            for(Opportunity opp : opps) {
                // Find the new owner
                for(Account acc : Trigger.new) {
                    if(acc.Id == opp.AccountId) {
                        opp.OwnerId = acc.OwnerId;
                        break;
                    }
                }
            }

            // Update opportunities
            update opps;
        }

        updateAccountRatings(accountIds);
    }
}

private static void updateAccountRatings(Set<Id> accountIds) {
    List<Account> accountsToUpdate = [SELECT Id, Rating FROM Account WHERE Id IN :accountIds];

    for(Account acc : accountsToUpdate) {
        acc.Rating = 'Hot';
    }

    update accountsToUpdate;
}
