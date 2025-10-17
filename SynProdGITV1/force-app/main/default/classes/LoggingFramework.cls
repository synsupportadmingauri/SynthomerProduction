public without sharing class LoggingFramework {
    public static void CreateLog(String logLevel, String message, String recordId, String recordInfo, String classMethod, String className, String stackTrace){
        
        //create new log based on the method inputs
        Create_Log__e newLog = New Create_Log__e();
        newLog.Log_Level__c = logLevel;
        newLog.Message__c = message;
        newLog.Record_Id__c = recordId;
        newLog.Record_Info__c = recordInfo;
        newLog.Source_Method__c = classMethod;
        newLog.Source_Name__c = className;
        newLog.Source_Type__c = 'Apex';
        newLog.Stack_Trace__c = stackTrace;
        
        //publish the event
        Database.SaveResult sr = EventBus.publish(newLog);
        
        if(!sr.isSuccess()){
            System.debug('Failed to publish platform event for log creation.');
        }
    }	
}