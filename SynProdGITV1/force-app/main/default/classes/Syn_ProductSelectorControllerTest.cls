/*************************************************************** 
====================================================== 
Purpose:  Test Class for Syn_ProductSelectorController
=================================================== 
History:  
AUTHOR     DATE 	    Reference 	     Description 
Vishal S  29/04/2025    SSP-353	    Initial Implementation	 
***************************************************************/
@isTest
public class Syn_ProductSelectorControllerTest {
    
    @testSetup
   public static void setupData(){
        
        //setup PriceBook
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = pricebookId,
            IsActive = true
        );
        update standardPricebook;
        
        // Create Unit of Measure
        UoM_Std_Data__c uom = new UoM_Std_Data__c(Name = 'Kilogram', UOM_Code__c = 'KGM', Internal_UoM_Code__c = 'KG' );
        insert uom;
        
        // Create Product Category
        Product_Category__c category = new Product_Category__c(Name = 'Chemicals', Product_Category_Id__c ='Test_PC_001', Level__c = '3 - Product', Hierarchy_Info__c = 'Dispersion polymer - PA_Pure Acrylic');
        insert category;
        
        // Create Product
        Product2 product = new Product2(Name = 'Test Product', Product_Id__c = 'Test_P001', Base_UoM__c = uom.Id , Product_Category__c = category.Id, StockKeepingUnit = 'KG');
        insert product;
        
        System.debug('pb: '+ standardPricebook); 
        PricebookEntry existingPbe;
        
        List<PricebookEntry> existingEntries = [
            SELECT Id, UnitPrice FROM PricebookEntry 
            WHERE Product2Id = :product.Id AND Pricebook2Id = :standardPricebook.Id  AND CurrencyIsoCode = 'GBP'
            LIMIT 1
        ];
        
        System.debug(existingEntries);
        
        if (existingEntries.isEmpty()) {
            // Add if not present
            existingPbe = new PricebookEntry(
                Product2Id = product.Id,
                Pricebook2Id = standardPricebook.Id,
                UnitPrice = 100,
                IsActive = true,
                CurrencyIsoCode = 'GBP'
            );
            insert existingPbe;
        } else {
            // Use existing
            existingPbe = existingEntries[0];
        }
        
        // Create Plant
        Plant__c plant = new Plant__c(Name = 'Plant A');
        insert plant;
        
        // Create Sample Master Matrix Data
        Sample_Master_Matrix_Data__c matrix = new Sample_Master_Matrix_Data__c(
            Product__c = product.Id,
            Product_Category_ID__c = category.Id,
            Unit__c = uom.Id,
            Region__c = 'ASIA',
            Plant_ID__c = plant.Id,
            Min__c = 10,
            Max__c = 100,
            Sampling_Status__c = '02 - Active',
            CurrencyIsoCode = 'GBP'            
        );
        insert matrix;
        
        // Create Stock Data
        Product_Stock_Data__c stock = new Product_Stock_Data__c(
            Product_ID__c = product.Id,
            Stock_level__c = 50,
            Stock_Threshold__c = 1000,
            Product_Stock_External_ID__c = 'Test_P001_ENORICA'
        );
        insert stock;
        
        // Add sales org data
        Sales_Org_Data__c salesOrg = new Sales_Org_Data__c(
            Sales_Org_Id__c = 'SOT1',
            Name =  'Test Org'
        );
        insert salesOrg;
        
        // Add Salesforce Order Type Determination
        Salesforce_Order_Type_Determination__c orderType = new Salesforce_Order_Type_Determination__c(
            Plant_ID__c = plant.Id,
            Salesforce_Order_Type__c = 'ZPLS',
            Sales_Org__c = salesOrg.Id,
            Distribution_Channel__c = '10',
            Division__c = '00',
            Shipping_Condition__c = '03',
            Delivery_Block__c = '02',
            Active__c = true
        );
        insert orderType;
        
        // Add Product Sales Data
        Product_Sales_Data__c salesData = new Product_Sales_Data__c(
            Product_ID__c = product.Id,
            Sales_Organization__c = salesOrg.Id,
            Distribution_Channel__c = '10',
            Item_Category_Group__c = 'NORM',
            Product_Sales_Ext_ID__c = 'Test_P001_SOT1_10'
        );
        insert salesData;
        
        // Add SAP S4 Order Type Determination
        SAP_S4_Order_Type_Determination__c s4OrderType = new SAP_S4_Order_Type_Determination__c(
            Salesforce_Order_Type__c = 'ZPLS',
            Item_Category_Group__c = 'NORM',
            S4_Order_Type__c = 'ZSAM',
            Item_Category__c = 'ZSAF',
            Active__c = true
        );
        insert s4OrderType;
        
        // Setup Account Data
        Account acc = new Account(Name = 'Test Account', BillingCountry='United Kingdom');
        insert acc;
        
        // Set up Order
        Order order = new Order(
            Name = 'Test Order',
            AccountId = acc.Id, // Dummy value for required field
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Shipping_Condition__c = '03',
            Delivery_Block__c = '02',
            Pricebook2Id = pricebookId
        );
        insert order;
        
        // set up OrderItem
        OrderItem orderItem = new OrderItem(
            OrderId = order.Id,
            Quantity = 5,
            Total_Price_Internal__c = 100,
            PricebookEntryId = existingPbe.Id,
            Product2Id = product.Id,
            Quantity_UoM__c = uom.Id,
            Estimated_Stock__c = 25,
            Salesforce_Order_Type__c = 'ZOR',
            S4_Order_Type__c = 'ZSAM',
            Sales_Organisation__c = salesOrg.Id,
            Distribution_Channel__c = '10',
            Division__c = '00',         
            S4_Item_Category__c = 'ZSAF',
            Sample_Master_Matrix_Data__c = matrix.Id
        );
        insert orderItem;
        
    }
    
    @isTest
    static void testSearchProducts_withAllParams() {
        Test.startTest();
        Syn_ProductSelectorController.SampleSearchResult results = Syn_ProductSelectorController.searchProducts(
            'Test', 'Chemicals', 'Kilogram', '10', 'ASIA', 1, 10
        );
        Test.stopTest();
        
        System.assertNotEquals(0, results.records.size(), 'Should return matching product');
        System.assertEquals(50, results.records[0].stockLevel, 'Stock level should match inserted data');
    }
    
    @isTest
    static void testSearchProducts_withNoRequiredQuantity() {
        Syn_ProductSelectorController.SampleSearchResult results = Syn_ProductSelectorController.searchProducts(
            'Test', null, null, null, null, 1, 10
        );
        System.assert(results.records.size() > 0, 'Should return at least one product without quantity filter');
    }
    
    @isTest
    static void testSearchCategories() {
        List<String> lstCategories = Syn_ProductSelectorController.searchCategories('Chem');
        System.assert(lstCategories.contains('Chemicals'), 'Should include matching category name');
    }
    
    @isTest
    static void testSearchProductName(){
        
        List<String> lstProducts = Syn_ProductSelectorController.searchProductNames('Test P');
         System.assert(lstProducts.contains('Test Product'), 'Should include matching category name');
    }
    
    @isTest
    static void testSearchUoM() {
        List<UoM_Std_Data__c> uoms = Syn_ProductSelectorController.searchUoM('Kilo');
        System.assertEquals(1, uoms.size(), 'Should return one matching UoM');
        System.assertEquals('Kilogram', uoms[0].Name, 'UoM name should match');
    }
    
    @isTest
    static void testGetPriceBookEntryId() {
        // Get the inserted Product2 from setup
        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Test Product' LIMIT 1];
        
        Test.startTest();
        PricebookEntry result = Syn_ProductSelectorController.getPriceBookEntryId(prod.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should return a PricebookEntry');
        System.assertEquals(prod.Id, result.Product2Id, 'Returned entry should belong to the test product');
    }
    
    @isTest
    static void testValidateTickedProducts_Success() {
        
        Product2 product = [SELECT Id FROM Product2 WHERE Name = 'Test Product' LIMIT 1];
        Plant__c plant = [SELECT Id FROM Plant__c WHERE Name = 'Plant A' LIMIT 1];
        UoM_Std_Data__c uom = [SELECT Id FROM UoM_Std_Data__c WHERE Name = 'Kilogram' LIMIT 1];
        
        Test.startTest();
        Syn_ProductSelectorController.selectedProductWrapper result = Syn_ProductSelectorController.validateTickedProducts(
            product.Id,
            plant.Id,
            uom.Id,
            null
        );
        Test.stopTest();
        
        // Assert
        System.assertEquals('ZPLS', result.salesforceOrderType, 'Salesforce Order Type should match');
        System.assertEquals('ZSAM', result.s4OrderType, 'S4 Order Type should match');
        
    }
    
    @isTest
    static void testValidateTickedProducts_mismatchShouldThrow() {
        Product2 product = [SELECT Id FROM Product2 WHERE Name = 'Test Product' LIMIT 1];
        Plant__c plant = [SELECT Id FROM Plant__c WHERE Name = 'Plant A' LIMIT 1];
        UoM_Std_Data__c uom = [SELECT Id FROM UoM_Std_Data__c WHERE Name = 'Kilogram' LIMIT 1];
        
        // Reuse previous inserts or query if needed
        Salesforce_Order_Type_Determination__c orderType = [SELECT Id, Salesforce_Order_Type__c, Sales_Org__c, Plant_ID__c, Distribution_Channel__c, Division__c, Shipping_Condition__c, Delivery_Block__c FROM Salesforce_Order_Type_Determination__c LIMIT 1];
        Product_Sales_Data__c salesData = [SELECT Id, Item_Category_Group__c FROM Product_Sales_Data__c LIMIT 1];
        SAP_S4_Order_Type_Determination__c s4OrderType = [SELECT Id, S4_Order_Type__c, Item_Category__c FROM SAP_S4_Order_Type_Determination__c LIMIT 1];
        
        // Create a wrapper with mismatching field
        Syn_ProductSelectorController.selectedProductWrapper oldWrapper = new Syn_ProductSelectorController.selectedProductWrapper(
            'DIFFERENT', // mismatching salesforceOrderType
            s4OrderType.S4_Order_Type__c,
            orderType.Shipping_Condition__c,
            orderType.Delivery_Block__c,
            plant.Id,
            orderType.Sales_Org__c,
            orderType.Distribution_Channel__c,
            orderType.Division__c,
            s4OrderType.Item_Category__c,
            'dummyId',
            'dummyPBId',
            'true'
        );
        
        String jsonWrapper = JSON.serialize(oldWrapper);
        Boolean exceptionThrown = false;
        
        System.debug(plant.Id+ ' plant Id: '+ orderType.Plant_ID__c);
        
        Test.startTest();
        try {
            Syn_ProductSelectorController.validateTickedProducts(product.Id, plant.Id, uom.Id, jsonWrapper);
            System.assert(false, 'Expected an AuraHandledException due to mismatch');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Expected an AuraHandledException');
        Test.stopTest();
    }
    
      @isTest
static void testGetOrderItemsFormOrder() {

    // get Product
    Product2 product = [SELECT Id, Name FROM Product2 WHERE Name = 'Test Product' LIMIT 1];
  
    // get Order
    Order order = [SELECT Id, Name FROM Order WHERE  Name = 'Test Order' LIMIT 1];
         
    Test.startTest();
    List<Map<String, Object>> result = Syn_ProductSelectorController.getOrderItemsFormOrder(order.Id);
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    System.assertEquals(1, result.size(), 'Should return one order item');
    System.assertEquals(product.Id, result[0].get('productId'), 'Product ID should match');
    System.assertEquals('ASIA', result[0].get('region'), 'Region should match matrix data');
}

    
}