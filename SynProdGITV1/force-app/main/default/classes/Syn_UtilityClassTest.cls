/*************************************************************** 
Purpose: Test Class for Apex Utilities  
====================================================== 
History: 
AUTHOR            DATE       Reference        Description 
Kamlesh Shinde   31/03/2025             Initial Implementation  
***************************************************************/
@isTest
public with sharing class Syn_UtilityClassTest {
    
    /*************************************************************** 
    Purpose: Set Up data for test
    ====================================================== 
    History: 
    AUTHOR            DATE       Reference        Description 
    Kamlesh Shinde   31/03/2025             Initial Implementation  
    ***************************************************************/    
    @TestSetup
    Static Void setUpData(){
        //Step 1: Set the pricebook
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = pricebookId,
            IsActive = true
        );
        update standardPricebook;
        
        //Step 2: Create UoM_Std_Data__c records
        List<UoM_Std_Data__c> lstOfUOM = new List<UoM_Std_Data__c>();

        lstOfUOM.add(new UoM_Std_Data__c(  Name = 'Meter', Dimension__c = 'LENGTH', UOM_Code__c='MTR', Internal_UoM_Code__c ='M' ));
        lstOfUOM.add(new UoM_Std_Data__c(  Name = 'Bag', Dimension__c = 'AAAADL', UOM_Code__c='BG', Internal_UoM_Code__c ='BAG' ));
        lstOfUOM.add(new UoM_Std_Data__c(  Name = 'Large Bag', Dimension__c = 'AAAADL', UOM_Code__c='LBG', Internal_UoM_Code__c ='LB' ));
        lstOfUOM.add(new UoM_Std_Data__c(  Name = 'Gram', Dimension__c = 'MASS', UOM_Code__c='GRM', Internal_UoM_Code__c ='G'  ));
        lstOfUOM.add(new UoM_Std_Data__c(  Name = 'Kilogram', Dimension__c = 'MASS', UOM_Code__c='KGM', Internal_UoM_Code__c ='KG' ));
        lstOfUOM.add(new UoM_Std_Data__c(  Name = 'Liter', Dimension__c = 'VOLUME', UOM_Code__c='LTR', Internal_UoM_Code__c ='L' ));
        lstOfUOM.add(new UoM_Std_Data__c(  Name = 'Milliliter', Dimension__c = 'VOLUME', UOM_Code__c='MLT', Internal_UoM_Code__c ='ML' ));
        lstOfUOM.add(new UoM_Std_Data__c(  Name = 'US Gallon', Dimension__c = 'VOLUME', UOM_Code__c='GLL', Internal_UoM_Code__c ='GAL' ));
        
        insert lstOfUOM;
        
        //Step 3: Create Product records
        List<Product2> lstProducts = new List<Product2>();
		UoM_Std_Data__c uom1Reference = New UoM_Std_Data__c(UOM_Code__c = 'LBG');
        UoM_Std_Data__c uom2Reference = New UoM_Std_Data__c(UOM_Code__c = 'LTR');
        
        lstProducts.add(new Product2(Name = 'Product1', IsActive = true, Product_Id__c = '123', Base_UoM__r = uom1Reference));
        lstProducts.add(new Product2(Name = 'Product2', IsActive = true, Product_Id__c = '124', Base_UoM__r = uom2Reference));

        insert lstProducts;
        
        Product2 prdRef = New Product2(Product_Id__c = '123');
        UoM_Std_Data__c uomReference = New UoM_Std_Data__c(UOM_Code__c = 'KGM');
            
        //Step 4: Create Product_Conversions_Data__c records related to the product
        List<Product_Conversions_Data__c> lstPordConversionData = new List<Product_Conversions_Data__c>();
        Product_Conversions_Data__c objProductConversion = new Product_Conversions_Data__c(Product__r = prdRef, Alternative_Unit__r = uomReference, Product_Conversion_Ext_ID__c = '1');
        
        Insert objProductConversion;
    }
    

    /*************************************************************** 
    Purpose: Test method for UtilityClass.getValidUoMListforProduct
    ====================================================== 
    History: 
    AUTHOR            DATE       Reference        Description 
    Kamlesh Shinde   31/03/2025             Initial Implementation  
    ***************************************************************/        
    @isTest
    static void testGetUomStdDataNamesByProduct() {
        
        List<String> lstProdIds = New List<String>();
        //Step 1: Get all products to use the test
        List<Product2> lstProds = [Select id from product2];
        For(Product2 objProd : lstProds){
            lstProdIds.add(objProd.id);
        }
        
        Test.startTest();
        // Step 2: Call the method to test
        List<Syn_UtilityClass.OutputUoM> lstUomStdNames = Syn_UtilityClass.getValidUoMListforProduct(lstProdIds);
        Test.stopTest();

        System.assertEquals(lstProds.size(), lstUomStdNames.size());

		//Step 3: get product data for assertion 
		Map<Id, Product2> idToProdRec = New Map<Id, Product2>([SELECT Id, Product_Id__c FROM Product2]);
        
        //Step 4: Based on the business logic for the product id = 123; The valid UoMs should be - LBG, KGM and GRM
        //Step 4a: Get UoM Ids for the first product
        List<UoM_Std_Data__c> lstUoMsPrd123 = [Select id, UOM_Code__c FROM UoM_Std_Data__c WHERE UOM_Code__c = 'LBG' OR UOM_Code__c = 'KGM' OR UOM_Code__c = 'GRM' ORDER BY ID];
         
        //Step 5: Based on the business logic for the product id = 124; The valid UoMs should be - LTR, MLT and GLL
        //Step 5a: Get UoM Ids for the second product
        List<UoM_Std_Data__c> lstUoMsPrd124 = [Select id, UOM_Code__c FROM UoM_Std_Data__c WHERE UOM_Code__c = 'LTR' OR UOM_Code__c = 'MLT' OR UOM_Code__c = 'GLL' ORDER BY ID];
        
        For(Syn_UtilityClass.OutputUoM outputUoM : lstUomStdNames){
            outputUoM.validUoMs?.sort();
            If(idToProdRec.get(outputUoM.productId)?.Product_Id__c == '123'){
                System.assertEquals(lstUoMsPrd123[0].Id, outputUoM.validUoMs.get(0));
                System.assertEquals(lstUoMsPrd123[1].Id, outputUoM.validUoMs.get(1));
                System.assertEquals(lstUoMsPrd123[2].Id, outputUoM.validUoMs.get(2));
            }
            If(idToProdRec.get(outputUoM.productId)?.Product_Id__c == '124'){       
                System.assertEquals(lstUoMsPrd124[0].Id, outputUoM.validUoMs.get(0));
                System.assertEquals(lstUoMsPrd124[1].Id, outputUoM.validUoMs.get(1));
                System.assertEquals(lstUoMsPrd124[2].Id, outputUoM.validUoMs.get(2));
            }            
        }
    }
}