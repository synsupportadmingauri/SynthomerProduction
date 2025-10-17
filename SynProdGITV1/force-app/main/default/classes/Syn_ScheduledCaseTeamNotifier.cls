/*************************************************************** 
====================================================== 
Purpose: Schedule the Notify Case team member flow 
===================================================== 
History: 
AUTHOR     DATE 	    Reference 	     Description 
Vishal S   26/06/2025   				Initial Implementation
***************************************************************/ 
global with sharing class Syn_ScheduledCaseTeamNotifier implements Schedulable {
    global void execute(SchedulableContext sc) {
        new Flow.Interview.SubFlow_Notify_New_Case_Team_Member(
            new Map<String, Object>()
        ).start();
    }

    // Call this once to schedule the job hourly
    public static void scheduleCaseTeamNotifier() {
        
                    Name_Value_Pair__mdt nameValuePair = [
                        SELECT Value__c  
                        FROM Name_Value_Pair__mdt 
                        WHERE DeveloperName = 'Schedule_Case_Team_Member_Notifier_Min'
                        LIMIT 1
                	];
                
                Integer everyNthMinute = Integer.valueOf(nameValuePair.Value__c);
                String nameOfSchedulableClass = 'Syn_ScheduledCaseTeamNotifier';
                
        		String scheduleName;
                Integer counter = 1;
                for (Integer minute = 0; minute < 60; minute++) {
                    if (Math.mod(minute, everyNthMinute) == 0) {
                        If(Test.isRunningTest()){
                        	scheduleName = nameOfSchedulableClass +' Test '+ String.valueOf(counter);    
                        }
                        Else{
                            scheduleName = nameOfSchedulableClass +' '+ String.valueOf(counter);
                        }
                        
                        String cronPattern  = '0 ' + String.valueOf(minute) + ' * * * ?';
                        System.schedule(scheduleName, cronPattern, (Schedulable) Type.forName(nameOfSchedulableClass).newInstance());
                        counter++;
                    }
                }
    }
}