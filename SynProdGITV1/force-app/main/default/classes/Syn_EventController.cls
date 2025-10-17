/*************************************************************** 
====================================================== 
Purpose: Returns the ParentId__c to LWC-redirectToParentChatter
===================================================== 
History: 
AUTHOR     DATE         Reference        Description 
Shyam C   09-10-2025   INC- 165690       Initial draft   
***************************************************************/

public with sharing class Syn_EventController {
    @AuraEnabled(cacheable=true)
    public static Id getParentId(Id eventId) {
        Event ev = [SELECT ParentId__c FROM Event WHERE Id = :eventId LIMIT 1];
        return ev.ParentId__c;
    }
}