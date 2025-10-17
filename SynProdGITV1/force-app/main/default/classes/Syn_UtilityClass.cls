/********************************************************************************************************************** 
Purpose: Class for Apex Utilities  
====================================================================================================================== 
History: 
AUTHOR         		DATE       Reference        Description 
Kamlesh / Boyai   31/03/2025             Initial Implementation  
**********************************************************************************************************************/
public with sharing class Syn_UtilityClass {
    private static final String AAAADL_DIMENSION = 'AAAADL';
    
    /***************************************************************************************************************** 
    Purpose: Retrieves a list of valid Unit of Measure(UoM_Std_Data__c) Ids valid for input list of product Ids.  
    Parameters:- lstProductId List(String): A list of product2 record ids.  
    Returns: - List<OutoutUOM>: List containing of product id and its valid list UoM Id(UoM_Std_Data__c).  
    ================================================================================================================== 
    History: 
    AUTHOR   	         DATE       Reference        Description 
    Kamlesh / Boyai   31/03/2025             Initial Implementation  
    *****************************************************************************************************************/
    @InvocableMethod(Label='Get UoMs' Description='Returns list of valid UoM for a given product id')
    public static List<Syn_UtilityClass.OutputUoM> getValidUoMListforProduct(List<String> lstProductId) {
        Map<String, Set<String>> mapProdToUoMs = New Map<String, Set<String>>(); 
        Map<String, Set<String>> mapProdToDimension = New Map<String, Set<String>>();
        List<String> lstOfValidUoM;
        List<Syn_UtilityClass.OutputUoM> result = new list<Syn_UtilityClass.OutputUoM>();       
        
        Try{
            // Validate input
            if (lstProductId.isEmpty()) {
                throw new IllegalArgumentException('Product Id cannot be null or empty.');
             }
			
            //Step 1: For each product get the standard Base UOM and keep it in a map
            Set<String> setOfValidUOM;
            Set<String> setOfDimension;
            Set<String> setOfAllDimension =  New Set<String>();
            For(Product2 recProduct : [SELECT Id, Base_UoM__c, Base_UoM__r.Dimension__c FROM Product2 WHERE Id in : lstProductId]){
                setOfValidUOM = New Set<String>();
                setOfValidUOM.add(recProduct.Base_UoM__c);
                mapProdToUoMs.put(recProduct.id, setOfValidUOM);
                setOfDimension = New Set<String>();
                setOfDimension.add(recProduct.Base_UoM__r?.Dimension__c);
                mapProdToDimension.put(recProduct.id, setOfDimension);
                setOfAllDimension.add(recProduct.Base_UoM__r?.Dimension__c);
            }
           
            setOfDimension = New Set<String>();
            //Step 2: Now for each product get the Alternate UoM (along with its Dimension) and add it to the map against the product id
            For(Product_Conversions_Data__c objProductConversion : [SELECT Alternative_Unit__c, Product__c, Alternative_Unit__r.Dimension__c FROM Product_Conversions_Data__c 
                                                                    WHERE Product__c in :mapProdToUoMs.keyset() ]){
                 If (objProductConversion.Alternative_Unit__c != null) {
                      mapProdToUoMs.get(objProductConversion.product__c).add(objProductConversion.Alternative_Unit__c); 
                      mapProdToDimension.get(objProductConversion.product__c).add(objProductConversion.Alternative_Unit__r.Dimension__c);
                      setOfAllDimension.add(objProductConversion.Alternative_Unit__r.Dimension__c);
                 }
            }         
            
            //Step 3: Get all units which are related to the dimension
            Set<String> setDimensionUoM = New Set<String>();
            Map<String, Set<String>> mapDimensionToUoMs = New Map<String, Set<String>>();
            String curDimension = '';
            String prevDimension = '';
            //get all UoMs and form a map of dimension to UoMs
            For(UoM_Std_Data__c UoMData : [SELECT Id, Dimension__c FROM UoM_Std_Data__c WHERE Dimension__c In :setOfAllDimension AND Dimension__c != :AAAADL_DIMENSION Order by Dimension__c]){
                curDimension = UoMData.Dimension__c;
                
                If(curDimension != prevDimension && prevDimension != ''){
                	mapDimensionToUoMs.put(prevDimension, setDimensionUoM);
                    setDimensionUoM = New Set<String>();
                }
                
				setDimensionUoM.add(UoMData.Id);
                prevDimension = curDimension;
            }
            
            //add the last one in the list
            mapDimensionToUoMs.put(prevDimension, setDimensionUoM);
            
            //Step 4: Finally add the dimension based additional
            //for each product get the list of dimensions collated earlier and add the UoM for each dimension
            For(String productId : mapProdToUoMs.keyset()){
                For(String varDimension : mapProdToDimension.get(productId)){
                    If(mapDimensionToUoMs.get(varDimension) != Null){
                    	mapProdToUoMs.get(productId).addAll(mapDimensionToUoMs.get(varDimension));    
                    }  
                }
            }
            
            //Step 5: Form the output based on the extracted data
            Syn_UtilityClass.OutputUoM objOutputUoM;
            
            For(String prodId : mapProdToUoMs.keyset()){
                if (mapProdToUoMs.get(prodId) != null) {
                    lstOfValidUoM = new List<String>(mapProdToUoMs.get(prodId));
                    objOutputUoM = New Syn_UtilityClass.OutputUoM(prodId, lstOfValidUoM);
                    result.add(objOutputUoM);                
                }
            }
        }
        Catch(Exception ex){
            System.debug(ex.getStackTraceString());
            System.debug(ex.getMessage());
            System.debug(ex.getLineNumber());
            LoggingFramework.CreateLog('Error', ex.getMessage(), '', '', 'getValidUoMListforProduct', 'Syn_UtilityClass', ex.getStackTraceString());
        }
        
        return result;
    }
    
    //Apex defined type for output
	public class OutputUoM 
    {   
        public OutputUoM(String prodId, List<String> UoMs)
        {
            productId = prodId;
            validUoMs = UoMs;
        }
        @InvocableVariable
        public String productId;
        @InvocableVariable
        public List<String> validUoMs;
    }
}