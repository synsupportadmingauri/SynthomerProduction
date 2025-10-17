/***************************************************************
======================================================
Purpose: Triggers territory assignment for Account records by making HTTP callout
======================================================
History:

AUTHOR     DATE       	Reference      	Description 
Ankur      17-04-2025   SS2-T152     	Initial draft 
***************************************************************/
public with sharing class Syn_CallTerritoryAssignmentAPICtrl {
    
    /******************************************************************* 
    Purpose: Method called from Account Record triggered flow
    for triggering Territory Assignment on Account
    ********************************************************************/
    @InvocableMethod(label='Trigger Territory Assignment via Callout')
    public static void callInternalAPI(List<Id> accountIds) {
        if (accountIds != null && !accountIds.isEmpty()) {
            callAssignmentAPIAsync(accountIds);
        }
    }
    
    /******************************************************************* 
    Purpose: Makes a single composite callout to update dummy field fTestor territory assignment
    ********************************************************************/
    @future(callout=true)
    public static void callAssignmentAPIAsync(List<Id> lstAccountIds) {
        try {
            List<Account> accountsToUpdate = [
                SELECT Id, Territory_Assignment_Dummy_Field__c
                FROM Account
                WHERE Id IN :lstAccountIds
            ];

            List<Map<String, Object>> recordsList = new List<Map<String, Object>>();

            for (Account acc : accountsToUpdate) {
                Boolean newValue = !acc.Territory_Assignment_Dummy_Field__c;

                Map<String, Object> recordMap = new Map<String, Object>{
                    'attributes' => new Map<String, String>{ 'type' => 'Account' },
                    'Id' => acc.Id,
                    'Territory_Assignment_Dummy_Field__c' => newValue
                };

                recordsList.add(recordMap);
            }

            Map<String, Object> body = new Map<String, Object>{
                'allOrNone' => false,
                'records' => recordsList
            };

            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:Territory_Assignment_Named_Credentials/services/data/v63.0/composite/sobjects');
            req.setMethod('PATCH');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Sforce-Auto-Assign', 'True');
            req.setBody(JSON.serialize(body));
			system.debug(JSON.serialize(body));


            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                System.debug('Bulk update successful: ' + res.getBody());
            } else {
                logError('Composite update failed', res.getStatusCode() + ' - ' + res.getBody(), null);
            }
        } catch (Exception e) {
            logError('Exception during composite callout', e.getMessage(), e.getStackTraceString());
        }
    }

    private static void logError(String message, String details, String stackTrace) {
        Log__c errorLog = new Log__c();
        errorLog.Source_Type__c = 'Apex';
        errorLog.Source_Name__c = 'Syn_CallTerritoryAssignmentAPICtrl';
        errorLog.Source_Method__c = 'callAssignmentAPIAsync';
        errorLog.Log_Level__c = 'Error';
        errorLog.Message__c = message;
        errorLog.Stack_Trace__c = stackTrace != null ? stackTrace : details;
        insert errorLog;
    }
}