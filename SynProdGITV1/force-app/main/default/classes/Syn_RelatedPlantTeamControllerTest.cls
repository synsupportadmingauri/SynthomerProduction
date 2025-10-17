/*************************************************************** 
====================================================== 
Purpose: Test class for Syn_RelatedPlantTeamController
===================================================== 
History: 
AUTHOR     DATE         Reference        Description 
Shyam C   18-08-2025   INC- 160416       Initial draft   
***************************************************************/

@isTest 
public with sharing class Syn_RelatedPlantTeamControllerTest {

    @isTest
    public static void getPlantTeamMembersTest() {

        Id orderId = Syn_TestDataFactory.createPlantTeam();

        Test.startTest();
         List<Plant_Team_Data__c> result = Syn_RelatedPlantTeamController.getPlantTeamMembers(orderId);
        Test.stopTest();

        
        System.Assert.areNotEqual(null, result, 'List of Plant Team Members should be returned');
    }
}