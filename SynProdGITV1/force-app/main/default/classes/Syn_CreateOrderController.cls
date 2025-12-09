/*************************************************************** 
====================================================== 
Purpose: Class to Create the sample order with products 
===================================================== 
History: 
AUTHOR     DATE         Reference        Description 
Vishal S   03/06/2025    SSP-353        Initial Implementation  
Vishal S   21/07/2025    INC. 159362    Determine the currency for non ZPLS sample order 
Shyam C    16/09/2025    INC. 163626    Return Plant Currency for non ZPLS sample Order
Ankur O	   03/10/2025	 SD1-T64		Assign Name while creating Order
***************************************************************/
public  without sharing  class Syn_CreateOrderController {
    // Wrapper class to return Opportunity, Account, and Contact data together
    public class WrapperOrderData {       
        @AuraEnabled public Id opportunityId { get; set; }
        @AuraEnabled public Id accountId { get; set; }
        @AuraEnabled public Id contactId { get; set; }
        @AuraEnabled public Id shipToAccountId {get; set;}
        @AuraEnabled public String errorMessage { get; set; }
        
        // Constructor for the wrapper
        public WrapperOrderData(Id opportunityId, Id accountId, Id contactId, Id shipToAccountId, String errorMessage) {        
            this.opportunityId = opportunityId;
            this.accountId = accountId;
            this.contactId = contactId;
            this.shipToAccountId = shipToAccountId;
            this.errorMessage = errorMessage;
        }
    }

    /*************************************************************** 
====================================================== 
Purpose: method to insert the Order 
===================================================== 
History: 
AUTHOR     DATE         Reference        Description 
Vishal S   03/06/2025    SSP-353        Initial Implementation   
***************************************************************/
public class EvaluatedAccountInfo{
    @AuraEnabled public String evaluatedSoldToParty;
    @AuraEnabled public String incoterms;
    @AuraEnabled public String paymentTerm;
    @AuraEnabled public String incotermLocation;
    @AuraEnabled public String currencyIsoCode;

      public EvaluatedAccountInfo() {
          
        }
    
    public EvaluatedAccountInfo(String evaluatedSoldToParty, String incoterms, String paymentTerm, String incotermLocation, String currencyIsoCode) {
        this.evaluatedSoldToParty = evaluatedSoldToParty;
        this.incoterms = incoterms;
        this.paymentTerm = paymentTerm;
        this.incotermLocation = incotermLocation;
        this.currencyIsoCode = currencyIsoCode;
    }
}

    
    /**
* @purpose : Get Details of record based on Provided Id
* @param : recordId : Id of the record
* @return : WrapperOrderData : Wrapper class with Opportunity, Account, and Contact data
*/
    @AuraEnabled(cacheable=true)
    public static WrapperOrderData getRecordDetails(Id recordId) {
        Boolean blnPartnerUser = [SELECT Id, IsPartner FROM User WHERE Id = :UserInfo.getUserId()].isPartner;
        
        if(!blnPartnerUser){
            // Check if the recordId starts with "006" (Opportunity record ID prefix)
            if (String.valueOf(recordId).startsWith('006')) {            
                Opportunity opp = [SELECT Id, Name, AccountId FROM Opportunity WHERE Id = :recordId LIMIT 1];
                Account acc = [SELECT Id, Name, BillingAddress, (SELECT Id, Name FROM Contacts LIMIT 2) FROM Account WHERE Id = :opp.AccountId LIMIT 1];
                
                // Get Account and Contact IDs
                Id accountId = acc.Id;
                
                //get default ship to account
                Id shipToAccount = getShipToAccount(accountId);
                
                
                // Return the wrapper with Opportunity, Account, and Contact data
                return new WrapperOrderData(
                    opp.Id, 
                    accountId, 
                    acc.Contacts.size() == 1 ? acc.Contacts[0].Id : null, 
                    shipToAccount != null ? shipToAccount : null,
                    null
                );
                
            } else if(String.valueOf(recordId).startsWith('001')) {
                Account acc = [SELECT Id, Name, BillingAddress,(SELECT Id, Name FROM Contacts LIMIT 2) FROM Account WHERE Id = :recordId LIMIT 1];
                
                // Get Account and Contact IDs
                Id accountId = acc.Id;
                
                //get default ship to account
                Id shipToAccount =getShipToAccount(accountId);
                
                return new WrapperOrderData(
                    null, 
                    accountId, 
                    acc.Contacts.size() == 1 ? acc.Contacts[0].Id : null,
                    shipToAccount != null ? shipToAccount : null,  
                    null
                );
                
            } else{
                return new WrapperOrderData(null, null, null, null, 'Invalid record ID. This is not an Opportunity or Account record.');
            }
        }else{
            
            	User objUser = [SELECT Id, AccountId, ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
                // Get Account and Contact IDs
                Id accountId = objUser.AccountId;
                
                //get default ship to account
                Id shipToAccount = getShipToAccount(accountId);
                
                
                // Return the wrapper with Opportunity, Account, and Contact data
                return new WrapperOrderData(
                    null, 
                    accountId != null ? accountId : null, 
                    objUser.ContactId != null ? objUser.ContactId : null, 
                    shipToAccount != null ? shipToAccount : null,
                    null
                );
            
        }
        
    }
 
    /*************************************************************** 
====================================================== 
Purpose: method to default the ship to account if only one Account Partner present 
===================================================== 
History: 
AUTHOR     DATE         Reference        Description 
Vishal S   17/06/2025    SSP-353        Initial Implementation   
***************************************************************/
    public static Id getShipToAccount(Id accountId) {
    List<Account_Partners_Data__c> lstAccountPartnerData = [
        SELECT Id, Name, Main_Partner__c, Related_Customer_ID__c 
        FROM Account_Partners_Data__c 
        WHERE Main_Partner__c = :accountId
    ];

    if (lstAccountPartnerData.size() == 1) {
        String externalId = lstAccountPartnerData[0].Related_Customer_ID__c;

        try {
        Account acc = [
            SELECT Id, Account_DM_External_ID__c 
            FROM Account 
            WHERE Account_DM_External_ID__c = :externalId 
            LIMIT 1
        ];
            
        return acc.Id;
     } catch (Exception e) {
        System.debug('No account found for external ID: ' + externalId);
        return null;
     }
    }

    return null;
}

    /*************************************************************** 
====================================================== 
Purpose: method to default the ship to account if only one Account Partner present 
===================================================== 
History: 
AUTHOR     DATE         Reference        Description 
Vishal S   20/06/2025    SSP-353        Initial Implementation   
***************************************************************/
@AuraEnabled
public static boolean validateShipToContact(Id contactId, Id accountId){

    List<AccountContactRelation> lstAcctConRel = [SELECT Id, AccountId, ContactId, IsActive FROM AccountContactRelation WHERE ContactId =: contactId ];

    
    for(AccountContactRelation acctConRel: lstAcctConRel){
        if(acctConRel.AccountId == accountId && acctConRel.IsActive){
            return true;
        }
    }
    return false;
}
    
    /**
* @purpose : Get the Billing and Shipping address for provided Account Id
* @param : accountIdList : List of Account Ids
* @return : Map<Id, Account> : Map of Account Id and Account record
*/
    @AuraEnabled
    public static Map<Id, Account> getAccountDetails(List<Id> accountIdList){
        Map<Id, Account> accountMap = new Map<Id, Account>();
        
        try {
            for (Account accountRec : [SELECT BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,ShippingStreet,
                                       ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry,ShippingStateCode, ShippingCountryCode,
                                       CurrencyIsoCode, Region__c
                                       FROM Account
                                       WHERE Id IN :new Set<Id>(accountIdList)]
                ) {
                    accountMap.put(accountRec.Id, accountRec);
                }
            
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        
        return accountMap;
    }

/*************************************************************** 
====================================================== 
Purpose: method to determine the currency code for the order 
===================================================== 
History: 
AUTHOR     DATE         Reference        Description 

***************************************************************/
   @AuraEnabled
    public static Id createOrderWithProducts(Map<String, Object> orderFields, List<Map<String, Object>> orderProducts) {
        try {
            Order newOrder = new Order();
            newOrder.AccountId = (Id)orderFields.get('AccountId');
            newOrder.Ship_To_Account__c = (Id)orderFields.get('Ship_To_Account__c');
            newOrder.EffectiveDate = Date.valueOf((String)orderFields.get('EffectiveDate'));
            newOrder.Status = (String)orderFields.get('Status');
            newOrder.Pricebook2Id = (Id)orderFields.get('Pricebook2Id');
            newOrder.CurrencyIsoCode = (String)orderFields.get('CurrencyIsoCode');
            newOrder.BillingStreet = (String)orderFields.get('BillingStreet');
            newOrder.BillingCity = (String)orderFields.get('BillingCity');
            newOrder.BillingState = (String)orderFields.get('BillingState');
            newOrder.BillingPostalCode = (String)orderFields.get('BillingPostalCode');
            newOrder.BillingCountry = (String)orderFields.get('BillingCountry');
            newOrder.ShippingStreet = (String)orderFields.get('ShippingStreet');
            newOrder.ShippingCity = (String)orderFields.get('ShippingCity');
            newOrder.ShippingState = (String)orderFields.get('ShippingState');
            newOrder.ShippingPostalCode = (String)orderFields.get('ShippingPostalCode');
            newOrder.ShippingCountry = (String)orderFields.get('ShippingCountry');
            newOrder.Plant__c = (String)orderFields.get('Plant__c');
            newOrder.Sales_Organisation__c = (String)orderFields.get('Sales_Orgnization__c');
            newOrder.Delivery_Block__c = (String)orderFields.get('Delivery_Block__c');
            newOrder.Distribution_Channel__c = (String)orderFields.get('Distribution_Channel__c');
            newOrder.S4_Order_Type__c = (String)orderFields.get('S4_Order_Type__c');
            newOrder.Salesforce_Order_Type__c = (String)orderFields.get('Salesforce_Order_Type__c');
            newOrder.Division__c = (String)orderFields.get('Division__c');
            newOrder.Shipping_Condition__c = (String)orderFields.get('Shipping_Condition__c');
            newOrder.Incoterms__c = (String)orderFields.get('IncoTerms__c');
            newOrder.Evaluated_Sold_To_Party__c = (String)orderFields.get('Evaluated_Sold_To_Party__c');
            newOrder.Incoterms_Location__c = (String)orderFields.get('IncoTerms_Location__c');
            newOrder.Payment_Terms__c = (String)orderFields.get('Payment_Terms__c');
            newOrder.OpportunityId = (Id)orderFields.get('OpportunityId');
            newOrder.ShipToContactId = (Id)orderFields.get('ShipToContactId');
            newOrder.Is_Ship_To_Contact_Related__c = (Boolean)orderFields.get('isShipToContactRelated');
            
            newOrder.End_Customer__c = (String)orderFields.get('End_Customer__c');
            //17/10/2025 Arpita R - Changed Data type to Number
			//newOrder.Potential_Volume__c = (String)orderFields.get('Potential_Volume__c');
			if (orderFields.get('Potential_Volume1__c') != ''  ) {
               newOrder.Potential_Volume1__c = 
               Decimal.valueOf((String)orderFields.get('Potential_Volume1__c'));
            }

			//newOrder.Potential_Volume1__c = Decimal.valueOf((String)orderFields.get('Potential_Volume1__c'));
			newOrder.Application__c = (String)orderFields.get('Application__c');
			newOrder.Name = (String)orderFields.get('Name');								// SD1-T64+ 03/10/2025 Ankur O
            
            insert newOrder;

            insertOrderProducts(orderProducts, newOrder.Id);

            return newOrder.Id;
            } catch (AuraHandledException ahe) {
            throw ahe; // already has the correct message
        } catch (Exception e) {
            throw new AuraHandledException('Order creation failed: ' + e.getMessage());
        }
    }
 
    /*************************************************************** 
====================================================== 
Purpose: method to insert the Order Products
===================================================== 
History: 
AUTHOR     DATE         Reference        Description 
Vishal S   26/04/2025    SSP-353        Initial Implementation   
***************************************************************/
  @AuraEnabled
public static void insertOrderProducts(List<Map<String, Object>> orderProduct, Id orderId) {

    List<OrderItem> lstOrderProductToInsert = new List<OrderItem>();

    // These are common for all products
    Id pricebook2Id = (Id)orderProduct[0].get('pricebook2Id');
    String currencyIsoCode = (String)orderProduct[0].get('currencyIsoCode');
    

    // Collect unique Product2Ids
    Set<Id> productIds = new Set<Id>();
    for (Map<String, Object> item : orderProduct) {
        productIds.add((Id)item.get('productId'));
    }

    // Query all needed PricebookEntries
    Map<Id, Id> productToPbeIdMap = new Map<Id, Id>();
    List<PricebookEntry> pbeList = [
        SELECT Id, Product2Id
        FROM PricebookEntry
        WHERE Pricebook2Id = :pricebook2Id
          AND CurrencyIsoCode = :currencyIsoCode
          AND Product2Id IN :productIds
    ];

    for (PricebookEntry pbe : pbeList) {
        productToPbeIdMap.put(pbe.Product2Id, pbe.Id);
    }

    // Build OrderItems
    for (Map<String, Object> item : orderProduct) {
        Id productId = (Id)item.get('productId');
        Id pricebookEntryId = productToPbeIdMap.get(productId);

        if (pricebookEntryId == null) {
            throw new AuraHandledException('Missing PricebookEntry for ProductId: ' + productId);
        }

        OrderItem orderProductLine = new OrderItem();
        orderProductLine.OrderId = orderId;
        orderProductLine.Sample_Master_Matrix_Data__c = (String)item.get('Id');
        orderProductLine.Product2Id = productId;
        orderProductLine.PricebookEntryId = pricebookEntryId;
        orderProductLine.Quantity = (Decimal)item.get('quantity');
        orderProductLine.Total_Price_Internal__c = (Decimal)item.get('totalPrice');
        orderProductLine.Description = (String)item.get('description');
        orderProductLine.Plant__c = (String)item.get('plantId');
        orderProductLine.Salesforce_Order_Type__c = (String)item.get('SalesforceOrderType');
        orderProductLine.S4_Order_Type__c = (String)item.get('s4OrderType');
        orderProductLine.S4_Item_Category__c = (String)item.get('itemCategory');
        orderProductLine.Sales_Organisation__c = (String)item.get('salesOrg');
        orderProductLine.Distribution_Channel__c = (String)item.get('distributionChannel');
        orderProductLine.Division__c = (String)item.get('division');
        orderProductLine.Quantity_UoM__c = (String)item.get('uomId');
        orderProductLine.Default_Product_Used__c = (Boolean)item.get('defaultProductUsed');

        if (item.containsKey('stockLevel')) {
            orderProductLine.Estimated_Stock__c = Decimal.valueOf(String.valueOf(item.get('stockLevel')));
        }
        if (item.containsKey('shippingDate')) {
            orderProductLine.Shipping_Date__c = (Date)item.get('shippingDate');
        }

        lstOrderProductToInsert.add(orderProductLine);
    }

    // Insert OrderItems
    try {
        insert lstOrderProductToInsert;
    } catch (DmlException e) {
       String errorMsg = e.getDmlMessage(0); 
    
        throw new AuraHandledException('Order item insert failed: ' + errorMsg);
    }
}

@AuraEnabled(cacheable=true)
public static List<Opportunity> getOpportunitiesByAccount(Id accountId) {
    try {
        return [SELECT Id, Name 
                FROM Opportunity 
                WHERE AccountId = :accountId 
                AND IsClosed = false 
                ORDER BY Name 
                LIMIT 100];
    } catch (Exception e) {
        throw new AuraHandledException('Error fetching opportunities: ' + e.getMessage());
    }
} 
/*************************************************************** 
===================================================================================
Purpose: Method to determine the one time customer for Domestic or International
====================================================================================
History: 
AUTHOR     DATE         Reference        Description 
Vishal S   06/05/2025    SSP-353        Initial Implementation   
***************************************************************/
@AuraEnabled
public static EvaluatedAccountInfo getEvaluatedSoldToParty(String accountId, String plantId, String shippingCountry) {
    System.debug('Acc id is '+ accountId);
    System.debug('plantid'+plantId);
    System.debug('shipping country'+shippingCountry);
    if (String.isBlank(accountId) || String.isBlank(plantId) || String.isBlank(shippingCountry)) {
        throw new AuraHandledException('Missing required parameters.');
    }
    
    try {
        // Step 1: Get Account details
        Account account = [
            SELECT Id, Type, Name 
            FROM Account 
            WHERE Id = :accountId 
            LIMIT 1
        ];

        // Step 2: Get Plant Address and extract country
        Plant__c plant = [
            SELECT Id, Address__c 
            FROM Plant__c 
            WHERE Id = :plantId 
            LIMIT 1
        ];
        Address plantAddress = plant.Address__c;
        String plantCountry = plantAddress != null ? plantAddress.country : null;
        if (String.isBlank(plantCountry)) {
            throw new AuraHandledException('Plant country is missing.');
        }
        // Step 3: Get Order Type Determination for Plant
        List<Salesforce_Order_Type_Determination__c> orderTypes = [
            SELECT Id, Sales_Org__c, Distribution_Channel__c, Division__c, 
                   One_Time_Customer_ID_Domestic__c, One_Time_Customer_ID_International__c  
            FROM Salesforce_Order_Type_Determination__c
            WHERE Plant_ID__c = :plantId 
              AND Active__c = true
            LIMIT 1
        ];

        if (orderTypes.isEmpty()) {
            throw new AuraHandledException('No active Order Type Determination found for the Plant.');
        }

        Salesforce_Order_Type_Determination__c orderType = orderTypes[0];
        String evaluatedSoldToParty;

        // Step 4: Determine if shipping is domestic or international
        if (plantCountry.equalsIgnoreCase(shippingCountry)) {
            evaluatedSoldToParty = orderType.One_Time_Customer_ID_Domestic__c;
        } else {
            evaluatedSoldToParty = orderType.One_Time_Customer_ID_International__c;
        }

        // Step 5: Return early for Prospects
        if (account.Type == 'Prospect' && account.Name != 'Test Customer Account') {
            EvaluatedAccountInfo result = new EvaluatedAccountInfo();
            result.evaluatedSoldToParty = evaluatedSoldToParty;

            // Query sales data for evaluatedSoldToParty
            List<Account_Sales_Data__c> oneTimeAccountSalesDataList = [
                SELECT Payment_Term__c, Incoterms__c, Incoterms_Location__c, CurrencyIsoCode, 
                       Sales_Org_Data__c, Distribution_Channel__c, Division__c
                FROM Account_Sales_Data__c
                WHERE Account__c = :evaluatedSoldToParty
            ];

            for (Account_Sales_Data__c salesData : oneTimeAccountSalesDataList) {
                if (salesData.Sales_Org_Data__c == orderType.Sales_Org__c &&
                    salesData.Distribution_Channel__c == orderType.Distribution_Channel__c &&
                    salesData.Division__c == orderType.Division__c) {

                    result.incoterms = salesData.Incoterms__c;
                    result.paymentTerm = salesData.Payment_Term__c;
                    result.incotermLocation = salesData.Incoterms_Location__c;
                    result.currencyIsoCode = salesData.CurrencyIsoCode;
                    break;
                }
            }
            return result;
        }

        // Step 6: Check if Sales Data exists for original account
        List<Account_Sales_Data__c> accountSalesDataList = [
            SELECT Payment_Term__c, Incoterms__c, Incoterms_Location__c, CurrencyIsoCode, 
                   Sales_Org_Data__c, Distribution_Channel__c, Division__c
            FROM Account_Sales_Data__c
            WHERE Account__c = :accountId
        ];

        for (Account_Sales_Data__c salesData : accountSalesDataList) {
            if (salesData.Sales_Org_Data__c == orderType.Sales_Org__c &&
                salesData.Distribution_Channel__c == orderType.Distribution_Channel__c &&
                salesData.Division__c == orderType.Division__c) {

                EvaluatedAccountInfo result = new EvaluatedAccountInfo();
                result.evaluatedSoldToParty = accountId;
                result.incoterms = salesData.Incoterms__c;
                result.paymentTerm = salesData.Payment_Term__c;
                result.incotermLocation = salesData.Incoterms_Location__c;
                result.currencyIsoCode = salesData.CurrencyIsoCode;
                return result;
            }
        }

        // Fallback to evaluatedSoldToParty
        List<Account_Sales_Data__c> oneTimeAccountSalesDataList = [
            SELECT Payment_Term__c, Incoterms__c, Incoterms_Location__c, CurrencyIsoCode, 
                   Sales_Org_Data__c, Distribution_Channel__c, Division__c
            FROM Account_Sales_Data__c
            WHERE Account__c = :evaluatedSoldToParty
        ];

        EvaluatedAccountInfo result = new EvaluatedAccountInfo();
        result.evaluatedSoldToParty = evaluatedSoldToParty;

        for (Account_Sales_Data__c salesData : oneTimeAccountSalesDataList) {
            if (salesData.Sales_Org_Data__c == orderType.Sales_Org__c &&
                salesData.Distribution_Channel__c == orderType.Distribution_Channel__c &&
                salesData.Division__c == orderType.Division__c) {

                result.incoterms = salesData.Incoterms__c;
                result.paymentTerm = salesData.Payment_Term__c;
                result.incotermLocation = salesData.Incoterms_Location__c;
                result.currencyIsoCode = salesData.CurrencyIsoCode;
                break;
            }
        }
        return result;

    } catch (Exception e) {
        throw new AuraHandledException('Error in getEvaluatedSoldToParty: ' + e.getMessage());
    }
}

/*************************************************************** 
====================================================== 
Purpose: method to insert the Order 
===================================================== 
History: 
AUTHOR     DATE          Reference       Description  
Vishal S   21/07/2025    INC. 159362    Determine the currency for non ZPLS sample order
Shyam C    16/09/2025    INC. 163626    Return Plant currency for non ZPLS sample order
***************************************************************/
@AuraEnabled
    public static String getNonS4OrderCurrency(String accountId, String plantId) {
        try {
            // Get Account Currency
            Account account = [
                SELECT Id, CurrencyIsoCode 
                FROM Account 
                WHERE Id = :accountId 
                LIMIT 1
            ];
            // Begin of INC. 163626- 16/09/2025 Shyam C
            // Get Order Type for Plant
            //List<Salesforce_Order_Type_Determination__c> orderTypes = [
            //    SELECT Sales_Org__c, Distribution_Channel__c, Division__c
            //    FROM Salesforce_Order_Type_Determination__c
            //    WHERE Plant_ID__c = :plantId AND Active__c = true
            //    LIMIT 1
            //];

            //Salesforce_Order_Type_Determination__c orderType = orderTypes[0];

            // Get Sales Data for Account
            //List<Account_Sales_Data__c> salesDataList = [
            //    SELECT CurrencyIsoCode, Sales_Org_Data__c, Distribution_Channel__c, Division__c
            //    FROM Account_Sales_Data__c 
            //    WHERE Account__c = :accountId AND 
            //        Sales_Org_Data__c = :orderType.Sales_Org__c AND 
            //        Distribution_Channel__c = :orderType.Distribution_Channel__c AND 
            //        Division__c = :orderType.Division__c  LIMIT 1];

            //if(!salesDataList.isEmpty()){
            //    return salesDataList[0].CurrencyIsoCode;
            //}
            //End of INC 163626- 16/09/2025 Shyam C

            //Begin of INC 163626+ 16/09/2025 Shyam C
            List<Plant__c> plants = [SELECT CurrencyIsoCode FROM Plant__c WHERE Id = :plantId LIMIT 1];
            if (!plants.isEmpty()) {
                return plants[0].CurrencyIsoCode;

            }
            //End of INC 163626+ 16/09/2025 Shyam C

            
            // If no matching Sales Data found, return Account Currency
            return account.CurrencyIsoCode;

        } catch (Exception e) {
            System.debug('Error in getNonS4OrderCurrency: ' + e.getMessage());
            throw new AuraHandledException('Error in getNonS4OrderCurrency: ' + e.getMessage());
        }
    }
 /*************************************************************** 
====================================================== 
Purpose: method to insert the Order 
===================================================== 
History: 
AUTHOR     DATE          Reference       Description  
Ankur O   29/09/2025   Community Portal   Method to determine Partner User Login
***************************************************************/   
    @AuraEnabled
    public static Boolean isPartnerUser() {
        return [SELECT Id, IsPartner FROM User WHERE Id = :UserInfo.getUserId()]
               .IsPartner;
    }
/*************************************************************** 
====================================================== 
Purpose: method to insert the Order 
===================================================== 
History: 
AUTHOR     DATE          Reference       Description  
Ankur O   29/09/2025   Community Portal   Method to get Partner User AccountId
***************************************************************/    
    @AuraEnabled
    public static Id partnerAccountId() {
        return [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].AccountId;
    }   
    
}