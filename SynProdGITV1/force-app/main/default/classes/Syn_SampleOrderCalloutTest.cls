/*************************************************************** 
====================================================== 
Purpose: Test class for Syn_SampleOrderCallout
===================================================== 
History: 
AUTHOR     DATE         Reference        Description 
Arpita R  12-05-2025   SS2-T189         Initial draft   
***************************************************************/
@isTest 
public class Syn_SampleOrderCalloutTest {
    
    /*************************************************************** 
====================================================== 
Purpose: Mocks a successful S4 API response
===================================================== 
History: 
AUTHOR     DATE         Reference        Description 
Arpita R  12-05-2025   SS2-T189         Initial draft   
***************************************************************/
    class S4MockResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"ns0:Message1":{"S4Responds":{"sapOrderId":"SAP12345","integrationStatus":"Success","errormessage":""}}}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    /*************************************************************** 
====================================================== 
Purpose: Mocks a successful Enorica API response
===================================================== 
History: 
AUTHOR     DATE         Reference        Description 
Arpita R  12-05-2025   SS2-T189         Initial draft   
***************************************************************/
    class EnoricaMockResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"SalesforceOrderId": "904567890", "integrationStatus": "Success", "errormessage": ""}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    /*************************************************************** 
====================================================== 
Purpose: Mocks a Failure Enorica API response[Invalid Status Code]
===================================================== 
History: 
AUTHOR     DATE         Reference        Description 
Arpita R  12-05-2025   SS2-T189         Initial draft   
***************************************************************/
    public class EnoricaMockResponse_Failure implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"result": "error"}');
            return res;
        }
    }
    /*************************************************************** 
====================================================== 
Purpose: Mocks a Failure Enorica API response[Invalid JSON]
===================================================== 
History: 
AUTHOR     DATE         Reference        Description 
Arpita R  12-05-2025   SS2-T189         Initial draft   
***************************************************************/
    public class EnoricaMockResponse_InvalidJson implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"result": "'); // Invalid JSON
            return res;
        }
    }
    
        /*************************************************************** 
====================================================== 
Purpose: Callout to S4 System[Success]
===================================================== 
History: 
AUTHOR     DATE         Reference        Description 
Arpita R  12-05-2025   SS2-T189         Initial draft   
***************************************************************/
    @isTest
    static void testSendSalesOrderToSAP_S4() {
        // Arrange
        Order ord = Syn_TestDataFactory.createOrderWithItem('ZPLS'); // Pass order type as needed
        
        Syn_SampleOrderCallout.InputWrapper wrapper = new Syn_SampleOrderCallout.InputWrapper();
        wrapper.orderId = ord.Id;
        Test.setMock(HttpCalloutMock.class, new S4MockResponse());
        
        Test.startTest();
        Syn_SampleOrderCallout.sendSalesOrderToExternalSystem(new List<Syn_SampleOrderCallout.InputWrapper>{ wrapper });
        Test.stopTest();
        
        // Assert
        Order updatedOrder = [SELECT Status, SAP_Order_ID__c, Integration_Status__c FROM Order WHERE Id = :ord.Id];
        System.assertEquals('In Process/Package Preparation', updatedOrder.Status);
        System.assertEquals('SAP12345', updatedOrder.SAP_Order_ID__c);
        System.assertEquals('Success', updatedOrder.Integration_Status__c);
    }

            /*************************************************************** 
====================================================== 
Purpose: Callout to Enorica System[Success]
===================================================== 
History: 
AUTHOR     DATE         Reference        Description 
Arpita R  12-05-2025   SS2-T189         Initial draft   
***************************************************************/
    @isTest
    public static void testSendSampleOrdertoEnorica() {
        // Create a mock Order record
        Order ord = Syn_TestDataFactory.createOrderWithItem('ZSLS'); 
        
        Syn_SampleOrderCallout.InputWrapper wrapper = new Syn_SampleOrderCallout.InputWrapper();
        wrapper.orderId = ord.Id;
        Test.setMock(HttpCalloutMock.class, new EnoricaMockResponse());
        // Set up the mock for the HTTP response
        
        
        // Run the method
        Test.startTest();
        Syn_SampleOrderCallout.sendSalesOrderToExternalSystem(new List<Syn_SampleOrderCallout.InputWrapper>{ wrapper });
        Test.stopTest();
        
        
        //Verify the results for Enorica (success)
        Order updatedOrder = [SELECT Id, Status, Integration_Status__c FROM Order WHERE Id = :ord.Id];
        System.assertEquals('In Process/Package Preparation', updatedOrder.Status);
        System.assertEquals('Success', updatedOrder.Integration_Status__c);
    }
    
    
    
/*************************************************************** 
====================================================== 
Purpose: Callout to Enorica System[Failure]
===================================================== 
History: 
AUTHOR     DATE         Reference        Description 
Arpita R  12-05-2025   SS2-T189         Initial draft   
***************************************************************/   
    @isTest
    static void testSendSampleOrdertoEnorica_FailureResponse() {
        Order ord = Syn_TestDataFactory.createOrderWithItem('ZSLS');
        Test.setMock(HttpCalloutMock.class, new EnoricaMockResponse_Failure());
        
        Test.startTest();
        Syn_SampleOrderCallout.sendSampleOrdertoEnorica(ord.Id);
        Test.stopTest();
        
        Order updatedOrder = [SELECT Id, Status, Integration_Status__c FROM Order WHERE Id = :ord.Id];
        System.assertEquals('Approved', updatedOrder.Status); // or whatever your fallback is
    }
    
    
/*************************************************************** 
====================================================== 
Purpose: Callout to Enorica System[Failure]
===================================================== 
History: 
AUTHOR     DATE         Reference        Description 
Arpita R  12-05-2025   SS2-T189         Initial draft   
***************************************************************/   
    
    @isTest
    static void testSendSampleOrdertoEnorica_InvalidJson() {
        Order ord = Syn_TestDataFactory.createOrderWithItem('ZSLS');
        Test.setMock(HttpCalloutMock.class, new EnoricaMockResponse_InvalidJson());
        
        Test.startTest();
        Syn_SampleOrderCallout.sendSampleOrdertoEnorica(ord.Id);
        Test.stopTest();
        
        Order updatedOrder = [SELECT Id, Status, Integration_Status__c FROM Order WHERE Id = :ord.Id];
        System.assertEquals('Approved', updatedOrder.Status);
        System.assertEquals('In Error', updatedOrder.Integration_Status__c);
    }
    
/*************************************************************** 
====================================================== 
Purpose: Callout to S4 System[Failure]
===================================================== 
History: 
AUTHOR     DATE         Reference        Description 
Arpita R  12-05-2025   SS2-T189         Initial draft   
***************************************************************/   
    public class S4MockResponse_Failure implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status": "error", "message": "Internal server error"}');
            return res;
        }
    }
    
/*************************************************************** 
====================================================== 
Purpose: Callout to S4 System[Failure]
===================================================== 
History: 
AUTHOR     DATE         Reference        Description 
Arpita R  12-05-2025   SS2-T189         Initial draft   
***************************************************************/   
    @isTest
    static void testS4Callout_Failure() {
        // Arrange
        Order ord = Syn_TestDataFactory.createOrderWithItem('ZPLS');
        Test.setMock(HttpCalloutMock.class, new S4MockResponse_Failure());
        
        // Act
        Test.startTest();
        Syn_SampleOrderCallout.sendSampleOrdertoS4(ord.Id); // Replace with your actual S4 method
        Test.stopTest();
        
        // Assert
        Order updatedOrder = [SELECT Id, Integration_Status__c FROM Order WHERE Id = :ord.Id];
        System.assertEquals('In Error', updatedOrder.Integration_Status__c);
    }
    // Invalid JSON from S4
    public class S4MockResponse_InvalidJson implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status": '); // Malformed JSON
            return res;
        }
    }

/*************************************************************** 
====================================================== 
Purpose: Callout to S4 System[Failure - Invalid JSON]
===================================================== 
History: 
AUTHOR     DATE         Reference        Description 
Arpita R  12-05-2025   SS2-T189         Initial draft   
***************************************************************/   
    @isTest
    static void testS4Callout_InvalidJson() {
        // Arrange
        Order ord = Syn_TestDataFactory.createOrderWithItem('ZPLS');
        Test.setMock(HttpCalloutMock.class, new S4MockResponse_InvalidJson());
        
        // Act
        Test.startTest();
        Syn_SampleOrderCallout.sendSampleOrdertoS4(ord.Id); 
        Test.stopTest();
        
        // Assert
        Order updatedOrder = [SELECT Id, Integration_Status__c FROM Order WHERE Id = :ord.Id];
        System.assertEquals('In Error', updatedOrder.Integration_Status__c); 
    }
    
    
}