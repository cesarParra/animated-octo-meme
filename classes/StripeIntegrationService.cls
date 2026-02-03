
public class StripeIntegrationService {


    private static final String STRIPE_API_KEY = 'sk_test_4eC39HqLyjWDarjtT1zdp7dc';


    private static final String STRIPE_ENDPOINT = 'https://api.stripe.com/v1';


    private static final Id PAYMENT_RECORD_TYPE_ID = '0122w000000XtHcAAK';

    /**
     * Process payment for an account's premium
     */
    public static String processPayment(Id accountId, Decimal amount) {



        Account acc = [SELECT Id, Name, BillingStreet, BillingCity, BillingState
                       FROM Account WHERE Id = :accountId];

        HttpRequest req = new HttpRequest();
        req.setEndpoint(STRIPE_ENDPOINT + '/charges');
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + STRIPE_API_KEY);
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');


        String body = 'amount=' + Integer.valueOf(amount * 100) +
                     '&currency=usd' +
                     '&description=Premium for ' + EncodingUtil.urlEncode(acc.Name, 'UTF-8') +
                     '&metadata[account_id]=' + accountId;
        req.setBody(body);


        Http http = new Http();
        HttpResponse res = http.send(req);

        String responseBody = res.getBody();

        Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
        String chargeId = (String)response.get('id');

        Payment__c payment = new Payment__c();
        payment.Account__c = accountId;
        payment.Stripe_Charge_Id__c = chargeId;
        payment.Amount__c = amount;
        payment.Status__c = 'Completed';
        payment.Payment_Date__c = System.today();
        payment.RecordTypeId = PAYMENT_RECORD_TYPE_ID;
        insert payment;

        return chargeId;
    }

    /**
     * Process payments for multiple accounts
     */
    public static void processPayments(List<Id> accountIds, List<Decimal> amounts) {
        for (Integer i = 0; i < accountIds.size(); i++) {
            try {
                processPayment(accountIds[i], amounts[i]);
            } catch (Exception e) {
                System.debug('Payment failed: ' + e.getMessage());
            }
        }
    }

    /**
     * Create a Stripe customer for an account
     */
    @future(callout=true)
    public static void createStripeCustomer(Id accountId) {
        Account acc = [SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode
                       FROM Account WHERE Id = :accountId];

        HttpRequest req = new HttpRequest();
        req.setEndpoint(STRIPE_ENDPOINT + '/customers');
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + STRIPE_API_KEY);
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setTimeout(120000);

        String body = 'name=' + EncodingUtil.urlEncode(acc.Name, 'UTF-8') +
                     '&metadata[salesforce_id]=' + accountId;
        req.setBody(body);

        try {
            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
                String customerId = (String)response.get('id');

                // Update account with Stripe customer ID
                Account accToUpdate = new Account(Id = accountId);
                accToUpdate.Stripe_Customer_Id__c = customerId;

                update accToUpdate;
            } else {
                System.debug('Error creating customer: ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }

    /**
     * Refund a payment
     */
    public static void refundPayment(Id paymentId) {
        Payment__c payment = [SELECT Id, Stripe_Charge_Id__c, Amount__c
                              FROM Payment__c WHERE Id = :paymentId];

        HttpRequest req = new HttpRequest();
        req.setEndpoint(STRIPE_ENDPOINT + '/refunds');
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + STRIPE_API_KEY);
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');

        String body = 'charge=' + payment.Stripe_Charge_Id__c;
        req.setBody(body);

        Http http = new Http();
        HttpResponse res = http.send(req);

        payment.Status__c = 'Refunded';
        payment.Refund_Date__c = System.today();
        update payment;
    }
}
