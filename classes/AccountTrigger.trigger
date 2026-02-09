trigger AccountTrigger on Account (before update, after update) {

    if (Trigger.isBefore && Trigger.isUpdate) {
        // Calculate premium amount based on credit score
        for (Account acc : Trigger.new) {
            Account oldAccount = Trigger.oldMap.get(acc.Id);

            if (acc.Credit_Score__c != oldAccount.Credit_Score__c) {
                // Calculate premium
                Decimal premium = AccountService.calculatePremiumAmount(acc);
                acc.Premium_Amount__c = premium;

                // Set risk tier based on credit score
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
        // Send notification email when credit score changes
        for (Account acc : Trigger.new) {
            Account oldAccount = Trigger.oldMap.get(acc.Id);

            if (acc.Credit_Score__c != oldAccount.Credit_Score__c) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new String[]{'admin@company.com'});
                email.setSubject('Credit Score Updated');
                email.setPlainTextBody('Credit score changed for account: ' + acc.Name);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
            }
        }

        // Create tasks for high-risk accounts
        for (Account acc : Trigger.new) {
            Account oldAccount = Trigger.oldMap.get(acc.Id);

            if (acc.Risk_Tier__c == 'High' && oldAccount.Risk_Tier__c != 'High') {
                Task t = new Task(
                    Subject = 'Review High Risk Account',
                    WhatId = acc.Id,
                    Status = 'Not Started',
                    Priority = 'High'
                );
                insert t;
            }
        }
    }
}
