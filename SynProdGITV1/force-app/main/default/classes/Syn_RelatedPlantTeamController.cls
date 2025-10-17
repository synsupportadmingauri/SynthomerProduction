/*************************************************************** 
====================================================== 
Purpose: Class to Get Related Plant Team members from the Order
===================================================== 
History: 
AUTHOR     DATE         Reference        Description 
Shyam C   13/08/2025                  Initial Implementation  

***************************************************************/

public class Syn_RelatedPlantTeamController {
	@AuraEnabled(cacheable=true)
    public static List<Plant_Team_Data__c> getPlantTeamMembers(Id orderId) {
        Order ord = [
            SELECT Plant__c
            FROM Order
            WHERE Id = :orderId
            LIMIT 1
        ];
        
        return [
            SELECT Id,
                   Role__c,
                   User__r.Name,
                   Employee__r.Name
            FROM Plant_Team_Data__c
            WHERE Plant_ID__c = :ord.Plant__c
        ];
    }
}