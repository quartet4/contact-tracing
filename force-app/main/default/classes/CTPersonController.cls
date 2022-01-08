public with sharing class CTPersonController {
    
    public static String getToken(String mobileNumber) {
        Blob targetBlob = Blob.valueOf('mobileNumber');
        Blob hash = Crypto.generateDigest('MD5', targetBlob);

        // get the string value of hash blob
        return EncodingUtil.base64Encode(hash);
    }

    // return list of first 100 Persons
    public static List<Person__c> getRecentHealthChanges() {
        return [SELECT id, Health_Status__c, Mobile__c, Status_Update_Date__c, Token__c 
                    FROM Person__c 
                    ORDER BY Status_Update_Date__c DESC NULLS LAST LIMIT 100];
    }

    // return List of Persons where Name, Mobile or Token matches search term
    public static List<Person__c> searchPeople(String searchTerm) {
        String s = searchTerm + '%';
        return [SELECT id, Health_Status__c, Mobile__c, Status_Update_Date__c, Token__c 
                    FROM Person__c 
                    WHERE (Name LIKE :s) 
                        OR (Mobile__c LIKE :s) 
                        OR (Token__c LIKE :s) 
                    ORDER BY Status_Update_Date__c DESC NULLS LAST];
    }

    // return Person record via Id
    public static Person__c getPersonById(String personId) {
        List<Person__c> p = [SELECT id, Health_Status__c, Mobile__c, Status_Update_Date__c, Token__c 
                    FROM Person__c 
                    WHERE id = :personId LIMIT 1];
        if (p.size() > 0) 
            return p[0]; 
        else
            return null;
    }

    public static Map<String, Integer> getHealthStatusCount() {
        Map<String, Integer> results = new Map<String, Integer>();
        for(AggregateResult ar : [SELECT Health_Status__c, COUNT(Id) total
                                    FROM Person__c
                                    GROUP BY Health_Status__c]) {
            String healthStatus = String.valueOf(ar.get('Health_Status__c'));
            Integer count = Integer.valueOf(ar.get('total'));
            results.put(healthStatus, count);
      }
        return results;
    }

    public static Set<Id> getCohabitants(Set<Id> personIds, Set<Id> alreadyProcessed) {
        List<String> healthStatuses = new List<String>{'Green', 'Yellow'};
        List<People_Tracing__c> peopleTraces = [SELECT Id, Person_1__c, Person_2__c FROM People_Tracing__c
            WHERE (Person_1__c IN :personIds
                OR Person_2__c IN :personIds)
                AND Contact_Type__c = 'Cohabitant'
                AND (Person_1__r.Health_Status__c IN :healthStatuses
                OR Person_2__r.Health_Status__c IN :healthStatuses)];
        Set<Id> cohabitants = new Set<Id>();
        for(People_Tracing__c pt : peopleTraces){
            if(!alreadyProcessed.contains(pt.Person_1__c)){
                cohabitants.add(pt.Person_1__c);
                alreadyProcessed.add(pt.Person_1__c);
            }
            if(!alreadyProcessed.contains(pt.Person_2__c)){
                cohabitants.add(pt.Person_2__c);
                alreadyProcessed.add(pt.Person_2__c);
            }
        }
        return cohabitants;
    }

    public static Set<Id> getNeighbours(Set<Id> personIds, Set<Id> alreadyProcessed) {
        List<People_Tracing__c> peopleTraces = [SELECT Id, Person_1__c, Person_2__c FROM People_Tracing__c
            WHERE (Person_1__c IN :personIds
                OR Person_2__c IN :personIds)
                AND Contact_Type__c = 'Neighbour'
                AND (Person_1__r.Health_Status__c = 'Green'
                OR Person_2__r.Health_Status__c = 'Green')];
        Set<Id> neighbours = new Set<Id>();
        for(People_Tracing__c pt : peopleTraces){
            if(!alreadyProcessed.contains(pt.Person_1__c)){
                neighbours.add(pt.Person_1__c);
                alreadyProcessed.add(pt.Person_1__c);
            }
            if(!alreadyProcessed.contains(pt.Person_2__c)){
                neighbours.add(pt.Person_2__c);
                alreadyProcessed.add(pt.Person_2__c);
            }
        }
        return neighbours;
    }

    public static Set<Id> getPrimaryContacts(Set<Id> personIds, Set<Id> alreadyProcessed) {
        List<String> healthStatuses = new List<String>{'Green', 'Yellow'};
        List<People_Tracing__c> peopleTraces = [SELECT Id, Person_1__c, Person_2__c FROM People_Tracing__c
            WHERE (Person_1__c IN :personIds
                OR Person_2__c IN :personIds)
                AND Contact_Type__c = 'Other'
                AND Contact_Date__c = LAST_N_DAYS:10
                AND (Person_1__r.Health_Status__c IN :healthStatuses
                OR Person_2__r.Health_Status__c IN :healthStatuses)];
        Set<Id> primaryContacts = new Set<Id>();
        for(People_Tracing__c pt : peopleTraces){
            if(!alreadyProcessed.contains(pt.Person_1__c)){
                primaryContacts.add(pt.Person_1__c);
                alreadyProcessed.add(pt.Person_1__c);
            }
            if(!alreadyProcessed.contains(pt.Person_2__c)){
                primaryContacts.add(pt.Person_2__c);
                alreadyProcessed.add(pt.Person_2__c);
            }
        }
        return primaryContacts;
    }

    public static Set<Id> getSecondaryContacts(Set<Id> primaryContactIds, Set<Id> alreadyProcessed) {
        List<People_Tracing__c> peopleTraces = [SELECT Id, Person_1__c, Person_2__c FROM People_Tracing__c
            WHERE (Person_1__c IN :primaryContactIds
                OR Person_2__c IN :primaryContactIds)
                AND Contact_Type__c = 'Other'
                AND Contact_Date__c = LAST_N_DAYS:10
                AND (Person_1__r.Health_Status__c = 'Green'
                OR Person_2__r.Health_Status__c = 'Green')];
        Set<Id> secondaryContacts = new Set<Id>();
        for(People_Tracing__c pt : peopleTraces){
            if(!alreadyProcessed.contains(pt.Person_1__c)){
                secondaryContacts.add(pt.Person_1__c);
                alreadyProcessed.add(pt.Person_1__c);
            }
            if(!alreadyProcessed.contains(pt.Person_2__c)){
                secondaryContacts.add(pt.Person_2__c);
                alreadyProcessed.add(pt.Person_2__c);
            }
        }
        return secondaryContacts;
    }
}