/*************************************************************** 
====================================================== 
Purpose: Test class for Syn_EventController
===================================================== 
History: 
AUTHOR     DATE         Reference        Description 
Shyam C   15-10-2025   INC- 165690       Initial draft   
***************************************************************/
@IsTest
private class Syn_EventControllerTest {

    @IsTest
    static void testGetParentId_WhenEventHasParent() {
        // Step 1: Create the parent Event
        Event parentEvent = new Event(
            Subject = 'Main Event',
            StartDateTime = System.now(),
            EndDateTime = System.now().addHours(1)
        );
        insert parentEvent;

        // Step 2: Create a child Event with ParentId__c as the parent's Id (as text)
        Event childEvent = new Event(
            Subject = 'Child Event',
            StartDateTime = System.now(),
            EndDateTime = System.now().addHours(1),
            ParentId__c = String.valueOf(parentEvent.Id)
        );
        insert childEvent;

        // Step 3: Query the actual record (since Event IDs can change on insert)
        Event insertedChild = [SELECT Id, ParentId__c FROM Event WHERE Id = :childEvent.Id LIMIT 1];

        // Step 4: Call the method
        Id returnedParentId = Syn_EventController.getParentId(insertedChild.Id);

        // Step 5: Compare against the stored ParentId__c string, not the in-memory parent Id
        System.assertEquals(
            insertedChild.ParentId__c,
            String.valueOf(returnedParentId),
            'Should return the same ParentId__c value stored in the Event record'
        );
    }

}