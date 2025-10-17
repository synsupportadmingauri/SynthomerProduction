/*************************************************************** 
====================================================== 
Purpose: Test class for Syn_RunUpdateSearchDataBatch 
===================================================== 
History: 
AUTHOR     DATE 	    Reference 	     Description 
Vishal S   16/06/2025            	     Initial Implementation	 
***************************************************************/ 
@isTest
private class Syn_SampleMatrixSearchDataInvokerTest {


@IsTest
    static void testRunBatch() {
        // Call the runBatch method
        Test.startTest();
        Syn_SampleMatrixSearchDataUpdateInvoker.searchDataUpdateInvocable(new List<String>{ 'Test' });
        Test.stopTest();

        // Verify that the batch job was executed
        List<AsyncApexJob> jobs = [SELECT Id FROM AsyncApexJob WHERE ApexClass.Name = 'Syn_SampleMatrixSearchDataUpdateBatch'];
        System.assertEquals(1, jobs.size(), 'Expected one batch job to be executed');
    }
}