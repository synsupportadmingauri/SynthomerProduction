/*************************************************************** 
====================================================== 
Purpose: Update Search Data field of Sample Master Matrix Object
===================================================== 
History: 
AUTHOR     DATE 	    Reference 	     Description 
Vishal S   16/06/2025            	     Initial Implementation	 
***************************************************************/ 
public class Syn_SampleMatrixSearchDataUpdateInvoker {
	@InvocableMethod(label='Run Update Search Data Batch from Flow')
    public static void searchDataUpdateInvocable(List<String> dummyInput) {
        // Trigger the batch job
        Database.executeBatch(new Syn_SampleMatrixSearchDataUpdateBatch(), 200);
    }
}