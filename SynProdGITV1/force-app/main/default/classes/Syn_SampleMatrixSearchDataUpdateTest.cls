/*************************************************************** 
====================================================== 
Purpose: Test class for Syn_UpdateSearchDataBatch 
===================================================== 
History: 
AUTHOR     DATE 	    Reference 	     Description 
Vishal S   16/06/2025            	     Initial Implementation	 
***************************************************************/ 
@isTest
private class Syn_SampleMatrixSearchDataUpdateTest {

    @IsTest
    static void testExecuteMethod() {
        // Create lookup records
        //setup PriceBook
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = pricebookId,
            IsActive = true
        );
        update standardPricebook;
        
        // Create Product Category
        Product_Category__c category = new Product_Category__c(Name = 'Chemicals', Product_Category_Id__c ='Test_PC_001', Level__c = '3 - Product', Hierarchy_Info__c = 'Dispersion polymer - PA_Pure Acrylic');
        insert category;
        
        // Create Product
        Product2 product = new Product2(Name = 'Test Product', Product_Id__c = 'Test_P001' , Product_Category__c = category.Id, StockKeepingUnit = 'KG');
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
        User approver = new User(
            FirstName = 'Test',
            LastName = 'Approver',
            Alias = 'tapprov',
            Email = 'testapprover@example.com',
            Username = 'testapprover' + DateTime.now().getTime() + '@example.com',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert approver;

        // Create main record
        Sample_Master_Matrix_Data__c record = new Sample_Master_Matrix_Data__c(
            Product__c = product.Id,
            Plant_ID__c = plant.Id,
            Product_Category_ID__c = category.Id,
            Region__c = 'ASIA',
            Approver__c = approver.Id
        );
        insert record;

        Test.startTest();
        Database.executeBatch(new Syn_SampleMatrixSearchDataUpdateBatch(), 200);
        Test.stopTest();

        // Validate results
        record = [SELECT Search_Data__c FROM Sample_Master_Matrix_Data__c WHERE Id = :record.Id];
        System.assertEquals('Test_P001 -> Test Product -> Plant A -> Chemicals -> ASIA -> Test Approver', record.Search_Data__c);
    }
}