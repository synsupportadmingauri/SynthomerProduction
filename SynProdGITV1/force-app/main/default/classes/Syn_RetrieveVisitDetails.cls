/*************************************************************** 
Purpose: Retrieve all visit details (including Archieved)  
====================================================== 
History: 
AUTHOR            DATE       Reference        Description 
Pratik G         21/07/2025  INC.159974       Initial Implementation  
***************************************************************/
public with sharing class Syn_RetrieveVisitDetails {
    // Custom class to hold output structure for Flow
    public class VisitDetails {
        @InvocableVariable(label='Visit ID' description='The ID of the Visit/Event')
        public String VisitId;
        
        @InvocableVariable(label='Visit Outcome ID' description='The Visit_Outcome_Id__c field value')
        public String VisitOutcomeId;
        
        public VisitDetails(String visitId, String visitOutcomeId) {
            this.VisitId = visitId;
            this.VisitOutcomeId = visitOutcomeId;
        }
    }
    
/*************************************************************** 
Purpose: Retrieve all visit details (including Archieved) 
====================================================== 
History: 
AUTHOR                   DATE       Reference        Description 
Pratik G/Vishal S         21/07/2025  INC.159974       Initial Implementation  
***************************************************************/
    @InvocableMethod(label='Retrieve Visit Details' description='Returns Visit ID and Visit_Outcome_Id__c for given Visit IDs')
    public static List<VisitDetails> getVisitDetails(List<String> visitIds) {
    // First: Get parent IDs from child visits
            Map<Id, Id> childToParentMap = new Map<Id, Id>();
            for (Event evt : [
                SELECT Id, ParentId__c
                FROM Event
                WHERE Id IN :visitIds
                ALL ROWS
            ]) {
                	
                if (evt.ParentId__c != null) {
                    childToParentMap.put(evt.Id, evt.ParentId__c);
                } else{
                    childToParentMap.put(evt.Id, evt.Id);
                }
            }
        
        
            
            // Second: Get parent visit records
            Set<Id> parentIds = new Set<Id>(childToParentMap.values());
            List<Event> parentVisits = [
                SELECT Id, Visit_Outcome__r.Id
                FROM Event
                WHERE Id IN :parentIds AND IsChild = False
                ALL ROWS
            ];
        
        	
            // Map for faster lookup
            Map<Id, Event> parentVisitMap = new Map<Id, Event>();
            for (Event evt : parentVisits) {
                parentVisitMap.put(evt.Id, evt);
            }
            
            // Construct results based on original input
            List<VisitDetails> results = new List<VisitDetails>();
            for (Id childId : childToParentMap.keySet()) {
                Id parentId = childToParentMap.get(childId);
                Event parentVisit = parentVisitMap.get(parentId);
                if (parentVisit != null) {
                    String outcomeId = parentVisit.Visit_Outcome__r != null ? parentVisit.Visit_Outcome__r.Id : null;
                    results.add(new VisitDetails(parentId, outcomeId));
                }
            }
        	
            return results;
        }


}