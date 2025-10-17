/*************************************************************** 
====================================================== 
Purpose: Product Selector LWC controller class
===================================================== 
History: 
AUTHOR     DATE 	    Reference 	     Description 
Vishal S   08/04/2025    SSP-353	    Initial Implementation	 
***************************************************************/ 
public with sharing class Syn_ProductSelectorController {
    
    
    /*************************************************************** 
====================================================== 
Purpose: Retrive products based user input values
===================================================== 
History: 
AUTHOR     DATE 	    Reference 	     Description 
Vishal S   08/04/2025    SSP-353	    Initial Implementation	 
***************************************************************/ 
    @AuraEnabled(cacheable=true)
    public static SampleSearchResult searchProducts(String productName, String categoryName, String unitOfMeasureName, String requiredQuantity, String region, Integer pageNumber,
    Integer pageSize) {
        System.debug('pageNumber:'+pageNumber);
        Integer safePageNumber = (pageNumber == null || pageNumber < 1) ? 1 : pageNumber;
        List<SampleMasterMatrixWrapper> wrappedResults = new List<SampleMasterMatrixWrapper>();
          SampleSearchResult resultWrapper = new SampleSearchResult();
        Integer totalRecords = 0;
        
        if(productName == null && categoryName == null ){
            resultWrapper.records = wrappedResults;
           resultWrapper.totalRecords = 0;
           return resultWrapper;
        }

        // Add wildcards for partial match
        String nameFilter = '%' + productName.replace('*', '%') + '%';
        String categoryFilter = (categoryName != null && categoryName != '') ? '%' + categoryName.replace('*', '%') + '%' : null;
        String unitOfMeasureFilter = (unitOfMeasureName != null && unitOfMeasureName != '') ? '%' + unitOfMeasureName.replace('*', '%') + '%' : null;
        String regionFilter = (region != null && region != '') ? '%' + region + '%' : null;
        Decimal requiredQty = (requiredQuantity != null && requiredQuantity != '')?Decimal.valueOf(requiredQuantity):null;
        String samplingStatus = '02 - Active';

        System.debug(nameFilter + ' '+ categoryFilter + ' '+ unitOfMeasureFilter);
        
          // Apply LIMIT and OFFSET
       Integer offsetVal = (safePageNumber - 1) * pageSize;
       // Get total count
      String countQuery = 'SELECT COUNT() FROM Sample_Master_Matrix_Data__c WHERE Sampling_Status__c  =: samplingStatus';

        // Start building the query string
        String query = 'SELECT Id, Name, Product__c, Plant_ID__c, Product__r.Product_Id__c, Product__r.Name, Product_Category_ID__r.Name, Plant_ID__r.Name, ' +
            'Min__c, Max__c, Product__r.StockKeepingUnit, Unit__r.Name, Region__c, Sampling_Status__c ' +
            'FROM Sample_Master_Matrix_Data__c WHERE Sampling_Status__c  =: samplingStatus' ;
            
         
            query += ' AND Product__r.Name LIKE \'' + String.escapeSingleQuotes(nameFilter) + '\'';
            countQuery += ' AND Product__r.Name LIKE \'' + String.escapeSingleQuotes(nameFilter) + '\'';
    

        if (categoryFilter != null) {
            query += ' AND Product_Category_ID__r.Name LIKE \'' + String.escapeSingleQuotes(categoryFilter) + '\'';
             countQuery += ' AND Product_Category_ID__r.Name LIKE \'' + String.escapeSingleQuotes(categoryFilter) + '\'';
        }
        
        if(unitOfMeasureFilter != null) {
            query += 'AND (Unit__r.Name LIKE \'' + String.escapeSingleQuotes(unitOfMeasureFilter) + '\' OR Unit__r.UOM_Code__c LIKE \'' + String.escapeSingleQuotes(unitOfMeasureFilter) + '\')';
            countQuery += 'AND (Unit__r.Name LIKE \'' + String.escapeSingleQuotes(unitOfMeasureFilter) + '\' OR Unit__r.UOM_Code__c LIKE \'' + String.escapeSingleQuotes(unitOfMeasureFilter) + '\')';
        }
        
        if(regionFilter != null){
            query += ' AND (Region__c LIKE \'' + String.escapeSingleQuotes(regionFilter) + '\' OR Region__c = null OR Region__c = \'\')';
            countQuery += ' AND (Region__c LIKE \'' + String.escapeSingleQuotes(regionFilter) + '\' OR Region__c = null OR Region__c = \'\')';
        }
       
        query += ' ORDER BY Min__c ASC';
        query += ' LIMIT ' + pageSize + ' OFFSET ' + offsetVal;
       
        
        // Execute the dynamic SOQL query
        List<Sample_Master_Matrix_Data__c> lstProductSampleMasterMatrixData = Database.query(query);
        totalRecords = (Integer) Database.countQuery(countQuery);
        List<Sample_Master_Matrix_Data__c> finalListProductSampleMasterMatrixData = new List<Sample_Master_Matrix_Data__c>();
        // Boolean blnQty = false;
        
        // if(requiredQty!= null){
        //     for (Sample_Master_Matrix_Data__c record : lstProductSampleMasterMatrixData) {
        //         // You can access fields like:
        //         Decimal minQty = record.Min__c;
        //         Decimal maxQty = record.Max__c;
                
        //         if(requiredQty <= maxQty && requiredQty >= minQty){
                    
        //             if(!blnQty){
        //             finalListProductSampleMasterMatrixData.clear();
        //             }
        //             finalListProductSampleMasterMatrixData.add(record);
        //             blnQty = true;
        //             continue;
        //         }else if(requiredQty <= minQty && !blnQty){
        //             finalListProductSampleMasterMatrixData.add(record);
        //             continue;
        //         }else if(requiredQty >=minQty && !blnQty){
        //             finalListProductSampleMasterMatrixData.clear();
        //             finalListProductSampleMasterMatrixData.add(record);        
        //         }
                
        //         // Example debug log
        //         System.debug('Product: ' + productName + ', Region: ' + region);
        //     }
        // }
        // else{
        //     finalListProductSampleMasterMatrixData.addAll(lstProductSampleMasterMatrixData);
        // }
        
        finalListProductSampleMasterMatrixData.addAll(lstProductSampleMasterMatrixData);

        List<Id> productIds = new List<Id>();
        
        for (Sample_Master_Matrix_Data__c record : finalListProductSampleMasterMatrixData) {
            if (record.Product__r != null) {
                productIds.add(record.Product__r.Id);
            }
        }
        System.debug('productIds '+ productIds);
        List<Product_Stock_Data__c> productStockData = [Select Id, Product_ID__c, Stock_level__c FROM Product_Stock_Data__c WHERE Product_ID__c IN: productIds];
        
        //Map<String, List<Sample_Master_Matrix_Data__c>> resultMap = new Map<String, List<Sample_Master_Matrix_Data__c>>();
        
        // Prepare a map for faster stock level lookup
        Map<Id, Product_Stock_Data__c> stockMap = new Map<Id, Product_Stock_Data__c>();
        for (Product_Stock_Data__c stock : productStockData) {
            stockMap.put(stock.Product_ID__c, stock);
        }
        
        // Build final wrapper list
        //List<SampleMasterMatrixWrapper> wrappedResults = new List<SampleMasterMatrixWrapper>();
        for (Sample_Master_Matrix_Data__c matrix : finalListProductSampleMasterMatrixData) {
            Decimal stockLevel = null;
            if (matrix.Product__r != null && stockMap.containsKey(matrix.Product__r.Id)) {
                stockLevel = stockMap.get(matrix.Product__r.Id).Stock_level__c;
            }
            wrappedResults.add(new SampleMasterMatrixWrapper(matrix, stockLevel));
        }
        System.debug(wrappedResults);
       // return wrappedResults;
      
       resultWrapper.totalRecords = totalRecords;
       resultWrapper.records = wrappedResults;
       return resultWrapper;
    }
    
    /*************************************************************** 
====================================================== 
Purpose:Search product Names based on user Input
===================================================== 
History: 
AUTHOR     DATE 	    Reference 	     Description 
Vishal S   30/04/2025    SSP-353	    Initial Implementation	 
***************************************************************/
    @AuraEnabled(cacheable = true)
    public static List<String> searchProductNames(String searchTerm)
    {        
        // Query Product Names
        String searchTermFilter = searchTerm.replace('*', '%');
        List<Sample_Master_Matrix_Data__c> products = [
            SELECT Product__r.Name
            FROM Sample_Master_Matrix_Data__c
            WHERE Product__r.Name LIKE :('%' + searchTermFilter + '%') 
            ORDER BY Name
            LIMIT 25
        ];
      
        Set<String> uniqueProductNames = new Set<String>();
        
        // Populate the Set to remove duplicates
        for (Sample_Master_Matrix_Data__c product : products) {
            uniqueProductNames.add(product.Product__r.Name);
        }
  		System.debug(uniqueProductNames);
        return new List<String>(uniqueProductNames);
    }   
    
    /*************************************************************** 
====================================================== 
Purpose:Search categries based on user Input
===================================================== 
History: 
AUTHOR     DATE 	    Reference 	     Description 
Vishal S   08/04/2025    SSP-353	    Initial Implementation	 
***************************************************************/
    @AuraEnabled(cacheable=true)
    public static List<String> searchCategories(String searchTerm) {   
        
        String searchTermFilter = searchTerm.replace('*', '%');
        // Query categories
        List<Sample_Master_Matrix_Data__c> categories = [
            SELECT Product_Category_ID__r.Name
            FROM Sample_Master_Matrix_Data__c
            WHERE Product_Category_ID__r.Name LIKE :('%' + searchTermFilter + '%') 
            AND Product_Category_ID__r.Level__c = '3 - Product'
            ORDER BY Product_Category_ID__r.Name
            LIMIT 25
        ];
        
        // Use a Set to ensure uniqueness based on a specific field
        Set<String> uniqueCategories = new Set<String>();
        
        // Populate the Set to remove duplicates
        for (Sample_Master_Matrix_Data__c category : categories) {
            uniqueCategories.add(category.Product_Category_ID__r.Name);
        }
       
        return new List<String>(uniqueCategories);
    }
    
    
    
    /*************************************************************** 
====================================================== 
Purpose: Retrive UOM standard data based on user input values
===================================================== 
History: 
AUTHOR     DATE 	    Reference 	     Description 
Vishal S   08/04/2025    SSP-353	    Initial Implementation	 
***************************************************************/
    @AuraEnabled(cacheable=true)
    public static List<UoM_Std_Data__c> searchUoM(String searchTerm){
        
        String searchTermFilter = searchTerm.replace('*', '%');

        return [
            SELECT Id, Name 
            FROM UoM_Std_Data__c  
            WHERE Name LIKE :('%'+searchTermFilter+'%') OR UOM_Code__c  LIKE :('%'+searchTermFilter+'%')
            ORDER BY Name 
            Limit 25
        ];
        
    }
    
    
    /*************************************************************** 
====================================================== 
Purpose: Wrapper class to send the data to LWC
===================================================== 
History: 
AUTHOR     DATE 	    Reference 	     Description 
Vishal S   08/04/2025    SSP-353	    Initial Implementation	 
***************************************************************/
    
    public class SampleMasterMatrixWrapper {
        @AuraEnabled public Sample_Master_Matrix_Data__c matrixRecord;
        @AuraEnabled public Decimal stockLevel;
        
        public SampleMasterMatrixWrapper(Sample_Master_Matrix_Data__c matrixRecord, Decimal stockLevel) {
            this.matrixRecord = matrixRecord;
            this.stockLevel = stockLevel;
        }
    }
    
    public class SampleSearchResult {
    @AuraEnabled public Integer totalRecords;
    @AuraEnabled public List<SampleMasterMatrixWrapper> records;
}

    /*************************************************************** 
====================================================== 
Purpose: To validate the ticked products
===================================================== 
History: 
AUTHOR     DATE 	    Reference 	     Description 
Vishal S   08/04/2025    SSP-353	    Initial Implementation	 
***************************************************************/
    @AuraEnabled
    public static selectedProductWrapper validateTickedProducts(
        String productId, 
        String plantId,
        String unitOfMeasure, 
        String oldSelectedProductJson 
    ) {
        System.debug('Product ID: ' + productId + ', Plant ID: ' + plantId + ', Unit of Measure: ' + unitOfMeasure);
        
        
        selectedProductWrapper oldSelectedProduct;
        
        if (!String.isBlank(oldSelectedProductJson)) {
            oldSelectedProduct = (selectedProductWrapper)JSON.deserialize(oldSelectedProductJson, selectedProductWrapper.class);
        }
        
        System.debug(oldSelectedProduct);
        
        // Step 1: Get Salesforce Order Type Determination
        List<Salesforce_Order_Type_Determination__c> lstSalesforceOrderTypeDeterminations = [
            SELECT Id, Salesforce_Order_Type__c, Sales_Org__c, Distribution_Channel__c, Division__c, 
            Shipping_Condition__c, Delivery_Block__c, Default_Product__c
            FROM Salesforce_Order_Type_Determination__c
            WHERE Plant_ID__c = :plantId 
            AND Active__c = true
            LIMIT 1
        ];
        
        if (lstSalesforceOrderTypeDeterminations.isEmpty()) {
            throw new AuraHandledException('No Salesforce Order Type Determination found for the given plant.');
        }
        
        Salesforce_Order_Type_Determination__c orderType = lstSalesforceOrderTypeDeterminations[0];
        
        if(orderType.Default_Product__c!=null)
        {
            productId = orderType.Default_Product__c;
        }
        // Step 2: Get Product Sales Data
        //if(orderType.Salesforce_Order_Type__c == 'ZPLS' ){
        List<Product_Sales_Data__c> lstProductSalesData = [
            SELECT Id, Item_Category_Group__c 
            FROM Product_Sales_Data__c
            WHERE Product_ID__c = :productId
            AND Sales_Organization__c = :orderType.Sales_Org__c
            AND Distribution_Channel__c = :orderType.Distribution_Channel__c
            LIMIT 1
        ];
        
         if (lstProductSalesData.isEmpty() && orderType.Salesforce_Order_Type__c == 'ZPLS') {
             throw new AuraHandledException('The data required for the Product Sales Data is not currently maintained. Please contact the Product Maintenance team for support.');
         }
                    Product_Sales_Data__c productSalesData;
            List<SAP_S4_Order_Type_Determination__c> lstS4Determinations = new List<SAP_S4_Order_Type_Determination__c>();
            SAP_S4_Order_Type_Determination__c s4OrderType = new SAP_S4_Order_Type_Determination__c();

            if (lstProductSalesData != null && !lstProductSalesData.isEmpty()) {
                productSalesData = lstProductSalesData[0];

                // Step 3: Get S4 Order Type Determination
                lstS4Determinations = [
                    SELECT Id, S4_Order_Type__c, Item_Category__c
                    FROM SAP_S4_Order_Type_Determination__c
                    WHERE Salesforce_Order_Type__c = :orderType.Salesforce_Order_Type__c
                    AND Item_Category_Group__c = :productSalesData.Item_Category_Group__c 
                    AND Active__c = true
                    LIMIT 1
                ];
                
               if (lstS4Determinations.isEmpty() && orderType.Salesforce_Order_Type__c == 'ZPLS') {
                   throw new AuraHandledException('The data required for the S4 order type is not currently maintained. Please contact the Product Maintenance team for support.');
               } 
            }

            // Safely assign the result
            if (lstS4Determinations != null && !lstS4Determinations.isEmpty()) {
                s4OrderType = lstS4Determinations[0];
            } else {
                s4OrderType.S4_Order_Type__c = null;
                s4OrderType.Item_Category__c = null;
            }

     
        //get Price book Id for the selected Product
        PricebookEntry pricebookEntry = new PricebookEntry();
        if(orderType.Default_Product__c != null){
            pricebookEntry = getPriceBookEntryId(orderType.Default_Product__c);
        }
        else{
             pricebookEntry = getPriceBookEntryId(productId);
        }
        String pricebookEntryId = pricebookEntry.Id;
        String pricebookId = pricebookEntry.Pricebook2Id;
        
        
        // Step 4: Compare with old selection if provided
        selectedProductWrapper newSelection = new selectedProductWrapper(
            orderType.Salesforce_Order_Type__c,
            s4OrderType.S4_Order_Type__c,
            orderType.Shipping_Condition__c,
            orderType.Delivery_Block__c,
            plantId,
            orderType.Sales_Org__c,
            orderType.Distribution_Channel__c,
            orderType.Division__c,
            s4OrderType.Item_Category__c,
            pricebookEntryId,
            pricebookId, 
            orderType.Default_Product__c
        );
        
        //step 5: check the valid UoM
        List<String> lstProduct = new List<String>{productId};
            
            List<String> lstValidUoMs = Syn_UtilityClass.getValidUoMListforProduct(lstProduct)[0].validUoMs;
        
        if (!lstValidUoMs.isEmpty()) {
            
            if (!lstValidUoMs.contains(unitOfMeasure)) {
                // Show error message or throw exception
                throw new AuraHandledException('Selected Unit of Measure is not valid for the selected product, please contact your Product Manager.');
            }
        }
        
        System.debug('newSelection'+' '+newSelection + ' '+oldSelectedProduct);
        if (oldSelectedProduct != null) {
            // Compare all fields
            System.debug('oldSelection'+' '+oldSelectedProduct);
            
            Map<String, Boolean> mismatchMap = new Map<String, Boolean>{
                'Plant'                 => newSelection.plant != oldSelectedProduct.plant,
                'Salesforce Order Type' => newSelection.salesforceOrderType != oldSelectedProduct.salesforceOrderType,
                    'S4 Order Type'         => newSelection.s4OrderType != oldSelectedProduct.s4OrderType,
                    'Shipping Condition'    => newSelection.shippingCondition != oldSelectedProduct.shippingCondition,
                    'Delivery Block'        => newSelection.deliveryBlock != oldSelectedProduct.deliveryBlock
                    
                    };
                        
                        for (String fieldLabel : mismatchMap.keySet()) {
                            if (mismatchMap.get(fieldLabel)) {
                                System.debug(fieldLabel);
                                throw new AuraHandledException(fieldLabel + ' does not match the previously selected product.');
                            }
                        }
        }
        
        return newSelection;
    }
    
    /*************************************************************** 
====================================================== 
Purpose: Wrapper class for product validation
===================================================== 
History: 
AUTHOR     DATE 	    Reference 	     Description 
Vishal S   08/04/2025    SSP-353	    Initial Implementation	 
***************************************************************/
    
    public class selectedProductWrapper {
        @AuraEnabled public String salesforceOrderType;
        @AuraEnabled public String s4OrderType;
        @AuraEnabled public String shippingCondition;
        @AuraEnabled public String deliveryBlock;
        @AuraEnabled public String plant;
        @AuraEnabled public String salesOrg;
        @AuraEnabled public String distributionChannel;
        @AuraEnabled public String division;
        @AuraEnabled public String s4ItemCategory;
        @AuraEnabled public String pricebookEntryId;
        @AuraEnabled public String pricebookId;
        @AuraEnabled public String defaultProduct;
        
        
        
        // Required for deserialization from LWC
        public selectedProductWrapper() {}
        
        public selectedProductWrapper(String salesforceOrderType, String s4OrderType, String shippingCondition, String deliveryBlock, String plant, String salesOrg, String distributionChannel, String division, String s4ItemCategory, String pricebookEntryId, String pricebookId, String defaultProduct ) {
            this.salesforceOrderType = salesforceOrderType;
            this.s4OrderType = s4OrderType;
            this.shippingCondition = shippingCondition;
            this.deliveryBlock = deliveryBlock;
            this.plant = plant;
            this.salesOrg = salesOrg;
            this.distributionChannel = distributionChannel;
            this.division = division;
            this.s4ItemCategory = s4ItemCategory;
            this.pricebookEntryId = pricebookEntryId;
            this.pricebookId = pricebookId;
            this.defaultProduct = defaultProduct;
        }
    }
    
    /*************************************************************** 
====================================================== 
Purpose: To get the product Pricebook Entry ID and the PriceBook Id
===================================================== 
History: 
AUTHOR     DATE 	    Reference 	     Description 
Vishal S   08/04/2025    SSP-353	    Initial Implementation	 
***************************************************************/
    public static PricebookEntry getPriceBookEntryId(String productId)
    {
        List<PricebookEntry> lstPriceBookEntry = [SELECT ID, Pricebook2Id, Product2Id  FROM PricebookEntry WHERE Product2Id = : productId LIMIT 1];
        return lstPriceBookEntry[0];
    }
    
    /*************************************************************** 
====================================================== 
Purpose: If component called from from Order then query the existing order Products
===================================================== 
History: 
AUTHOR     DATE 	    Reference 	     Description 
Vishal S   08/04/2025    SSP-353	    Initial Implementation	 
***************************************************************/
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getOrderItemsFormOrder(Id recordId) {
        System.debug('Record Id: ' + recordId);
        
        if (recordId != null   && recordId.getSObjectType() == Order.sObjectType) {
            System.debug('Inside Order processing block');
            Order order = [SELECT ID, Shipping_Condition__c, Delivery_Block__c FROM Order WHERE Id =: recordId];
            
            List<OrderItem> lstOrderProduct = [
                SELECT Id, Product2Id, Product2.Product_Id__c, Product2.Name, Description, Default_Product_Used__c,
                Product2.Product_Category__r.Name, Quantity, Quantity_UoM__c, Quantity_UoM__r.Name,
                Plant__c, Plant__r.Name, Estimated_Stock__c, 
                Salesforce_Order_Type__c, S4_Order_Type__c, 
                Sales_Organisation__c, 
                Distribution_Channel__c, Division__c, S4_Item_Category__c, 
                Sample_Master_Matrix_Data__c,
                PricebookEntryId, PricebookEntry.Pricebook2Id, 	Sample_Item_Approval_Status__c
                FROM OrderItem
                WHERE OrderId = :recordId
            ];
            
            // Collect unique Matrix IDs
            Set<Id> lstSampleMasterMatrixIds = new Set<Id>();
            for (OrderItem item : lstOrderProduct) {
                if (item.Sample_Master_Matrix_Data__c != null) {
                    lstSampleMasterMatrixIds.add(item.Sample_Master_Matrix_Data__c);
                }
            }
            
            // Map Matrix Data by Id
            Map<Id, Sample_Master_Matrix_Data__c> mapSampleMasterMatrix = new Map<Id, Sample_Master_Matrix_Data__c>();
            if (!lstSampleMasterMatrixIds.isEmpty()) {
                for (Sample_Master_Matrix_Data__c matrix : [
                    SELECT Id, Product__c, Region__c, Min__c, Max__c
                    FROM Sample_Master_Matrix_Data__c
                    WHERE Id IN :lstSampleMasterMatrixIds
                ]) {
                    mapSampleMasterMatrix.put(matrix.Id, matrix);
                }
            }
            
            // Compose the final list
            List<Map<String, Object>> lstOrderProductMap = new List<Map<String, Object>>();
            
            for (OrderItem item : lstOrderProduct) {
                Sample_Master_Matrix_Data__c matrix = 
                    item.Sample_Master_Matrix_Data__c != null 
                    ? mapSampleMasterMatrix.get(item.Sample_Master_Matrix_Data__c) 
                    : null;
                
                lstOrderProductMap.add(new Map<String, Object>{
                    'Id' => matrix?.Id,
                        'productId' => item.Product2Id,
                        'externalProductId' => item.Product2.Product_Id__c,
                        'productName' => item.Product2.Name,
                        'description' => item.Description, 
                        'defaultProductUsed' => item.Default_Product_Used__c,
                        'productCategoryName' => item.Product2.Product_Category__r != null 
                        ? item.Product2.Product_Category__r.Name : null,
                            'possibleQuantity' => item.Quantity,
                            'plantId' => item.Plant__c,
                            'plantName' => item.Plant__r != null ? item.Plant__r.Name : null,
                                'region' => matrix != null ? matrix.Region__c : null,
                                    'minQty' => matrix != null ? matrix.Min__c : null,
                                        'maxQty' => matrix != null ? matrix.Max__c : null,
                                            'estimatedStock' => item.Estimated_Stock__c,
                                            'salesforceOrderType' => item.Salesforce_Order_Type__c,
                                            's4OrderType' => item.S4_Order_Type__c,
                                            'shippingCondition' => order.Shipping_Condition__c,
                                            'deliveryBlock' => order.Delivery_Block__c,
                                            'salesOrg' => item.Sales_Organisation__c,
                                            'distributionChannel' => item.Distribution_Channel__c,
                                            'division' => item.Division__c,
                                            'itemCategory' => item.S4_Item_Category__c,
                                            'pricebookEntryId' => item.PricebookEntryId,
                                            'pricebook2Id' => item.PricebookEntry != null 
                                            ? item.PricebookEntry.Pricebook2Id : null,
                                                'uomId' => item.Quantity_UoM__c,
                                                'uom' => item.Quantity_UoM__r.Name,
                                                'orderProductId' => item.Id,
                                                'approvalStatus' => item.Sample_Item_Approval_Status__c
                                                });
            }
            
            System.debug('Order Product Map: ' + lstOrderProductMap);
            return lstOrderProductMap;
        }
        
        return null;
    }
    

        /*************************************************************** 
====================================================== 
Purpose: If component called from from Order then query the existing order Products
===================================================== 
History: 
AUTHOR     DATE 	    Reference 	     Description 
Vishal S   08/04/2025    SSP-353	    Initial Implementation	 
***************************************************************/
@AuraEnabled(cacheable=true)
public static Name_Value_Pair__mdt getPaginationSize()
{
    Name_Value_Pair__mdt lstPageSize = [SELECT Id, DeveloperName, value__c FROM Name_Value_Pair__mdt WHERE DeveloperName = 'Sample_Prd_Selector_Result_Records_Page' LIMIT 1];
    return lstPageSize;
}
}