/***************************************************************
================================================================
Purpose: SampleOrderCallout for S4 and Enorica Orders
================================================================
History:

AUTHOR     DATE       	Reference      	Description 
Arpita     03-05-2025   SS2-T189     	Initial draft 
***************************************************************/
public class Syn_SampleOrderCallout {
    
    // Wrapper class for sending input to the future method
    public class InputWrapper {
        @InvocableVariable(required=true)
        public Id orderId;
    }
    
    
    /******************************************************************* 
Purpose: Method called from Order SAP Callout[RTF] and Trigger SAP 
Callout via Button [Autolaunched]
====================================================================
History: 
AUTHOR     DATE          Reference      Description 
Arpita     03-05-2025    SS2-T189     	Initial draft
********************************************************************/
    @InvocableMethod(label='Send Sales Orders to SAP' description='Send Orders to SAP and return response details')
    public static void sendSalesOrderToExternalSystem(List<InputWrapper> inputList) { //previousName - sendSalesOrderToSAP
        
        //System.debug('inputList '+inputList);
        Id orderId = inputList[0].orderId;
        
        Order ord = [SELECT Id, Salesforce_Order_Type__c FROM Order WHERE Id = :orderId LIMIT 1];
        
        // Step 1: Fetch metadata for S4 order types from Custom Metadata
        List<Name_Value_Pair__mdt> s4MetadataRecords = [
            SELECT DeveloperName, Value__c
            FROM Name_Value_Pair__mdt
            WHERE DeveloperName = 'Salesforce_Sample_Order_Type_for_S4'
        ];
        System.debug('Fetched S4 metadata record: ' + s4MetadataRecords);
        
        // Step 2: Create a Set to store S4 order types after splitting and trimming
        Set<String> s4OrderTypes = new Set<String>();
        if (!s4MetadataRecords.isEmpty()) {
            String s4Values = s4MetadataRecords[0].Value__c;
            System.debug('Raw S4 Metadata Value: ' + s4Values);
            
            if (String.isNotBlank(s4Values)) {
                // Handle both single and multiple values separated by ';'
                for (String val : s4Values.split(';')) {
                    s4OrderTypes.add(val.trim());
                }
            }
        }
        System.debug('Processed S4 Order Types: ' + s4OrderTypes);
        
        // Step 3: Fetch metadata for Enorica order types from Custom Metadata
        List<Name_Value_Pair__mdt> enoricaMetadataRecords = [
            SELECT DeveloperName, Value__c
            FROM Name_Value_Pair__mdt
            WHERE DeveloperName = 'Salesforce_Sample_Order_Type_for_Enorica'
        ];
        System.debug('Fetched Enorica metadata record: ' + enoricaMetadataRecords);
        
        // Step 4: Create a Set to store Enorica order types after splitting and trimming
        Set<String> enoricaOrderTypes = new Set<String>();
        if (!enoricaMetadataRecords.isEmpty()) {
            String enoricaValues = enoricaMetadataRecords[0].Value__c;
            System.debug('Raw Enorica Metadata Value: ' + enoricaValues);
            
            if (String.isNotBlank(enoricaValues)) {
                // Handle both single and multiple values separated by ';'
                for (String val : enoricaValues.split(';')) {
                    enoricaOrderTypes.add(val.trim());
                }
            }
        }
        System.debug('Processed Enorica Order Types: ' + enoricaOrderTypes);
        
        // Step 5: Get the current order type from the order record
        String receivedOrderType = ord.Salesforce_Order_Type__c;
        System.debug('Received Order Type: ' + receivedOrderType);
        
        // Step 6: logic to decide which integration to trigger
        if (s4OrderTypes.contains(receivedOrderType)) {
            System.debug('Order type found in S4 list. Sending to S4 system...');
            sendSampleOrdertoS4(orderId); // Call method for S4 integration
        } else if (enoricaOrderTypes.contains(receivedOrderType)) {
            System.debug('Order type found in Enorica list. Sending to Enorica system...');
            sendSampleOrdertoEnorica(orderId); // Call method for Enorica integration
        } else {
            System.debug('Order type not supported or unknown: ' + receivedOrderType);
        } 
    }
    
    
    /******************************************************************* 
Purpose: Method called from sendSalesOrderToSAP for S4 Orders
====================================================================
History: 
AUTHOR     DATE          Reference      Description 
Arpita    03-05-2025    SS2-T189     	Initial draft
********************************************************************/    
    //@future(callout=true)
    public static void sendSampleOrdertoS4(Id orderId) { 
        System.debug('inside sendSampleOrdertoS4');
        String sapOrderId = null;
        String integrationStatus = 'In Error'; // Default
        String orderStatus = 'Approved';       // Default
        String errorMessage = '';
        String responseBody ='';
        
        try {
            String strJsonbody = GUK_INTEG.ReadInterfaceFieldValues.readInterfaceFields('S4 Sample Order Replication', orderId);
            System.debug('strJsonbody ' + strJsonbody);
            
            // Step 1: Fetch config values like User Agent and S4 Endpoint from Custom Metadata
            Map<String, String> configMap = new Map<String, String>();
            
            // Define the metadata keys you want to fetch
            List<String> configKeys = new List<String>{
                'User_Agent',
                    'S4_Sample_Call_Out_End_Point'
                    };
                        
                        
                        // Query custom metadata records for those keys
                        List<Name_Value_Pair__mdt> configRecords = [
                            SELECT DeveloperName, Value__c
                            FROM Name_Value_Pair__mdt
                            WHERE DeveloperName IN :configKeys
                        ];
            
            // Populate the map
            for (Name_Value_Pair__mdt record : configRecords) {
                configMap.put(record.DeveloperName, record.Value__c);
            }
            
            // Extract the values
            String userAgent = configMap.get('User_Agent');
            String s4Endpoint = configMap.get('S4_Sample_Call_Out_End_Point');
            
            // Debug output for verification
            System.debug('User Agent: ' + userAgent);
            System.debug('S4 Sample Callout Endpoint: ' + s4Endpoint);
            
            // Send HTTP Request
            HttpRequest req = new HttpRequest();
            //req.setEndpoint('callout:SAP_CPI_Callout_Named_Credential/http/SFDC/S4/ED1CLNT200/PGTEST_SFDC_SALES_ORDER');
            req.setEndpoint('callout:SAP_CPI_Callout_Named_Credential' +s4Endpoint );
            req.setHeader('User-Agent', 'SFDC-DevMain-CallOut'); //Replace this with  -  req.setHeader('User-Agent', userAgent);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Accept', 'application/json');
            req.setTimeout(120000);//Added by Arpita
            req.setBody(strJsonbody);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            System.debug('request sent');
            System.debug('res.getStatusCode():  '+ res.getStatusCode());
            responseBody = res.getBody();
            System.debug('responseBody:  '+ responseBody);
            
            // Handle response
            if ( res.getStatusCode() >= 200 && res.getStatusCode() < 300 ) {
                System.debug('Inside IF --- Success');
                
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                
                // Navigate through the nested structure
                Map<String, Object> message1 = (Map<String, Object>) responseMap.get('ns0:Message1');
                Map<String, Object> s4Responds = (Map<String, Object>) message1.get('S4Responds');
                
                System.debug(s4Responds);
                // Extract values
                sapOrderId = (String) s4Responds.get('sapOrderId');
                integrationStatus = (String) s4Responds.get('integrationStatus');
                errorMessage  = (String) s4Responds.get('errormessage');
                // Use the extracted values
                System.debug('SAP Order ID: ' + sapOrderId);
                System.debug('Integration Status: ' + integrationStatus);
                System.debug('Error Message: ' + errorMessage);
                
                if (integrationStatus == 'Success') {   
                    orderStatus = 'In Process/Package Preparation';
                    update new Order(
                        Id = orderId,
                        Status = orderStatus,
                        SAP_Order_ID__c = sapOrderId,
                        Integration_Status__c = integrationStatus, 
                        Integration_Error_Log__c =  null
                    ); 
                    System.debug('Order updated with status: ' + orderStatus + ', integrationStatus: ' + integrationStatus);
                }
            } 
            
            if ( !(res.getStatusCode() >= 200 && res.getStatusCode() < 300) || integrationStatus != 'Success' )  {
                // Response received but with error status code (e.g., 400, 500, etc.) or Integration status is not Success
                integrationStatus = 'In Error';
                orderStatus = 'Approved'; // or whatever fallback is appropriate
                System.debug('Order updated due to non-successful HTTP status code: ' + res.getStatusCode());
                Log__c objLog = new Log__c();
                objLog.Record_Id__c 	= orderId;                
                objLog.Source_Type__c 	= 'Apex';
                objLog.Source_Name__c 	= 'Syn_SampleOrderCallout Class';
                objLog.Source_Method__c = 'sendSampleOrdertoS4';
                objLog.Stack_Trace__c 	= 'Response received: '+responseBody;  
                objLog.Log_Level__c 	= 'Error';
                
                if (errorMessage != null ) 
                {
                    objLog.Message__c 	= errorMessage;
                }
                else {
                    objLog.Message__c 	= 'Order updated due to non-successful HTTP status code';
                }
                insert objLog;
                update new Order(
                    Id = orderId,
                    Status = orderStatus,
                    SAP_Order_ID__c = sapOrderId,
                    Integration_Status__c = integrationStatus, 
                    Integration_Error_Log__c =  objLog.Id
                );
                
            }
            
        } catch (Exception objException) {
            System.debug('Callout Exception: ' + objException.getMessage());
            
            // Explicitly set to ensure correctness
            integrationStatus = 'In Error';
            orderStatus = 'Approved';
            System.debug('Order updated with status: ' + orderStatus + ', integrationStatus: ' + integrationStatus);
            Log__c objLog = new Log__c();
            objLog.Record_Id__c = orderId;            
            objLog.Source_Type__c = 'Apex';
            objLog.Source_Name__c = 'Syn_SampleOrderCallout Class';
            objLog.Source_Method__c = 'sendSampleOrdertoS4';
            objLog.Stack_Trace__c = 'Response received: '+responseBody; 
            objLog.Log_Level__c = 'Error';
            objLog.Message__c = objException.getMessage();
                            /*if (errorMessage != null ) 
                {
                objLog.Message__c = errorMessage;
                }
                else {
                objLog.Message__c = 'Order updated due to non-successful HTTP status code';
                }*/
            insert objLog;
            
            update new Order(
                Id = orderId,
                Status = orderStatus,
                SAP_Order_ID__c = sapOrderId,
                Integration_Status__c = integrationStatus,
                Integration_Error_Log__c =  objLog.Id
            );
        }
        
    }
    
    /******************************************************************* 
Purpose: Method called from sendSalesOrderToSAP for Enorica Orders
====================================================================
History: 
AUTHOR     DATE          Reference      Description 
Arpita      03-05-2025    SS2-T189     	Initial draft
********************************************************************/        
    @future(callout=true)
    public static void sendSampleOrdertoEnorica(Id orderId) { //sendSampleOrdertoS4 SendSampleOrderto
        System.debug('inside sendSampleOrderToEnorica');
        
        String integrationStatus = 'In Error'; // Default
        String orderStatus = 'Approved';       // Default
        String errorMessage = '';
        try {
            String strJsonbody = GUK_INTEG.ReadInterfaceFieldValues.readInterfaceFields('Enorica Sample Order Replication', orderId);
            //String strJsonbody = '{"SalesOrder": "9000035893", "ContactPerson": {"Detail": "Petr Vraspir / +420 602 280 472"}, "Owner": {"Name": "Fred Cummings", "Mail": "fred.cummings@synthomer.com"}, "ShippingAddress": {"Ship-toID": "10109455", "OrganizationName1": "STOMIX, spol. s r.o.", "OrganizationName2": "Via ODATA", "StreetName": "Žulová 178", "PostalCode": "790 65", "CityName": "Zulova", "Country": "CZ", "KSAShortAddress": "AAAA8888", "Mail": "x.generic@synthomer.com"}, "Item": [{"ItemNumber": "10", "Material": "100068631", "MaterialDesciption": "PLEXTOL™ D 512 | 1kg BOTTLE", "ItemDesciption": "PLEXTOL™ D 512 | 1kg BOTTLE", "RequestedQuantityUnit": "KGM", "RequestedQuantity": "3,000", "Batch": ""}, {"ItemNumber": "20", "Material": "100068731", "MaterialDesciption": "PLEXTOL™ E 303 | 1kg BOTTLE", "ItemDesciption": "PLEXTOL™ E 303 | 1kg BOTTLE", "RequestedQuantityUnit": "KGM", "RequestedQuantity": "5,000", "Batch": ""}]}';
            System.debug('strJsonbody ' + strJsonbody);
            
            //Fetch config values User-Agent and Enorica Endpoint from Custom Metadata
            Map<String, String> configMap = new Map<String, String>();
            
            // Define the metadata keys you want to fetch
            List<String> configKeys = new List<String>{
                'User_Agent',
                    'Enorica_Sample_Call_Out_End_Point'
                    };
                        
                        // Query custom metadata records for those keys
                        List<Name_Value_Pair__mdt> configRecords = [
                            SELECT DeveloperName, Value__c
                            FROM Name_Value_Pair__mdt
                            WHERE DeveloperName IN :configKeys
                        ];
            
            // Populate the map
            for (Name_Value_Pair__mdt record : configRecords) {
                configMap.put(record.DeveloperName, record.Value__c);
            }
            
            // Extract the values
            String userAgent = configMap.get('User_Agent');
            String enoricaEndpoint = configMap.get('Enorica_Sample_Call_Out_End_Point');
            
            // Debug output for verification
            System.debug('User Agent: ' + userAgent);
            System.debug('S4 Sample Callout Endpoint: ' + enoricaEndpoint);
            
            // Send HTTP Request
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:SAP_CPI_Callout_Named_Credential' +enoricaEndpoint );
            //req.setHeader('User-Agent', 'SFDC-DevMain-CallOut'); //Replace this with  -  req.setHeader('User-Agent', userAgent);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Accept', 'application/json');   
            req.setBody(strJsonbody);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            System.debug('request sent');
            System.debug('res.getStatusCode():  '+ res.getStatusCode());
            String responseBody = res.getBody();
            System.debug('responseBody:  '+ responseBody);
            
            // Handle response
            if ( res.getStatusCode() >= 200 && res.getStatusCode() < 300 ) {
                System.debug('Inside IF --- Success');
                String rawBody = res.getBody();
                System.debug('rawBody'+ rawBody);  
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                String salesforceOrderId = (String) responseMap.get('SFDCOrderId');//changed on 13-05
                integrationStatus = (String) responseMap.get('integrationStatus');
                errorMessage = (String) responseMap.get('errormessage');
                System.debug('salesforceOrderId ' + salesforceOrderId);
                System.debug('Integration Status: ' + integrationStatus);
                System.debug('Error Message: ' + errorMessage);
                
                // Use the extracted values
                System.debug('Integration Status: ' + integrationStatus);
                System.debug('Error Message: ' + errorMessage);
                
                // Use the extracted values
                System.debug('Integration Status: ' + integrationStatus);
                System.debug('Error Message: ' + errorMessage);
                
                if (integrationStatus == 'Success') {   
                    orderStatus = 'In Process/Package Preparation';
                    integrationStatus = 'Success';
                    update new Order(
                        Id = orderId,
                        Status = orderStatus,
                        Integration_Status__c = integrationStatus, 
                        Integration_Error_Log__c = null
                    ); 
                    
                    System.debug('Order updated with status: ' + orderStatus + ', integrationStatus: ' + integrationStatus);
                }
                
            } 
            
            if ( !(res.getStatusCode() >= 200 && res.getStatusCode() < 300) || integrationStatus != 'Success' )  {
                // Response received but with error status code (e.g., 400, 500, etc.) or Integration status is not Success
                integrationStatus = 'In Error';
                orderStatus = 'Approved'; // or whatever fallback is appropriate            
                System.debug('Order updated due to non-successful HTTP status code: ' + res.getStatusCode());
                Log__c objLog = new Log__c();
                objLog.Record_Id__c 	= orderId;                
                objLog.Source_Type__c 	= 'Apex';
                objLog.Source_Name__c 	= 'Syn_SampleOrderCallout Class';
                objLog.Source_Method__c = 'sendSampleOrdertoEnorica';
                objLog.Stack_Trace__c 	= 'Failed patch for Order: ' + orderId ;
                objLog.Log_Level__c 	= 'Error';
                IF (errorMessage != null ) 
                {
                    objLog.Message__c 	= errorMessage;
                }
                else {
                    objLog.Message__c 	= 'Order updated due to non-successful HTTP status code';
                }
                insert objLog; 
                update new Order(
                    Id = orderId,
                    Status = orderStatus,
                    Integration_Status__c = integrationStatus, 
                    Integration_Error_Log__c =  objLog.Id
                    
                );
            }
            
        } catch (Exception objException) {
            System.debug('Callout Exception: ' + objException.getMessage());
            
            // Explicitly set to ensure correctness
            integrationStatus = 'In Error';
            orderStatus = 'Approved';
            System.debug('Order updated with status: ' + orderStatus + ', integrationStatus: ' + integrationStatus);
            Log__c objLog = new Log__c();
            objLog.Record_Id__c = orderId;            
            objLog.Source_Type__c = 'Apex';
            objLog.Source_Name__c = 'Syn_SampleOrderCallout Class';
            objLog.Source_Method__c = 'sendSampleOrdertoEnorica';
            objLog.Stack_Trace__c = 'Failed patch for Order: ' + orderId; 
            objLog.Log_Level__c = 'Error';
            objLog.Message__c = objException.getMessage();
            insert objLog;
            System.debug('created objLog');
            
            
            
            update new Order(
                Id = orderId,
                Status = orderStatus,
                Integration_Status__c = integrationStatus,
                Integration_Error_Log__c =  objLog.Id
            );
            System.debug('Updated Order with objLog Link');
            
            
        }
        
    }
    
}