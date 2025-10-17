/*************************************************************** 
====================================================== 
Purpose: 
===================================================== 
History: 
AUTHOR     DATE 	    Reference 	     Description 
Vishal S   28/04/2025    SSP-353	    Initial Implementation	
Vishal S   16/07/2025    INC.159398     Shipping Country is missing while Evaluating sold to Party
Vishal S   21/07/2025    INC.159362    Determine the currency for non ZPLS sample order
Shyam C    09/08/2025    INC 162773    Making is_Updated_From_Apex__c = True to bypass validations written in a flow.
Vishal S   22/09/2025	 INC.164768		Remove validation for ZBFD - S4 Order type 
Ankur O   29/10/2025     Community Portal  Added Methods to Determine Portal User and Account Region.
***************************************************************/ 
public without sharing class Syn_UpdateOrderProductsController{
    
    /*************************************************************** 
====================================================== 
Purpose: 
===================================================== 
History: 
AUTHOR     DATE 	    Reference 	     Description 
Vishal S   28/04/2025    SSP-353	    Initial Implementation
Shyam C    09/08/2025    INC 162773+    Making is_Updated_From_Apex__c = True to bypass validations written in a flow.
***************************************************************/ 
    @AuraEnabled
    public static boolean updateOrderProducts(List<Map<String, Object>> orderProduct, Id orderId) {
        
        
        // Retrieve existing OrderItems for the given OrderId
        Map<String, OrderItem> existingItemsMap = new Map<String, OrderItem>();
        List<OrderItem> existingItems = new List<OrderItem>();
        for (OrderItem oi : [SELECT Id, Sample_Master_Matrix_Data__c, Default_Product_Used__c, Quantity, Total_Price_Internal__c, OrderId FROM OrderItem WHERE OrderId = :orderId]) {
            existingItemsMap.put(oi.Sample_Master_Matrix_Data__c, oi);
            existingItems.add(oi);
        }
        // Get Order details
        Order order = [SELECT Id, Pricebook2Id, CurrencyIsoCode FROM Order WHERE Id = : orderId LIMIT 1];
        
        // These are common for all products
        Id pricebook2Id = order.Pricebook2Id;
        String currencyIsoCode = order.CurrencyIsoCode;
        
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
        
        
        // Prepare lists for DML operations
        List<OrderItem> itemsToInsert = new List<OrderItem>();
        List<OrderItem> itemsToUpdate = new List<OrderItem>();
        List<OrderItem> itemsToDelete = new List<OrderItem>();
        
        // Process each item in the incoming orderProduct list
        for (Map<String, Object> item : orderProduct) {
            String itemId = (String)item.get('Id');
            OrderItem existingItem = existingItemsMap.get(itemId);
            System.debug('item '+  (Decimal)item.get('unitPrice'));
            // Create or update OrderItem
            //OrderItem orderItem = existingItem != null ? existingItem : new OrderItem();
            
           Id productId = (Id)item.get('productId');
        	Id pricebookEntryId = productToPbeIdMap.get(productId);
            
            OrderItem orderItem = new OrderItem();
            
            if(existingItem == null){
                
                orderItem.OrderId = orderId;
                orderItem.Sample_Master_Matrix_Data__c = itemId;
                orderItem.Product2Id = productId;
                //orderItem.PricebookEntryId = (String)item.get('pricebookEntryId');
                orderItem.PricebookEntryId = pricebookEntryId;
                orderItem.Quantity = (Decimal)item.get('quantity');
                //orderItem.UnitPrice = (Decimal)item.get('unitPrice');
                orderItem.Total_Price_Internal__c = (Decimal)item.get('totalPrice');
                orderItem.Description = (String)item.get('description');
                orderItem.Plant__c = (String)item.get('plantId');
                orderItem.Salesforce_Order_Type__c = (String)item.get('SalesforceOrderType');
                orderItem.S4_Order_Type__c = (String)item.get('s4OrderType');
                orderItem.S4_Item_Category__c = (String)item.get('itemCategory');
                orderItem.Sales_Organisation__c = (String)item.get('salesOrg');
                orderItem.Distribution_Channel__c = (String)item.get('distributionChannel');
                orderItem.Division__c = (String)item.get('division');
                orderItem.Quantity_UoM__c = (String)item.get('uomId');
                orderItem.Default_Product_Used__c = (Boolean)item.get('isDefaultProduct');
                if ( item.get('stockLevel') != null) {
                    orderItem.Estimated_Stock__c = Decimal.valueOf(String.valueOf(item.get('stockLevel')));
                } else {
                    orderItem.Estimated_Stock__c = null; // Or set to 0 if that's preferred
                }
                if (item.containsKey('shippingDate')) {
                    orderItem.Shipping_Date__c = (Date)item.get('shippingDate');
                }
                
                
                itemsToInsert.add(orderItem);
            } else {
                
                if (existingItem != null) {
                Decimal newQty = (Decimal)item.get('quantity');
                Decimal oldQty = existingItem.Quantity;

                Boolean isDefault = existingItem.Default_Product_Used__c;
                Boolean isQtyChanged = oldQty != newQty;

                if (isQtyChanged) {
                    orderItem.Id = existingItem.Id;
                    orderItem.Quantity = newQty;
                    orderItem.Total_Price_Internal__c = (Decimal)item.get('totalPrice');
                    
                    orderItem.Is_Updated_From_Apex__c = True;  //INC 162773+ Shyam C - Turning Flag up to bypass validations in a flow.
                    
                    itemsToUpdate.add(orderItem);
                } else if(isDefault){
                    orderItem.Id = existingItem.Id;
                    orderItem.Description = (String)item.get('description');
                    
                    orderItem.Is_Updated_From_Apex__c = True;  //INC 162773+ Shyam C - Turning Flag up to bypass validations in a flow.
                    
                    itemsToUpdate.add(orderItem);
                }
            }
                
            }
            
            // Remove the processed item from the map
            existingItemsMap.remove(itemId);
        }
        
        // Identify OrderItems to delete (those not in the incoming list)
        for (OrderItem obsoleteItem : existingItemsMap.values()) {
            itemsToDelete.add(obsoleteItem);
        }
        
        System.debug(itemsToInsert);
        System.debug(itemsToUpdate);
        System.debug(itemsToDelete);
        
        // Perform DML operations
        try {
            if (!itemsToDelete.isEmpty()) {
                delete itemsToDelete;
            }
            if (!itemsToInsert.isEmpty()) {

                String newCurrencyIsoCode = currencyIsoCode;
                
                if(!itemsToDelete.isEmpty() || existingItems.isEmpty()){
                    if(checkItemToDeleteWithExistingItems(existingItems, itemsToDelete )){

                        newCurrencyIsoCode = updateOrderHeader(itemsToInsert, orderProduct);
                        
                    }
                }

                if(newCurrencyIsoCode!= currencyIsoCode)
                {
                    // Query all needed PricebookEntries
                    Map<Id, Id> newProductToPbeIdMap = new Map<Id, Id>();
                    List<PricebookEntry> newPbeList = [
                        SELECT Id, Product2Id
                        FROM PricebookEntry
                        WHERE Pricebook2Id = :pricebook2Id
                        AND CurrencyIsoCode = :newCurrencyIsoCode
                        AND Product2Id IN :productIds
                    ];
                    
                    for (PricebookEntry pbe : newPbeList) {
                        newProductToPbeIdMap.put(pbe.Product2Id, pbe.Id);
                    }

                    for(OrderItem orderItem : itemsToInsert){
                        Id pbeId = newProductToPbeIdMap.get(orderItem.Product2Id);
                        orderItem.PricebookEntryId = pbeId;
                    }
                }

                insert itemsToInsert;
            }
            if (!itemsToUpdate.isEmpty()) {

                update itemsToUpdate;
            }


            
        } catch (DmlException e) {
            System.debug(e.getMessage());
            throw new AuraHandledException('Error updating Order Line Items: ' + e.getMessage());
        }

        if(itemsToInsert.isEmpty() && itemsToUpdate.isEmpty() && itemsToDelete.isEmpty()){
            return false;
        }
            else{
                return true;
            }
    }
    
    /*************************************************************** 
====================================================== 
Purpose: 
===================================================== 
History: 
AUTHOR     DATE 	    Reference 	     Description 
Vishal S   28/04/2025    SSP-353	    Initial Implementation	 
***************************************************************/ 
    
    
    public static boolean checkItemToDeleteWithExistingItems(List<OrderItem> existingItems, List<OrderItem> itemsToDelete){
        
        List<Id> existingItemSampleMatrixIds = new List<Id>();
        List<Id> itemsToDeleteSampleMatrixIds = new List<Id>();
        
        for (OrderItem oi : existingItems) {
            if (oi.Sample_Master_Matrix_Data__c != null) {
                existingItemSampleMatrixIds.add(oi.Sample_Master_Matrix_Data__c);
            }
        }
        
        for(OrderItem oi: itemsToDelete){
            if (oi.Sample_Master_Matrix_Data__c != null) {
                itemsToDeleteSampleMatrixIds.add(oi.Sample_Master_Matrix_Data__c);
            }
        }
        
        if (existingItemSampleMatrixIds.equals(itemsToDeleteSampleMatrixIds)) {
            System.debug('all to delete');
            return true;
        }
        return false;
        
    }
    
    /*************************************************************** 
====================================================== 
Purpose: 
===================================================== 
History: 
AUTHOR     DATE 	    Reference 	     Description 
Vishal S   28/04/2025    SSP-353	    Initial Implementation
Vishal S   16/07/2025    INC.159398     Shipping Country is missing while Evaluating sold to Party
Vishal S   21/07/2025    INC.159362    Determine the currency for non ZPLS sample order
Vishal S   22/09/2025	 INC.164768		Remove validation for ZBFD - S4 Order type  
***************************************************************/ 
    
    
   public static String updateOrderHeader(List<OrderItem> itemsToInsert, List<Map<String, Object>> orderProduct) {
    if (itemsToInsert == null || itemsToInsert.isEmpty() || orderProduct == null || orderProduct.isEmpty()) {
        throw new AuraHandledException('Order data is incomplete.');
    }

    Id orderId = itemsToInsert[0].OrderId;
    Order orderToUpdate = [SELECT Id, Plant__c, Sales_Organisation__c, Salesforce_Order_Type__c, S4_Order_Type__c, 
        Distribution_Channel__c, Division__c, Shipping_Condition__c, Delivery_Block__c, AccountId, ShippingCountry,
        IncoTerms__c, IncoTerms_Location__c, CurrencyIsoCode, Payment_Terms__c, Evaluated_Sold_To_Party__c,  
        Ship_To_Account__r.CurrencyIsoCode, Account.CurrencyIsoCode, Ship_To_Account__c,
        //changes start for INC.159398 16-07-2025
        Account.BillingCountry, Account.ShippingCountry, 
        Ship_To_Account__r.ShippingCountry, Ship_To_Account__r.BillingCountry
        //changes end for INC.159398 16-07-2025
        FROM Order 
        WHERE Id = :orderId LIMIT 1];

    // Basic field mapping
    orderToUpdate.Plant__c = itemsToInsert[0].Plant__c;
    orderToUpdate.Sales_Organisation__c = itemsToInsert[0].Sales_Organisation__c;
    orderToUpdate.Salesforce_Order_Type__c = itemsToInsert[0].Salesforce_Order_Type__c;
    orderToUpdate.S4_Order_Type__c = itemsToInsert[0].S4_Order_Type__c;
    orderToUpdate.Distribution_Channel__c = itemsToInsert[0].Distribution_Channel__c;
    orderToUpdate.Division__c = itemsToInsert[0].Division__c;
    orderToUpdate.Shipping_Condition__c = (String)orderProduct[0].get('shippingCondition');
    orderToUpdate.Delivery_Block__c = (String)orderProduct[0].get('deliveryBlock');

    // ZPLS-specific logic
    if (orderToUpdate.Salesforce_Order_Type__c == 'ZPLS') {
        //changes start for INC.159398 16-07-2025
        String orderShippingCountry;

        if (orderToUpdate.Ship_To_Account__c != null) {
            orderShippingCountry = (orderToUpdate.Ship_To_Account__r.ShippingCountry != null) 
                ? orderToUpdate.Ship_To_Account__r.ShippingCountry 
                : orderToUpdate.Ship_To_Account__r.BillingCountry;
        } else {
            orderShippingCountry = (orderToUpdate.Account.ShippingCountry != null)
                ? orderToUpdate.Account.ShippingCountry
                : orderToUpdate.Account.BillingCountry;
        }

        Syn_CreateOrderController.EvaluatedAccountInfo info = Syn_CreateOrderController.getEvaluatedSoldToParty(
            orderToUpdate.AccountId, orderToUpdate.Plant__c, orderShippingCountry
        ); 
        // changes end for INC.159398 16-07-2025
        // Begin of for INC. 164768 - 22/09/2025 - Vishal S 
       //if (info.evaluatedSoldToParty != orderToUpdate.AccountId && orderToUpdate.S4_Order_Type__c == 'ZBFD') {
       //    throw new AuraHandledException('Sample Product cannot be selected for the selected Account. Please ask the CSR team to create the Sample order directly in S4.');
       // }
        //End of for INC. 164768 - 22/09/2025 - Vishal S 

        orderToUpdate.IncoTerms__c = info.incoTerms;
        orderToUpdate.IncoTerms_Location__c = info.incotermLocation;
        orderToUpdate.Payment_Terms__c = info.paymentTerm;
        orderToUpdate.Evaluated_Sold_To_Party__c = info.evaluatedSoldToParty;
        orderToUpdate.CurrencyIsoCode = info.currencyIsoCode;
    } else {
         orderToUpdate.IncoTerms__c = '';
         orderToUpdate.IncoTerms_Location__c = '';
         orderToUpdate.Payment_Terms__c = null;
         orderToUpdate.Evaluated_Sold_To_Party__c = null;
        //Begin of for INC. 159362- 21/07/2025 - Vishal S 
        // 
        // orderToUpdate.CurrencyIsoCode = (orderToUpdate.Ship_To_Account__r.CurrencyIsoCode != null)
        //     ? orderToUpdate.Ship_To_Account__r.CurrencyIsoCode
        //     : orderToUpdate.Account.CurrencyIsoCode;
       // Ends of INC. 159362- 21/07/2025 - Vishal S

       //Begin of INC. 159362+ 21/07/2025 - Vishal S
        String orderCurrency = Syn_CreateOrderController.getNonS4OrderCurrency(orderToUpdate.AccountId, orderToUpdate.Plant__c);
		System.debug(orderToUpdate.Plant__c + ' ' + orderCurrency);
        orderToUpdate.CurrencyIsoCode = orderCurrency;
        // Ends of INC. 159362+ 21/07/2025 - Vishal S
    }

    update orderToUpdate;
    return orderToUpdate.CurrencyIsoCode;
}
/*************************************************************** 
====================================================== 
Purpose: 
===================================================== 
History: 
AUTHOR     DATE 	    Reference 	     Description 
Ankur O   29/09/2025    Community Portal Method to determine Partner User Login	 
***************************************************************/  
    @AuraEnabled
    public static Boolean isPartnerUser() {
        return [SELECT Id, IsPartner FROM User WHERE Id = :UserInfo.getUserId()]
               .IsPartner;
    }
/*************************************************************** 
====================================================== 
Purpose: 
===================================================== 
History: 
AUTHOR     DATE 	    Reference 	     Description 
Ankur O   29/09/2025    Community Portal Method to determine Account Region	 	 
***************************************************************/     
    @AuraEnabled
    public static String getAccountRegion() {
        Id accId=  [SELECT Id, AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].AccountId;
        List<Account> lstAccount = [SELECT Id,Region__c FROM Account WHERE Id = : accId];
        Account objAccount = lstAccount[0];
        return objAccount.Region__c;
        
        
    }   

       
}