/*************************************************************** 
Purpose: Test Class for Syn_RetrieveVisitDetails
====================================================== 
History: 
AUTHOR            DATE       Reference        Description 
Pratik G         21/07/2025  INC.159974       Initial Implementation  
***************************************************************/  
@isTest
private class Syn_RetrieveVisitDetailsTest {

    @isTest
    static void testGetVisitDetails_WithOutcome() {
        // Get the parent event created in test setup
        Syn_TestDataFactory.createVisitData();
        List<Event> lstVisit = [SELECT Id, IsChild FROM Event WHERE Subject =:'Parent Visit'];
		Event visit = lstVisit[0];

        List<String> input = new List<String>{visit.Id};

        // Execute
        Test.startTest();
        List<Syn_RetrieveVisitDetails.VisitDetails> results = Syn_RetrieveVisitDetails.getVisitDetails(input);
        Test.stopTest();

        // Verify
        System.assertEquals(1, results.size(), 'Expected one result');
        Syn_RetrieveVisitDetails.VisitDetails vd = results[0];

        // If your logic resolves the parent internally, you can assert like this:
        System.assertEquals(visit.Id, vd.VisitId, 'Visit ID should be parent ID');
        System.assertNotEquals(null, vd.VisitOutcomeId, 'Outcome ID should not be null');
    }

    @isTest
    static void testGetVisitDetails_WithoutOutcome() {
        // Setup
         Syn_TestDataFactory.createVisitData();
       Event visit = [SELECT ID FROM Event WHERE Subject =:'Child Visit' LIMIT 1];
        List<String> input = new List<String>{visit.Id};

        // Execute
        Test.startTest();
        List<Syn_RetrieveVisitDetails.VisitDetails> results = Syn_RetrieveVisitDetails.getVisitDetails(input);
        Test.stopTest();

        // Verify
        System.assertEquals(1, results.size(), 'Expected one result');
        Syn_RetrieveVisitDetails.VisitDetails vd = results[0];
        System.assertEquals(visit.Id, vd.VisitId, 'Visit ID should be parent ID');
        System.assertEquals(null, vd.VisitOutcomeId, 'Outcome ID should be null');
    }


    @isTest
    static void testGetVisitDetails_EmptyInput() {
        // Setup
        List<String> input = new List<String>();

        // Execute
        Test.startTest();
        List<Syn_RetrieveVisitDetails.VisitDetails> results = Syn_RetrieveVisitDetails.getVisitDetails(input);
        Test.stopTest();

        // Verify
        System.assertEquals(0, results.size(), 'Expected empty result for empty input');
    }
}