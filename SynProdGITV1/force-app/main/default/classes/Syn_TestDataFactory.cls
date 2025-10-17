/*************************************************************** 
====================================================== 
Purpose: Test class to set up mock data 
===================================================== 
History: 
AUTHOR     DATE         Reference        Description 
Arpita R   03-05-2025   SS2-T189     	Initial draft
Pratik G   21/07/2025  INC.159974 		to setup the test data for Syn_RetriveVisitDetailsTest
Shyam C    18/08/2025  INC.160416		To setup the test data for Syn_RelatedPlantTeamControllerTest
***************************************************************/
@isTest
public class Syn_TestDataFactory {
    
    public static void createVisitData(){
                User testUser = new User(
                    Username = 'someone' + DateTime.now().getTime() + '@example.com',
                    Alias = 'tuser',
                    Email = 'testuser@example.com',
                    LastName = 'TestUser12',
                    ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id,
                    TimeZoneSidKey = 'America/New_York',
                    LocaleSidKey = 'en_US',
                    EmailEncodingKey = 'UTF-8',
                    LanguageLocaleKey = 'en_US',
                    Business_Partner_ID__c = String.valueOf(Crypto.getRandomInteger()).substring(0, 6) 
                );
                insert testUser;
        
        		User testUser2 = new User(
                    Username = 'someone1' + DateTime.now().getTime() + '@example.com',
                    Alias = 'tuser',
                    Email = 'testuser@example.com',
                    LastName = 'TestUser13',
                    ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id,
                    TimeZoneSidKey = 'America/New_York',
                    LocaleSidKey = 'en_US',
                    EmailEncodingKey = 'UTF-8',
                    LanguageLocaleKey = 'en_US',
                    Business_Partner_ID__c = String.valueOf(Crypto.getRandomInteger()).substring(0, 6) 
                );
                insert testUser2;
        
        		Visit_Outcome__c outcome = new Visit_Outcome__c(Outcome__c = 'Test Outcome');
                insert outcome;
        
       			Event visit1 = new Event(
                    Subject = 'Parent Visit',
                    ActivityDateTime = DateTime.now(),
                    DurationInMinutes = 30,
                    Visit_Outcome__c = outcome.Id,
                    CreatedById = testUser.Id,
                    OwnerId = testUser.Id
                );
                insert visit1;
        		
                //System.debug(relations);
				Event visit2 = new Event(
                Subject = 'Child Visit',
                ActivityDateTime =DateTime.now(),
                DurationInMinutes = 59,
                CreatedById = testUser.Id, 
                OwnerId = testUser2.Id
           		 );
            	insert visit2;
                		
    }
    
    public static Order createOrderWithItem(String strOrderType) {
        Order OrderRecord = new Order();
        Account acc = new Account(Name = 'Test Account', BillingStreet='123 Main St', BillingCity='Pune', BillingState='Maharashtra', BillingPostalCode='412109', BillingCountry='India', ShippingStreet='123 Mg Road', ShippingCity='Surat', ShippingState='Gujarat', ShippingCountry='India', ShippingPostalCode='412009', ShippingStateCode = 'GJ',
                                  ShippingCountryCode = 'IN',  Type = 'Prospect' );
        insert acc;
        
        Contact con = new Contact(FirstName = 'John', LastName = 'Doe', AccountId = acc.Id);
        insert con;
        
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
        
        System.debug('pb: '+ standardPricebook); 
        PricebookEntry existingPbe;
        
        List<PricebookEntry> existingEntries = [
            SELECT Id, UnitPrice FROM PricebookEntry 
            WHERE Product2Id = :product.Id AND Pricebook2Id = :standardPricebook.Id 
            LIMIT 1
        ];
        
        System.debug(existingEntries);
        
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
        
        Plant__c plant = new Plant__c(Name = 'Plant A', Address__CountryCode__s = 'US');
        insert plant;
        
        
        // Add sales org data
        Sales_Org_Data__c salesOrg = new Sales_Org_Data__c(
            Sales_Org_Id__c = 'SOT1',
            Name =  'Test Org'
        );
        insert salesOrg;
        
        // Add Onetime Customers
        Account domesticAcc = new Account(
            Name = 'One Time Account - International', BillingCountry='United Kingdom');
        insert domesticAcc;
        Account InternationalAcc = new Account(
            Name = 'One Time Customer Domestic', BillingCountry='India'
        );
        insert InternationalAcc;
        
        // Create account as customer
        Account customerAcct = new Account(Name = 'Test Customer Account', BillingCountry='United Kingdom');
        insert customerAcct;
        
        
        // Create test Order Type Determination
        Salesforce_Order_Type_Determination__c orderType = new Salesforce_Order_Type_Determination__c(
            Plant_ID__c = plant.Id,
            Active__c = true,
            Sales_Org__c = salesOrg.Id,
            Distribution_Channel__c = '10',
            Division__c = '00',
            One_Time_Customer_ID_Domestic__c = domesticAcc.Id,
            One_Time_Customer_ID_International__c = InternationalAcc.Id
        );
        insert orderType;

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
        // Create the Payment Terms
        Payment_Terms__c paymentTerm = new Payment_Terms__c(
            Name = 'PT30', // Payment Terms Code
            Active_Flag__c = true,
            CurrencyIsoCode = 'GBP',
            Description__c = 'Net 30 days'
        );
        insert paymentTerm;
        User testUser = new User(
            Username = 'someone' + DateTime.now().getTime() + '@example.com',
            Alias = 'tuser',
            Email = 'testuser@example.com',
            LastName = 'TestUser12',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            Business_Partner_ID__c = String.valueOf(Crypto.getRandomInteger()).substring(0, 6) 
        );
        insert testUser;
        
        
        // Create the Order record
        System.runAs(testUser) {
            Order order = new Order(
                Name = 'Test Order',
                AccountId = acc.Id, // Link to the Account created previously
                EffectiveDate = Date.today(),
                Status = 'Draft',
                Pricebook2Id = pricebookId,
                BillingStreet = '123 Main St',
                BillingCity = 'Pune',
                BillingState = 'Alaska',
                BillingPostalCode = 'L1 8JQ',
                BillingCountry = 'United States',
                BillingCountryCode ='US',
                ShipToContactId = con.Id, // Contact created previously
                Salesforce_Order_Type__c = strOrderType,
                ShippingStreet = '10 Downing Street',
                ShippingCity = 'London',
                ShippingCountryCode = 'US',
                ShippingState = 'Alaska',
                ShippingPostalCode = 'SW1A 2AA',
                ShippingCountry = 'United States',
                IncoTerms__c = 'CFR',
                IncoTerms_Location__c = 'Test',
                Sales_Organisation__c = salesOrg.Id, // Sales org created earlier
                Division__c = '00',
                Distribution_Channel__c = '10',
                Payment_Terms__c = paymentTerm.Id, // Reference to Payment Terms record
                Shipping_Condition__c = '02',
                Delivery_Block__c = '02',
                Plant__c = plant.Id,
                CreatedById = testUser.Id
            );
            insert order;
            
            // Create OrderItem with all required custom fields
            OrderItem orderProductLine = new OrderItem();
            orderProductLine.OrderId = order.Id; 
            orderProductLine.Product2Id = product.Id;
            orderProductLine.PricebookEntryId = existingPbe.Id;
            orderProductLine.Quantity = 5;
            orderProductLine.Total_Price_Internal__c = 500;
            orderProductLine.Description = 'Test Order Item Description';
            orderProductLine.Salesforce_Order_Type__c = strOrderType;
            orderProductLine.Distribution_Channel__c = '10';
            orderProductLine.Division__c = '00';
            orderProductLine.Default_Product_Used__c = true;
            orderProductLine.Sample_Item_Approval_Status__c ='Not Needed';
            insert orderProductLine;
            OrderRecord =order;
        }
        
        OrderRecord.status = 'Approved';
        return OrderRecord;
    }

    //For relatedPlantTeamController
    public static Id createPlantTeam(){
        Plant__c plant = new Plant__c(
            Name = 'Test Plant'
        );
        insert plant;

        Account customerAcct = new Account(Name = 'Test Customer Account', BillingCountry='United Kingdom');
        insert customerAcct;
        
        Order order = new Order(
            Name = 'Test Order',
            AccountId = customerAcct.Id,
            Plant__c = plant.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft'
        );
        insert order;

        Id empRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName()
    .get('Employee')
    .getRecordTypeId();
        
        
        Contact emp = new Contact(
            RecordTypeId = empRecordTypeId,
            LastName = 'Test Employee Plant Team'
        );
        insert emp;

        Plant_Team_Data__c teamMember1 = new Plant_Team_Data__c(
            Role__c = 'Sample Manager',
            Plant_ID__c = plant.Id,
            Employee__c = emp.Id
        );
        insert teamMember1;

        Id currentUserId = UserInfo.getUserId();

        Plant_Team_Data__c teamMember2 = new Plant_Team_Data__c(
            Role__c = 'Sample Manager',
            Plant_ID__c = plant.Id,
            User__c = currentUserId
        );
        insert teamMember2;

        return order.Id;
    }
    
}