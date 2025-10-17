@isTest
public class LoggingFrameworkTest {
    @isTest static void testLogCreation(){
		//dummy record id
        String recordId = '001254asdf25311234';
        
        Test.startTest();
        //create a log entry
        LoggingFramework.CreateLog('Error', 'Error while creating account', recordId, 'recordInfo', 'method', 'classname', 'stackTrace');
        Test.stopTest();
     
        //ensure there is log created
        List<Log__c> allLogs = [select record_id__c, log_level__c from Log__c];
        System.assertEquals(allLogs?.size() , 1 , 'Number of logs is incorrect.');
        Log__c log = allLogs[0];
        System.assertEquals(log.Record_Id__c, recordId, 'Record Id is not the same.');
    }
}