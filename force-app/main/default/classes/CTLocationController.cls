public with sharing class CTLocationController {
    
    public static List<Location__c> getRecentStatusChanges() {
        return [SELECT Id, Name, Address__c, Pincode__c, Red_Score__c, Status_Update_Date__c, Status__c
                    FROM Location__c
                    ORDER BY Status_Update_Date__c
                    DESC NULLS LAST LIMIT 100];
    }

    public static List<Location__c> searchLocations(String searchTerm) {
        String s = searchTerm + '%';
        return [SELECT Id, Name, Address__c, Pincode__c, Red_Score__c, Status_Update_Date__c, Status__c
                    FROM Location__c
                    WHERE (Name LIKE :s) 
                        OR (Pincode__c LIKE :s) 
                        OR (Address__c LIKE :s) 
                    ORDER BY Status_Update_Date__c 
                    DESC NULLS LAST];
    }

    public static Location__c getLocationById(String locationId) {
        List<Location__c> l = [SELECT Id, Name, Address__c, Pincode__c, Red_Score__c, Status_Update_Date__c, Status__c
                                    FROM Location__c
                                    WHERE Id = :locationId];
        if (l.size() > 0) {
            return l[0];
        }
        return null;
    }

    public static Map<String, Integer> getStatusCount() {
        Map<String, Integer> results = new Map<String, Integer>();
        for(AggregateResult ar : [SELECT Status__c, COUNT(Id) total
                                    FROM Location__c
                                    GROUP BY Status__c]) {
            String healthStatus = String.valueOf(ar.get('Health_Status__c'));
            Integer count = Integer.valueOf(ar.get('total'));
            results.put(healthStatus, count);
        }
        return results;
    }
 
}
