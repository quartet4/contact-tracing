public with sharing class AccountContactService {

    public static void updateActiveContacts(Set<Id> accountIds) {
        
        //get aggregate result for all accounts
        List<AggregateResult> results = 
                            [SELECT AccountId, COUNT(Id) totalContact
                            FROM Contact
                            WHERE Active__c = true AND AccountId IN :accountIds
                            GROUP BY AccountId];

        // build final list of accounts to update
        Map<Id, Account> updatedAccounts = new Map<Id, Account>();
        for(AggregateResult result : results) {

            // get account id and number of active contacts
            String accId = String.valueOf(result.get('AccountId'));
            Integer totalContacts = Integer.valueOf(result.get('totalContacts'));

            // make sure you use Id field in your account to update it
            Account acc = new Account(Id=accId, Active_Contacts__c = totalContacts);
            updatedAccounts.put(accId, acc);
        }

        // find missing account ids and set active contacts to zero
        for(Id accId : accountIds) {
            if(!updatedAccounts.containsKey(accId)){
                updatedAccounts.put(accId, new Account(Id=accId, Active_Contacts__c = 0));
            }
        }

        // update the final list of accounts
        update updatedAccounts.values();
    }

}
