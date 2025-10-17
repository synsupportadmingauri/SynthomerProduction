/*************************************************************** 
// ====================================================== 
// Purpose: Test class for Syn_UpdateOrderProductsController 
// ===================================================== 
// History: 
// AUTHOR     DATE         Reference        Description 
// Vishal S   29/04/2025                    Initial Implementation    
// Vishal S   24/06/2025                    Combined test data setup
// Vishal S   21/07/2025    INC. 159362    Determine the currency for non ZPLS sample order
// Shyam C	  16/09/2025    INC 163626     Add CurrencyIsoCode to Plant A
// Jalindar G 30/09/2025	SD1-T17		   Added method to cover isPartnerUser method
// *********************** ****************************************/ 
@isTest
public class Syn_UpdateOrderProductsControllerTest {  

    @testSetup
    static void setupTestData() {
        // Create Accounts
        Account acc = new Account(
            Name = 'Test Account', 
            BillingStreet = '123 Main St', 
            BillingCity = 'Pune', 
            BillingState = 'Maharashtra', 
            BillingStateCode = 'MH',
            BillingCountryCode = 'IN',
            BillingPostalCode = '412109', 
            BillingCountry = 'India', 
            ShippingStreet = '123 Mg Road', 
            ShippingCity = 'Surat', 
            ShippingState = 'Gujarat', 
            ShippingCountry = 'India',
            ShippingStateCode = 'GJ',
            ShippingCountryCode = 'IN',
            ShippingPostalCode = '412009',
            Type = 'Prospect', 
            CurrencyIsoCode = 'GBP'
        );
        Account shipToAcc = new Account(
            Name = 'Ship To Account', 
            CurrencyIsoCode = 'EUR', 
            BillingCountry = 'United Kingdom'
        );
        Account domesticAcc = new Account(
            Name = 'One Time Account - International', 
            BillingCountry = 'United Kingdom',
            CurrencyIsoCode = 'USD'
        );
        Account internationalAcc = new Account(
            Name = 'One Time Customer Domestic', 
            BillingCountry = 'India',
            CurrencyIsoCode = 'USD'
        );
        Account customerAcct = new Account(
            Name = 'Test Customer Account', 
            BillingCountry = 'United Kingdom'
        );
        insert new List<Account>{acc, shipToAcc, domesticAcc, internationalAcc, customerAcct};

        // Setup Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = pricebookId,
            IsActive = true
        );
        update standardPricebook;

        // Create Products
        Product2 prod1 = new Product2(
            Name = 'Test Product1', 
            IsActive = true, 
            Product_Id__c = 'PRD_test001'
        );
        Product2 prod2 = new Product2(
            Name = 'Test Product2', 
            IsActive = true, 
            Product_Id__c = 'PRD_test002'
        );
        insert new List<Product2>{prod1, prod2};

        // Create Pricebook Entries
        PricebookEntry pbe1;
        PricebookEntry pbe2;
        List<PricebookEntry> existingEntries1 = [
            SELECT Id, UnitPrice 
            FROM PricebookEntry 
            WHERE Product2Id = :prod1.Id AND Pricebook2Id = :standardPricebook.Id AND CurrencyIsoCode = 'GBP'
            LIMIT 1
        ];
        List<PricebookEntry> existingEntries2 = [
            SELECT Id, UnitPrice 
            FROM PricebookEntry 
            WHERE Product2Id = :prod2.Id AND Pricebook2Id = :standardPricebook.Id AND CurrencyIsoCode = 'GBP'
            LIMIT 1
        ];
        
        if (existingEntries1.isEmpty()) {
            pbe1 = new PricebookEntry(
                Product2Id = prod1.Id,
                Pricebook2Id = standardPricebook.Id,
                UnitPrice = 100,
                IsActive = true,
                CurrencyIsoCode = 'GBP'
            );
            insert pbe1;
        } else {
            existingEntries1[0].UnitPrice = 90;
            update existingEntries1;
            pbe1 = existingEntries1[0];
        }
        if (existingEntries2.isEmpty()) {
            pbe2 = new PricebookEntry(
                Product2Id = prod2.Id,
                Pricebook2Id = standardPricebook.Id,
                UnitPrice = 100,
                IsActive = true,
                CurrencyIsoCode = 'GBP'
            );
            insert pbe2;
        } else {
            existingEntries2[0].UnitPrice = 90;
            update existingEntries2;
            pbe2 = existingEntries2[0];
        }
        

        // Create Unit of Measure
        UoM_Std_Data__c uom = new UoM_Std_Data__c(
            Name = 'Kilogram', 
            UOM_Code__c = 'KGM', 
            Internal_UoM_Code__c = 'KG'
        );
        insert uom;

        // Create Product Category
        Product_Category__c category = new Product_Category__c(
            Name = 'Chemicals', 
            Product_Category_Id__c = 'Test_PC_001', 
            Level__c = '3 - Product', 
            Hierarchy_Info__c = 'Dispersion polymer - PA_Pure Acrylic'
        );
        insert category;

        // Create Plant
        Plant__c plant = new Plant__c(
            Name = 'Plant A', 
            Address__CountryCode__s = 'US',
            
            CurrencyISOCode ='GBP' //INC 163626+ 16/09/2025 Shyam C
        );
        insert plant;
			
        // Create Order
        Order ord = new Order(
            Name = 'Test Order',
            Status = 'Draft',
            EffectiveDate = Date.today(),
            AccountId = acc.Id,
            Pricebook2Id = standardPricebook.Id,
            Shipping_Condition__c = '03',
            Delivery_Block__c = '02',
            CurrencyIsoCode = 'GBP',
            ShippingCountry = 'United States'
        );
        insert ord;

        // Create Order Item
        OrderItem oi = new OrderItem(
            OrderId = ord.Id,
            Product2Id = prod1.Id,
            Quantity = 10,
            Total_Price_Internal__c = 10,
            PricebookEntryId = pbe1.Id,
            Plant__c = plant.Id,
            Salesforce_Order_Type__c = 'ZPLS',
            Is_Updated_From_Apex__c = False
        );
        insert oi;

        // Create Sample Master Matrix Data
        Sample_Master_Matrix_Data__c matrix = new Sample_Master_Matrix_Data__c(
            Product__c = prod1.Id,
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

        // Create Sales Org Data
        Sales_Org_Data__c salesOrg = new Sales_Org_Data__c(
            Sales_Org_Id__c = 'SOT1',
            Name = 'Test Org'
        );
        insert salesOrg;

        // Create Payment Term
        Payment_Terms__c paymentTerm = new Payment_Terms__c(
            Name = 'AD10',
            Description__c = '10% Advance Payment',
            Active_Flag__c = true
        );
        insert paymentTerm;

        // Create Account Sales Data
        Account_Sales_Data__c salesData = new Account_Sales_Data__c(
            Account__c = customerAcct.Id,
            Sales_Org_Data__c = salesOrg.Id,
            Distribution_Channel__c = '10',
            Division__c = '00',
            Account_Sales_External_ID__c = 'SOT1_10_00_01',
            Payment_Term__c = paymentTerm.Id,
            Incoterms__c = 'CFR',
            IncoTerms_Location__c = 'US'
        );
        Account_Sales_Data__c salesData1 = new Account_Sales_Data__c(
            Account__c = domesticAcc.Id,
            Sales_Org_Data__c = salesOrg.Id,
            Distribution_Channel__c = '10',
            Division__c = '00',
            Account_Sales_External_ID__c = 'SOT1_10_00_02',
            Payment_Term__c = paymentTerm.Id,
            Incoterms__c = 'CFR',
            IncoTerms_Location__c = 'US',
            CurrencyIsoCode = 'USD'
        );
        Account_Sales_Data__c salesData2 = new Account_Sales_Data__c(
            Account__c = internationalAcc.Id,
            Sales_Org_Data__c = salesOrg.Id,
            Distribution_Channel__c = '10',
            Division__c = '00',
            Account_Sales_External_ID__c = 'SOT1_10_00',
            Payment_Term__c = paymentTerm.Id,
            Incoterms__c = 'CFR',
            IncoTerms_Location__c = 'US',
            CurrencyIsoCode = 'USD'
        );
        
         Account_Sales_Data__c salesData3 = new Account_Sales_Data__c(
            Account__c = acc.Id,
            Sales_Org_Data__c = salesOrg.Id,
            Distribution_Channel__c = '10',
            Division__c = '00',
            Account_Sales_External_ID__c = 'SOT1_10_00_03',
            Payment_Term__c = paymentTerm.Id,
            Incoterms__c = 'CFR',
            IncoTerms_Location__c = 'US',
            CurrencyIsoCode = 'GBP'
        );
        insert new List<Account_Sales_Data__c>{salesData, salesData1, salesData2, salesData3};

        // Create Order Type Determination
        Salesforce_Order_Type_Determination__c orderType = new Salesforce_Order_Type_Determination__c(
            Plant_ID__c = plant.Id,
            Active__c = true,
            Sales_Org__c = salesOrg.Id,
            Distribution_Channel__c = '10',
            Division__c = '00',
            One_Time_Customer_ID_Domestic__c = domesticAcc.Id,
            One_Time_Customer_ID_International__c = internationalAcc.Id
        );
        insert orderType;
    }
    
    @isTest
    static void testUpdateOrderProducts_InsertScenario() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        Order ord = [SELECT Id FROM Order WHERE Name = 'Test Order'];
        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Test Product1'];
        PricebookEntry pbe = [SELECT Id, Pricebook2Id FROM PricebookEntry WHERE Product2Id = :prod.Id AND CurrencyIsoCode = 'GBP' LIMIT 1];
        Sample_Master_Matrix_Data__c matrix = [SELECT Id, Plant_ID__c FROM Sample_Master_Matrix_Data__c WHERE Product__c = :prod.Id];
		
        
        Map<String, Object> productMap = new Map<String, Object>{
            'Id' => matrix.Id,
            'productId' => prod.Id,
            'pricebookEntryId' => pbe.Id,
            'quantity' => 5,
            'totalPrice' => 0,
            'description' => 'Test Description',
            'plantId' => matrix.Plant_Id__c,
            'SalesforceOrderType' => 'ZPLS',
            's4OrderType' => 'ZSAM',
            'itemCategory' => 'ZSAF',
            'salesOrg' => null,
            'distributionChannel' => '10',
            'division' => '00',
            'uomId' => null,
            'stockLevel' => 15,
            'shippingDate' => Date.today().addDays(5),
            'isDefaultProduct' => false
        };
        Map<String, Object> productMap2 = new Map<String, Object>{
            'Id' => null,
            'productId' => prod.Id,
            'pricebookEntryId' => pbe.Id,
            'quantity' => 15,
            'totalPrice' => 0,
            'description' => 'Test Description 2',
            'plantId' => matrix.Plant_Id__c,
            'SalesforceOrderType' => 'ZPLS',
            's4OrderType' => 'ZSAM',
            'itemCategory' => 'ZSAF',
            'salesOrg' => null,
            'distributionChannel' => '10',
            'division' => '00',
            'uomId' => null,
            'stockLevel' => 20,
            'shippingDate' => Date.today().addDays(6),
            'isDefaultProduct' => true
        };
        List<Map<String, Object>> inputList = new List<Map<String, Object>>{productMap, productMap2};
        
        Test.startTest();
        Syn_UpdateOrderProductsController.updateOrderProducts(inputList, ord.Id);
        Test.stopTest();
        
        List<OrderItem> orderItems = [
            SELECT Id, Product2Id, Quantity, UnitPrice, OrderId, Sample_Master_Matrix_Data__c
            FROM OrderItem WHERE OrderId = :ord.Id AND Sample_Master_Matrix_Data__c = :matrix.Id
        ];
        
        System.assertEquals(1, orderItems.size(), 'One OrderItem should have been created');
        System.assertEquals(prod.Id, orderItems[0].Product2Id, 'Product should match');
        System.assertEquals(5, orderItems[0].Quantity, 'Quantity should be 5');
        System.assertEquals(0, orderItems[0].UnitPrice, 'Unit price should be 0');
    }
    
    @isTest
    static void testUpdateOrderProducts_DeleteExistingInsertNew() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        Order ord = [SELECT Id FROM Order WHERE Name = 'Test Order'];
        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Test Product1'];
        PricebookEntry pbe = [SELECT Id, Pricebook2Id FROM PricebookEntry WHERE Product2Id = :prod.Id AND CurrencyIsoCode = 'GBP' LIMIT 1];
        Sample_Master_Matrix_Data__c matrix = [SELECT Id, Plant_ID__c FROM Sample_Master_Matrix_Data__c WHERE Product__c = :prod.Id];
		
        OrderItem lstOrderItems = [SELECT ID FROM OrderItem WHERE OrderId =: ord.Id];
        delete lstOrderItems;
        
        Map<String, Object> productMap = new Map<String, Object>{
            'Id' => matrix.Id,
            'productId' => prod.Id,
            'pricebookEntryId' => pbe.Id,
            'quantity' => 5,
            'totalPrice' => 0,
            'description' => 'Test Description',
            'plantId' => matrix.Plant_Id__c,
            'SalesforceOrderType' => 'ZPLS',
            's4OrderType' => 'ZSAM',
            'itemCategory' => 'ZSAF',
            'salesOrg' => null,
            'distributionChannel' => '10',
            'division' => '00',
            'uomId' => null,
            'stockLevel' => 15,
            'shippingDate' => Date.today().addDays(5),
            'isDefaultProduct' => false
        };

        List<Map<String, Object>> inputList = new List<Map<String, Object>>{productMap};
        
        Test.startTest();
        Syn_UpdateOrderProductsController.updateOrderProducts(inputList, ord.Id);
        Test.stopTest();
        
        List<OrderItem> orderItems = [
            SELECT Id, Product2Id, Quantity, UnitPrice, OrderId, Sample_Master_Matrix_Data__c
            FROM OrderItem WHERE OrderId = :ord.Id AND Sample_Master_Matrix_Data__c = :matrix.Id
        ];
        
        System.assertEquals(1, orderItems.size(), 'One OrderItem should have been created');
        System.assertEquals(prod.Id, orderItems[0].Product2Id, 'Product should match');
        System.assertEquals(5, orderItems[0].Quantity, 'Quantity should be 5');
        System.assertEquals(0, orderItems[0].UnitPrice, 'Unit price should be 0');
    }
    
    
    
    @isTest
    static void testUpdateOrderProducts_DeleteScenario() {
        Order ord = [SELECT Id FROM Order WHERE Name = 'Test Order'];
        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Test Product1'];
        OrderItem oi = [SELECT Id FROM OrderItem WHERE OrderId = :ord.Id AND Product2Id = :prod.Id];
        List<Map<String, Object>> inputList = new List<Map<String, Object>>();
        
        Test.startTest();
        System.debug('Calling method...');
        Syn_UpdateOrderProductsController.updateOrderProducts(inputList, ord.Id);
        System.debug('Method executed successfully');
        Test.stopTest();
        
        List<OrderItem> remainingItems = [SELECT Id FROM OrderItem WHERE OrderId = :ord.Id];
        System.assertEquals(0, remainingItems.size(), 'OrderItem should have been deleted');
    }
    
    @isTest
    static void test_checkItemToDeleteWithExistingItems_logic() {
        Order ord = [SELECT Id FROM Order WHERE Name = 'Test Order'];
        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Test Product1'];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod.Id AND CurrencyIsoCode = 'GBP' LIMIT 1];
        Sample_Master_Matrix_Data__c sampleMatrixData = [SELECT Id FROM Sample_Master_Matrix_Data__c WHERE Product__c = :prod.Id];

        OrderItem existingItem = new OrderItem(
            OrderId = ord.Id,
            Quantity = 1,
            UnitPrice = 50,
            Total_Price_Internal__c = 50,
            PricebookEntryId = pbe.Id,
            Sample_Master_Matrix_Data__c = sampleMatrixData.Id
        );
        OrderItem toDeleteItem = new OrderItem(
            OrderId = ord.Id,
            Quantity = 1,
            UnitPrice = 50,
            Total_Price_Internal__c = 50,
            PricebookEntryId = pbe.Id,
            Sample_Master_Matrix_Data__c = sampleMatrixData.Id
        );
        insert new List<OrderItem>{existingItem, toDeleteItem};

        List<OrderItem> existingList = new List<OrderItem>{existingItem};
        List<OrderItem> deleteList = new List<OrderItem>{toDeleteItem};

        Boolean result = Syn_UpdateOrderProductsController.checkItemToDeleteWithExistingItems(existingList, deleteList);
        System.assertEquals(true, result, 'Should return true when Sample_Master_Matrix_Data__c matches');

        toDeleteItem.Sample_Master_Matrix_Data__c = UserInfo.getUserId();
        result = Syn_UpdateOrderProductsController.checkItemToDeleteWithExistingItems(existingList, new List<OrderItem>{toDeleteItem});
        System.assertEquals(false, result, 'Should return false for different Sample_Master_Matrix_Data__c');
    }

    @isTest
    static void testUpdateOrderHeader_ZPLS_Type() {
        Order ord = [SELECT Id FROM Order WHERE Name = 'Test Order'];
        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Test Product2'];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod.Id AND CurrencyIsoCode = 'GBP' LIMIT 1];
        Plant__c plant = [SELECT Id FROM Plant__c WHERE Name = 'Plant A'];

        OrderItem oi = new OrderItem(
            OrderId = ord.Id,
            Quantity = 1,
            UnitPrice = 10,
            PricebookEntryId = pbe.Id,
             Total_Price_Internal__c = 10,
            Plant__c = plant.Id,
            Salesforce_Order_Type__c = 'ZPLS'
        );
        //insert oi;
        
        List<OrderItem> lstOrderItems = [SELECT ID FROM OrderItem WHERE OrderId =: ord.Id];
        
        delete lstOrderItems; 
        

        List<OrderItem> itemsToInsert = new List<OrderItem>{oi};
        Map<String, Object> productMap = new Map<String, Object>{
            'shippingCondition' => '02',
            'deliveryBlock' => '01'
        };
        List<Map<String, Object>> orderProduct = new List<Map<String, Object>>{productMap};

        Test.startTest();
        String currencyCode = Syn_UpdateOrderProductsController.updateOrderHeader(itemsToInsert, orderProduct);
        Test.stopTest();

        System.assertEquals('USD', currencyCode, 'Currency code should match evaluated party currency');
    }
    
     @isTest
    static void testUpdateOrderHeader_ZSLS_Type() {
        Order ord = [SELECT Id FROM Order WHERE Name = 'Test Order'];
        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Test Product2'];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod.Id AND CurrencyIsoCode = 'GBP' LIMIT 1];
        Plant__c plant = [SELECT Id FROM Plant__c WHERE Name = 'Plant A'];

        OrderItem oi = new OrderItem(
            OrderId = ord.Id,
            Quantity = 1,
            UnitPrice = 10,
            PricebookEntryId = pbe.Id,
             Total_Price_Internal__c = 10,
            Plant__c = plant.Id,
            Salesforce_Order_Type__c = 'ZSLS'
        );
        //insert oi;

        List<OrderItem> itemsToInsert = new List<OrderItem>{oi};
        Map<String, Object> productMap = new Map<String, Object>{
            'shippingCondition' => '02',
            'deliveryBlock' => '01'
        };
        List<Map<String, Object>> orderProduct = new List<Map<String, Object>>{productMap};

        Test.startTest();
        String currencyCode = Syn_UpdateOrderProductsController.updateOrderHeader(itemsToInsert, orderProduct);
        Test.stopTest();

        System.assertEquals('GBP', currencyCode, 'Currency code should match evaluated party currency');
    }
    
/*************************************************************** 
====================================================== 
Purpose: Test method to cover isPartnerUser method.
===================================================== 
History:  
AUTHOR      DATE         Reference        Description 
Jalindar G  30/09/2025	 SD1-T17		  Test method to cover isPartnerUser method
***************************************************************/
    @isTest
    static void testPartnerUserNotNull() {
        // Step 1: Create an Account (Partner or Prospect)
        Account objAccount = new Account(
            Name = 'Test Account',
            Type = 'Prospect',
            BillingStreet = '123 Test St',
            BillingCity = 'Mumbai',
            BillingPostalCode = '400001',
            BillingCountry = 'India'
        );
        insert objAccount;
        
        // Step 2: Create a Contact for the Account
        Contact objContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = objAccount.Id
        );
        insert objContact;
        
        // Step 3: Create a normal User (cannot set AccountId or IsPartner in Apex)
        Profile objProfile = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User objUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            Email = 'testuser' + System.currentTimeMillis() + '@test.com',
            Username = 'testuser' + System.currentTimeMillis() + '@test.com',
            CommunityNickname = 'testuser' + System.currentTimeMillis(),
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = objProfile.Id
           
        );
        insert objUser;
        
        // Step 4: Run as the test user
        System.runAs(objUser) {
            // Test isPartnerUser
            Boolean blnPartner = Syn_UpdateOrderProductsController.isPartnerUser();
            System.assertEquals(false, blnPartner, 'Standard user should return false');
            
        }
    }
    
}