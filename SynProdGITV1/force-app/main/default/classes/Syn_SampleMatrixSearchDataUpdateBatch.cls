/*************************************************************** 
====================================================== 
Purpose: Update Search Data field of Sample Master Matrix Object
====================================================== 
History: 
AUTHOR     DATE 	         Reference 	         Description 
Vishal S   16/06/2025                         Initial Implementation	 
***************************************************************/ 
public class Syn_SampleMatrixSearchDataUpdateBatch implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([
            SELECT Id,
                   Product__r.Name, 
                   Plant_ID__r.Name, 
                   Product_Category_ID__r.Name, 
                   Region__c,
                   Approver__r.FirstName,
                   Approver__r.LastName,
            Product__r.Product_Id__c, Plant_ID__r.Plant_ID__c,
                   Search_Data__c
            FROM Sample_Master_Matrix_Data__c
        ]);
    }

    public void execute(Database.BatchableContext context, List<Sample_Master_Matrix_Data__c> sampleMatrixData) {
        for (Sample_Master_Matrix_Data__c record : sampleMatrixData) {
            List<String> parts = new List<String>();

            if (record.Product__r != null && String.isNotBlank(record.Product__r.Product_Id__c)) 
                parts.add(record.Product__r.Product_Id__c);

            
            
            if (record.Product__r != null && String.isNotBlank(record.Product__r.Name)) 
                parts.add(record.Product__r.Name);

             if (record.Plant_ID__r != null && String.isNotBlank(record.Plant_ID__r.Plant_ID__c)) 
                parts.add(record.Plant_ID__r.Plant_ID__c);
            
            if (record.Plant_ID__r != null && String.isNotBlank(record.Plant_ID__r.Name)) 
                parts.add(record.Plant_ID__r.Name);
            


            if (record.Product_Category_ID__r != null && String.isNotBlank(record.Product_Category_ID__r.Name)) 
                parts.add(record.Product_Category_ID__r.Name);

            if (String.isNotBlank(record.Region__c)) 
                parts.add(record.Region__c);

            if (record.Approver__r != null) {
                String fullName = '';
                if (String.isNotBlank(record.Approver__r.FirstName)) 
                    fullName += record.Approver__r.FirstName + ' ';
                if (String.isNotBlank(record.Approver__r.LastName)) 
                    fullName += record.Approver__r.LastName;
                if (String.isNotBlank(fullName)) 
                    parts.add(fullName.trim());
            }

            String concatenated = String.join(parts, ' -> ');
            if (record.Search_Data__c != concatenated) {
                record.Search_Data__c = concatenated;
            }
        }

        update sampleMatrixData;
    }

    public void finish(Database.BatchableContext context) {
        System.debug('Batch process for Search_Data__c completed.');
    }
}