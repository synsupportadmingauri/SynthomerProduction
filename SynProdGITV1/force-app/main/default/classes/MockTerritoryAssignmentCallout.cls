/***************************************************************
======================================================
Purpose: Created for generating dummy response
======================================================
History:

AUTHOR     DATE       	Reference      	Description 
Ankur      17-04-2025   SS2-T152     	Initial draft 
***************************************************************/
@isTest
public class MockTerritoryAssignmentCallout implements HttpCalloutMock {
    public static Boolean returnSuccess = true;
    public static Boolean returnException = false;
    
    public HTTPResponse respond(HTTPRequest req) {
        if (returnException) {
            throw new CalloutException('Callout exception');
        }
        
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        
        if (returnSuccess) {
            res.setBody('{"success": true}');
            res.setStatusCode(204);
        } else {
            res.setBody('{"error":"Bad Request"}');
            res.setStatusCode(400);
        }
        
        return res;
    }
}