/*************************************************************** 
====================================================== 
Purpose: Test class for Syn_ScheduledCaseTeamNotifier 
===================================================== 
History: 
AUTHOR     DATE 	    Reference 	     Description 
Vishal S   26/06/2025   				Initial Implementation
***************************************************************/ 
@isTest
private class Syn_ScheduledCaseTeamNotifierTest {

    @IsTest
    static void testScheduleCaseTeamNotifier() {
        Integer existingJobCount = 0;

        // Act: Get scheduled jobs with expected name prefix
        List<CronTrigger> jobs = [
            SELECT Id, CronJobDetail.Name
            FROM CronTrigger
            WHERE CronJobDetail.Name LIKE 'Syn_ScheduledCaseTeamNotifier%'
        ];

        existingJobCount = jobs?.size(); 

        Test.startTest();
        Syn_ScheduledCaseTeamNotifier.scheduleCaseTeamNotifier();
        Test.stopTest();
        
        // Act: Get scheduled jobs with expected name prefix
        jobs = [
            SELECT Id, CronJobDetail.Name
            FROM CronTrigger
            WHERE CronJobDetail.Name LIKE 'Syn_ScheduledCaseTeamNotifier%'
        ];

        //get the name value pair to see how many jobs will be scheduled
        Name_Value_Pair__mdt nameValuePair = [
                        SELECT Value__c  
                        FROM Name_Value_Pair__mdt 
                        WHERE DeveloperName = 'Schedule_Case_Team_Member_Notifier_Min'
                        LIMIT 1
                	];

        //
        Integer everyNthMinute = Integer.valueOf(nameValuePair.Value__c);
        Integer newJobCount = 60/everyNthMinute;
        Integer totalCount = newJobCount + existingJobCount;

        // Assert
        System.assert(!jobs.isEmpty(), 'At least one cron job should be scheduled');
        System.assertEquals(totalCount, jobs.size(), 'Should schedule every 15 minutes → 4 jobs in an hour');
    }
}