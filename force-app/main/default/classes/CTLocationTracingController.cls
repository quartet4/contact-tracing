public with sharing class CTLocationTracingController {
    
    public static List<Location_Tracing__c> getVisitors (String locationId) {
        List<Location_Tracing__c> l = 
            [SELECT Id, Person__c, Location__c, Visit_Date__c, Person__r.Token__c, Person__r.Health_Status__c 
                FROM Location_Tracing__c
                WHERE Id = : locationId
                ORDER BY Visit_Date__c 
                DESC NULLS LAST];
        if (l.size() > 0) {
            return l;
        }
        return null;
    }

    public static List<Location_Tracing__c> getLocationsByPersonIds (Set<Id> personIds) {
        List<Location_Tracing__c> l = 
            [SELECT Id, Person__c, Location__c 
                FROM Location_Tracing__c
                WHERE Person__c IN :personIds
                    AND Visit_Date__c = LAST_N_DAYS:10];
        if (l.size() > 0) {
            return l;
        }
        return null;
    }

    public static List<Location_Tracing__c> getLocationsByLocationIds (Set<Id> locationIds) {
        List<Location_Tracing__c> l = 
            [SELECT Id, Person__c, Location__c, Person__r.Health_Status__c 
                FROM Location_Tracing__c
                WHERE Location__c IN :locationIds
                    AND Person__r.Health_Status__c = 'Green'
                    AND Visit_Date__c = LAST_N_DAYS:10];
        if (l.size() > 0) {
            return l;
        }
        return null;
    }

    public static List<Location_Tracing__c> checkDuplicates (List<Location_Tracing__c> newLocationTraces) {


        Set<Id> locationIds = new Set<Id>();
        Set<Id> personIds = new Set<Id>();

        for(Location_Tracing__c trace : newLocationTraces) {
            locationIds.add(trace.Location__c);
            personIds.add(trace.Person__c);
        }

        // map of location Ids
        Map<Id, Set<Id>> mapOfExistingRecords = new Map<Id, Set<Id>>();
        // query existing location tracing records
        List<Location_Tracing__c> existingRecords = [SELECT Id, Person__c, Location__c
                                                        FROM Location_Tracing__c
                                                        WHERE Location__c IN :locationIds
                                                        AND Person__c IN :personIds];
        // list of dupe records
        List<Location_Tracing__c> duplicates = new List<Location_Tracing__c>();

        if(existingRecords != null && existingRecords.size() > 0) {
            for(Location_Tracing__c trace : existingRecords) {
                // check if map already has the locationId key
                if(!mapOfExistingRecords.containsKey(trace.Location__c)) {
                    // map does not have this key
                    // Add this new item in the map using location id as key
                    // and blank Set<Id> as value
                    mapOfExistingRecords.put(trace.Location__c, new Set<Id>());
                }
                // get map item using locationId key
                Set<Id> personIdSet = mapOfExistingRecords.get(trace.Location__c);
                // add the person id to the set
                personIdSet.add(trace.Person__c);
                // overwrite the existing map value
                mapOfExistingRecords.put(trace.Location__c, personIdSet);
            }

            // loop over new location tracing records
            for (Location_Tracing__c trace: newLocationTraces) {
                // first check for location id
                // if item found in map, then check for person in set
                if(mapOfExistingRecords.containsKey(trace.Location__c) 
                    && mapOfExistingRecords.get(trace.Location__c).contains(trace.Person__c))
                        duplicates.add(trace);
                }
            }
            return duplicates;
        
        }
        
}
