/*************************************************************** 
====================================================== 
Purpose: Test class for  Syn_CreateOrderControllerTest 
===================================================== 
History:  
AUTHOR     DATE         Reference        Description 
Ishwar M                                 Initial Implementation
Vishal S   29/04/2025                 	 Initial Implementation 
Ankur O	   29/09/2025	SD1-T17			 Added method to cover isPartnerUser & partnerAccountId method
***************************************************************/
@isTest
public class Syn_CreateOrderControllerTest {
       
    @testSetup
    static void setupTestData() {
        // Create an Account with one Contact
        Account acc = new Account(Name = 'Test Account', BillingStreet='123 Main St', BillingCity='Pune', BillingState='Maharashtra', BillingPostalCode='412109', BillingCountry='India', ShippingStreet='123 Mg Road', ShippingCity='Surat', ShippingState='Gujarat', ShippingCountry='India', ShippingPostalCode='412009', ShippingStateCode = 'GJ',
                                  ShippingCountryCode = 'IN',  Type = 'Prospect', CurrencyIsoCode = 'INR', Account_DM_External_ID__c = 'SAP001Test01' );
        insert acc;
        
        Contact con = new Contact(FirstName = 'John', LastName = 'Doe', AccountId = acc.Id);
        insert con;
        
        Account shipToAccount = new Account(Name = 'ship to Account', BillingCountry='United Kingdom', ShippingStreet='123 Mg Road', ShippingCity='Surat', ShippingState='Gujarat', ShippingCountry='India', ShippingPostalCode='412009', ShippingStateCode = 'GJ',
                                  ShippingCountryCode = 'IN',  Type = 'Prospect', Account_DM_External_ID__c = 'SAP001Test02' );
        insert shipToAccount;
        
        Account_Partners_Data__c accountPartnerData = new Account_Partners_Data__c(Main_Partner__c = acc.Id, Related_Customer_ID__c = 'SAP001Test02', Account_Partner_External_ID__c ='SAP001Test01_SAP001Test02' );
        
        insert accountPartnerData;
        
        // Create an Opportunity related to that Account
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id
        );
        insert opp;
        
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
        
        PricebookEntry existingPbe;
        
        List<PricebookEntry> existingEntries = [
            SELECT Id, UnitPrice FROM PricebookEntry 
            WHERE Product2Id = :product.Id AND Pricebook2Id = :standardPricebook.Id 
            LIMIT 1
        ];
                
        if (existingEntries.isEmpty()) {
            // Add if not present
            existingPbe = new PricebookEntry(
                Product2Id = product.Id,
                Pricebook2Id = standardPricebook.Id,
                UnitPrice = 100,
                IsActive = true
            );
            insert existingPbe;
        } else {
            // Use existing
            existingPbe = existingEntries[0];
        }
        // Assuming Address__c is a custom address type field with country
        // Address addr = new Address();
        // addr.country = 'USA';

        // Create Plant
        Plant__c plant = new Plant__c(Name = 'Plant A', Address__CountryCode__s = 'US');
        insert plant;
		
        Plant__c plant2 = new Plant__c(Name = 'Plant B', Address__CountryCode__s = 'US');
        insert plant2;
      
        // Add sales org data
        Sales_Org_Data__c salesOrg = new Sales_Org_Data__c(
            Sales_Org_Id__c = 'SOT1',
            Name =  'Test Org'
        );
        insert salesOrg;

        // Add Onetime Customers
        Account domesticAcc = new Account(
            Name = 'One Time Customer Domestic', BillingCountry='India' );
            insert domesticAcc;
        Account InternationalAcc = new Account(
            Name = 'One Time Account - International', BillingCountry='India'
        );
            insert InternationalAcc;

            // Create account as customer
        Account customerAcct = new Account(Name = 'Test Customer Account', BillingCountry='India');
        insert customerAcct;
        
            
        // Create test Order Type Determination
        Salesforce_Order_Type_Determination__c orderType1 = new Salesforce_Order_Type_Determination__c(
            Plant_ID__c = plant.Id,
            Active__c = true,
            Sales_Org__c = salesOrg.Id,
            Distribution_Channel__c = '10',
            Division__c = '00',
            One_Time_Customer_ID_Domestic__c = domesticAcc.Id,
            One_Time_Customer_ID_International__c = InternationalAcc.Id
        );
        insert orderType1;
        
         Salesforce_Order_Type_Determination__c orderType2 = new Salesforce_Order_Type_Determination__c(
            Plant_ID__c = plant2.Id,
            Active__c = true,
            Sales_Org__c = salesOrg.Id,
            Distribution_Channel__c = '20',
            Division__c = '00',
            One_Time_Customer_ID_Domestic__c = domesticAcc.Id,
            One_Time_Customer_ID_International__c = InternationalAcc.Id
        );
        insert orderType2;


        // Create Payment Term
        Payment_Terms__c paymentTerm = new Payment_Terms__c(
            	Name = 'AD10',
            Description__c = '10% Advance Payment,',
            Active_Flag__c = true
        );

        insert paymentTerm;

        // Create matching Account_Sales_Data__c
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
        insert salesData;
		
        // Account Sales data for domestic account
        Account_Sales_Data__c salesData1 = new Account_Sales_Data__c(
            Account__c = domesticAcc.Id,
            Sales_Org_Data__c = salesOrg.Id,
            Distribution_Channel__c = '10',
            Division__c = '00',
            Account_Sales_External_ID__c = 'SOT1_10_00_02',
            Payment_Term__c = paymentTerm.Id,
            Incoterms__c = 'CFR',
            IncoTerms_Location__c = 'US'
        );
        insert salesData1;
        
        // Account Sales data for International account
        Account_Sales_Data__c salesData2 = new Account_Sales_Data__c(
            Account__c = InternationalAcc.Id,
            Sales_Org_Data__c = salesOrg.Id,
            Distribution_Channel__c = '20',
            Division__c = '00',
            Account_Sales_External_ID__c = 'SOT1_10_00',
            Payment_Term__c = paymentTerm.Id,
            Incoterms__c = 'CFR',
            IncoTerms_Location__c = 'US'
        );
        insert salesData2;
        
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
        
        // Set up Order
        Order order = new Order(
            Name = 'Test Order',
            AccountId = acc.Id, // Dummy value for required field
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Shipping_Condition__c = '03',
            Delivery_Block__c = '02',
            Pricebook2Id = pricebookId,
            CurrencyIsoCode = 'INR'
        );
        insert order;
        
    }
    
    @isTest
static void testCreateOrderWithProducts() {
    // Create test Account
    Account acc =[SELECT Id FROM Account WHERE Name ='Test Account' LIMIT 1];

    // Create Ship To Account
    Account shipTo = new Account(Name = 'Ship To Account', BillingCountry='India');
    insert shipTo;

   Product2 product = [SELECT Id FROM Product2 WHERE Name =: 'Test Product' LIMIT 1];
        
        
        PricebookEntry pbe =[SELECT Id, Pricebook2Id FROM PricebookEntry WHERE Product2Id =: product.Id AND  CurrencyIsoCode = 'GBP' LIMIT 1];
    
    Plant__c plant = [SELECT Id FROM Plant__c WHERE Name = 'Plant A' LIMIT 1];
	 Sales_Org_Data__c salesOrg = [Select Id FROM Sales_Org_Data__c WHERE  Sales_Org_Id__c = 'SOT1'];
    
     Payment_Terms__c paymentTerm =[SELECT ID FROM Payment_Terms__c WHERE Name = 'AD10'];

    // Construct orderFields map
    Map<String, Object> orderFields = new Map<String, Object>{
        'AccountId' => acc.Id,
        'Ship_To_Account__c' => shipTo.Id,
        'EffectiveDate' => String.valueOf(Date.today()),
        'Status' => 'Draft',
        'Pricebook2Id' => pbe.Pricebook2Id,
        'CurrencyIsoCode' => 'GBP',
        'BillingStreet' => '123 Billing St',
        'BillingCity' => 'Billing City',
        'BillingState' => 'Alabama',
        'BillingPostalCode' => '90001',
        'BillingCountry' => 'United States',
        'ShippingStreet' => '456 Shipping St',
        'ShippingCity' => 'Shipping City',
        'ShippingState' => 'Alabama',
        'ShippingPostalCode' => '10001',
        'ShippingCountry' => 'United States',
        'Plant__c' => plant.Id,
        'Sales_Orgnization__c' => salesOrg.Id ,
        'Delivery_Block__c' => '01',
        'Distribution_Channel__c' => '10',
        'S4_Order_Type__c' => 'ZSAM',
        'Salesforce_Order_Type__c' => 'ZSLS',
        'Division__c' => '00',
        'Shipping_Condition__c' => '02',
        'IncoTerms__c' => 'CFR',
        'Evaluated_Sold_To_Party__c' => acc.Id,
        'IncoTerms_Location__c' => 'Warehouse 5',
        'Payment_Terms__c' => paymentTerm.Id,
         'isShipToContactRelated' => True
    };

    // Construct orderProducts list
    List<Map<String, Object>> orderProducts = new List<Map<String, Object>>{
        new Map<String, Object>{
            'productId' => product.Id,
            'quantity' => 2,
            'totalPrice' => 100,
            'pricebookEntryId' => pbe.Id,
             'pricebook2Id' => pbe.Pricebook2Id,
              'currencyIsoCode' => 'GBP',
                'defaultProductUsed' => false,
               'stockLevel' => 100
        }
    };

    Test.startTest();
    Id orderId = Syn_CreateOrderController.createOrderWithProducts(orderFields, orderProducts);
    Test.stopTest();

    // Assertions
    System.assertNotEquals(null, orderId, 'Order ID should not be null');

    Order createdOrder = [SELECT Id, AccountId FROM Order WHERE Id = :orderId];
    System.assertEquals(acc.Id, createdOrder.AccountId, 'Order should be linked to correct Account');

    List<OrderItem> orderItems = [SELECT Id, Quantity FROM OrderItem WHERE OrderId = :orderId];
    System.assertEquals(1, orderItems.size(), 'One OrderItem should be created');
    System.assertEquals(2, orderItems[0].Quantity, 'OrderItem quantity should match');
}
    
    @isTest
    static void testGetRecordDetailsWithOpportunity() {
        // Fetch opportunity for the test
        Opportunity testOpp = [SELECT Id, AccountId FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        
        Test.startTest();
        Syn_CreateOrderController.WrapperOrderData result = Syn_CreateOrderController.getRecordDetails(testOpp.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assertEquals(testOpp.Id, result.opportunityId);
        System.assertEquals(testOpp.AccountId, result.accountId);
        System.assertNotEquals(null, result.contactId, 'Expected a contact ID to be returned');
        System.assertEquals(null, result.errorMessage);
    }
    
    @isTest
    static void testGetRecordDetailsWithAccount() {
        Account testAcc = [SELECT Id, Name FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Test.startTest();
        Syn_CreateOrderController.WrapperOrderData result = Syn_CreateOrderController.getRecordDetails(testAcc.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assertEquals(null, result.opportunityId);
        System.assertEquals(testAcc.Id, result.accountId);
        System.assertNotEquals(null, result.contactId, 'Expected a contact ID to be returned');
        System.assertEquals(null, result.errorMessage);
    }
    
    @isTest
    static void testGetRecordDetailsWithInvalidId() {
        Contact testCon = [SELECT Id FROM Contact LIMIT 1];
        
        Test.startTest();
        Syn_CreateOrderController.WrapperOrderData result = Syn_CreateOrderController.getRecordDetails(testCon.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assertEquals('Invalid record ID. This is not an Opportunity or Account record.', result.errorMessage);
        System.assertEquals(null, result.opportunityId);
        System.assertEquals(null, result.accountId);
        System.assertEquals(null, result.contactId);
    }
    
    @isTest
    static void testGetAccountDetails() {
        Account testAcc = [SELECT Id, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, ShippingStreet, ShippingCity, ShippingState, ShippingCountry, ShippingPostalCode, ShippingStateCode, ShippingCountryCode FROM Account LIMIT 1];
        
        Test.startTest();
        Map<Id, Account> result = Syn_CreateOrderController.getAccountDetails(new List<Id>{testAcc.Id});
        Test.stopTest();
        
        System.assertEquals(1, result.size());
        System.assertEquals(testAcc.Id, result.get(testAcc.Id).Id);
        
    }
    
    @isTest
    static void testInsertOrderProducts() {
        // Setup: Create necessary records
        
        // UoM
        UoM_Std_Data__c uom = [SELECT Id FROM UoM_Std_Data__c WHERE UOM_Code__c =: 'KGM' LIMIT 1];
        
        
        
        // Product
        Product2 product = [SELECT Id FROM Product2 WHERE Name =: 'Test Product' LIMIT 1];
        
        
        PricebookEntry pbe =[SELECT Id, Pricebook2Id FROM PricebookEntry WHERE Product2Id =: product.Id LIMIT 1];
        
        
        // Sample Master Matrix
        Sample_Master_Matrix_Data__c matrix = [ SELECT Id, Plant_Id__c FROM Sample_Master_Matrix_Data__c WHERE Product__c =: product.Id LIMIT 1 ];
        
        // Order
        Order order = [SELECT Id, CurrencyIsoCode FROM Order WHERE Name =: 'Test Order' LIMIT 1];
        
        
        // Mock input map like from LWC
        Map<String, Object> orderProductMap = new Map<String, Object>{
            'Id' => matrix.Id,
                'productId' => product.Id,
                'pricebookEntryId' => pbe.Id,
                'quantity' => 10,
                'totalPrice' => 1000,
                'description' => 'Test Order Item',
                'plantId' => matrix.Plant_ID__c, // Use a valid plant ID if lookup validation exists
                'SalesforceOrderType' => 'ZPLS',
                's4OrderType' => 'ZSAM',
                'itemCategory' => 'ZSAF',
                'salesOrg' => null,
                'distributionChannel' => '10',
                'division' => '00',
                'uomId' => uom.Id,
                'stockLevel' => 25,
                'shippingDate' => Date.today().addDays(3),
                'defaultProductUsed' => true,
                'currencyIsoCode'=> 'INR',
            	'pricebook2Id' => pbe.Pricebook2Id
                };
                    
                    Test.startTest();
        Syn_CreateOrderController.insertOrderProducts(new List<Map<String, Object>>{orderProductMap}, order.Id);
        Test.stopTest();
        
        // Assertions
        List<OrderItem> items = [SELECT Id, OrderId, Product2Id, Quantity, Total_Price_Internal__c, Description 
                                 FROM OrderItem WHERE OrderId = :order.Id];
        
        System.assertEquals(1, items.size(), 'One OrderItem should be inserted');
        System.assertEquals(product.Id, items[0].Product2Id, 'Product should match');
        System.assertEquals(10, items[0].Quantity, 'Quantity should match');
        System.assertEquals(1000, items[0].Total_Price_Internal__c, 'Total price should match');
    }

    @isTest
    static void testGetEvaluatedSoldToParty_ProspectDomestic() {

        // get plant
        Plant__c plant = [SELECT Id FROM Plant__c WHERE Name = 'Plant B' LIMIT 1];

        //get Account
        Account acc =[SELECT Id FROM Account WHERE Name ='Test Account' LIMIT 1];
        
        //get domestic Account
     Account domesticAcc = [SELECT ID FROM Account WHERE Name = 'One Time Account - International' LIMIT 1];
        

         // Run method and assert result
            Test.startTest();
            Syn_CreateOrderController.EvaluatedAccountInfo result =
                Syn_CreateOrderController.getEvaluatedSoldToParty(acc.Id, plant.Id, 'UK');
            Test.stopTest();

            System.assertNotEquals(null, result, 'Result should not be null');
            System.assertEquals(domesticAcc.Id, result.evaluatedSoldToParty, 'Expected domestic one-time customer ID for Prospect account.');
            System.assertNotEquals(null, result.paymentTerm, 'Expected payment term to be returned');
            System.assertNotEquals(null, result.incoterms, 'Expected incoterms to be returned');
    }

    @isTest
    static void testGetEvaluatedSoldToParty_AccountWithSalesData() {

        // get Account 
        
        Account acct = [SELECT Id FROM Account WHERE Name = 'Test Customer Account' LIMIT 1];
    

        // get Plant
        Plant__c plant = [SELECT Id FROM Plant__c WHERE Name = 'Plant A' LIMIT 1];

        // Run method and assert result
        Test.startTest();
        Syn_CreateOrderController.EvaluatedAccountInfo result =
            Syn_CreateOrderController.getEvaluatedSoldToParty(acct.Id, plant.Id, 'US');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(acct.Id, result.evaluatedSoldToParty, 'Expected original account ID due to matching sales data.');
        System.assertNotEquals(null, result.paymentTerm, 'Expected payment term to be returned');
        System.assertNotEquals(null, result.incoterms, 'Expected incoterms to be returned');

    }
    
    @isTest
    static void testGetEvaluatedSoldToParty_CustomerInternational() {

         // Create Plant
        Plant__c plant = [SELECT Id FROM Plant__c WHERE Name = 'Plant B' LIMIT 1];

        //get account
         Account acct = [SELECT Id FROM Account WHERE Name = 'Test Customer Account' LIMIT 1];
       
        
        //get domestic Account
     Account internationalAcct = [SELECT ID FROM Account WHERE Name = 'One Time Account - International' LIMIT 1];
        

         // Run method and assert result
            Test.startTest();
            Syn_CreateOrderController.EvaluatedAccountInfo result =
                Syn_CreateOrderController.getEvaluatedSoldToParty(acct.Id, plant.Id, 'UK');
            Test.stopTest();

            System.assertNotEquals(null, result, 'Result should not be null');
            System.assertEquals(internationalAcct.Id, result.evaluatedSoldToParty, 'Expected domestic one-time customer ID for Prospect account.');
            System.assertNotEquals(null, result.paymentTerm, 'Expected payment term to be returned');
            System.assertNotEquals(null, result.incoterms, 'Expected incoterms to be returned');
    }
   @isTest
    static void testGetOpportunitiesByAccount() {
        // get Account
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        
  
        // get Opportunity
        Opportunity opp1 = [SELECT ID FROM Opportunity WHERE Name = 'Test Opportunity'];
        

        Test.startTest();
        List<Opportunity> result = Syn_CreateOrderController.getOpportunitiesByAccount(testAccount.Id);
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.size(), 'Only one open opportunity should be returned');
        System.assertEquals(opp1.Id, result[0].Id, 'The open opportunity should be returned');
    }
	
      @isTest
    static void testValidateShipToContact_True() {
  
        // Get Contact
        Contact con = [SELECT ID, AccountId FROM Contact WHERE LastName = 'Doe' LIMIT 1];


        // Call the method
        Boolean result = Syn_CreateOrderController.validateShipToContact(con.Id, con.AccountId);

        System.assertEquals(true, result, 'Should return true when active relation exists.');
    }
    
       @isTest
    static void testGetShipToAccount_Success() {
        

        // Get Main Partner Account
        Account mainPartner = [SELECT ID FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        // Get ship to Account
        Account shipTo = [SELECT Id, Account_DM_External_ID__c FROM Account WHERE Name = 'ship to Account' LIMIT 1];
		
        // Call method
        Id result = Syn_CreateOrderController.getShipToAccount(mainPartner.Id);

        System.assertEquals(shipTo.Id, result, 'Expected to return the Ship To Account Id');
    }
    
    
    /*************************************************************** 
====================================================== 
Purpose: Test method to cover isPartnerUser & partnerAccountId method
===================================================== 
History:  
AUTHOR     DATE         Reference        Description 
Ankur O	   29/09/2025	SD1-T17			 Test method to cover isPartnerUser & partnerAccountId method
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
            Boolean blnPartner = Syn_CreateOrderController.isPartnerUser();
            System.assertEquals(false, blnPartner, 'Standard user should return false');
            
            // Test partnerAccountId
            Id idAccount = Syn_CreateOrderController.partnerAccountId();
            System.assertEquals(null, idAccount, 'Standard user has no AccountId in Apex, so should be null');
        }
    }

}