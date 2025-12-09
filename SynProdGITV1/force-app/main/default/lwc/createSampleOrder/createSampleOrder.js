import { LightningElement, api, wire, track } from 'lwc';
//import getOpportunityDetails from '@salesforce/apex/OpportunityController.getOpportunityDetails';
import getRecordDetails from '@salesforce/apex/Syn_CreateOrderController.getRecordDetails';
import getAccountDetails from '@salesforce/apex/Syn_CreateOrderController.getAccountDetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from "lightning/actions";
import { getRecord } from "lightning/uiRecordApi";
import { loadStyle } from 'lightning/platformResourceLoader';
import modal80width from '@salesforce/resourceUrl/modal80width';
import createSampleOrder from '@salesforce/label/c.Create_Sample_Order';
import createSampleOrderHelpText from '@salesforce/label/c.Create_Sample_Order_Help_Text'
//import insertOrderProducts from '@salesforce/apex/Syn_CreateOrderController.insertOrderProducts';
import createOrderWithProducts from '@salesforce/apex/Syn_CreateOrderController.createOrderWithProducts';
import getEvaluatedSoldToParty from '@salesforce/apex/Syn_CreateOrderController.getEvaluatedSoldToParty';
import getOpportunitiesByAccount from 	'@salesforce/apex/Syn_CreateOrderController.getOpportunitiesByAccount';
import validateShipToContact from '@salesforce/apex/Syn_CreateOrderController.validateShipToContact';
import getNonS4OrderCurrency from '@salesforce/apex/Syn_CreateOrderController.getNonS4OrderCurrency';
const FIELDS = ["Order.OrderNumber"];
import isPartnerUser from '@salesforce/apex/Syn_CreateOrderController.isPartnerUser';
import partnerAccount from '@salesforce/apex/Syn_CreateOrderController.partnerAccountId';

export default class CreateSampleOrder extends NavigationMixin(LightningElement) {
    @api recordId;  // The record ID passed from the page context
    
    opportunityId;
    accountId;
    contactId;
    shipToAccount;
    errorMessage;
    newOrderId;
    selectedProducts = []; // To store selected products

    isOrderCreationVisible = true;
    isProductSelectorVisible = false;
    currencyIsoCode;
    isShipToContactRelated = true;

    @track opportunityOptions = [];
    isSubmitting = false;
    @track accountRegion;

    label = {
        createSampleOrder,
        createSampleOrderHelpText
    };

    @track isPartnerUser = false; 
    //recordId = '001dv000009tfYRAAY';
    PartnerAccountId = '';
    @track endCustomer = '';
    @track potentialVolume = '';
    @track application = '';
    @track orderName = '';              // SD1-T64+ 03/10/2025 Ankur O 

    connectedCallback() {
        isPartnerUser()
        .then(result => {
            this.isPartnerUser = result;
            consile.log('Under isPartnerUser');
            

        })
        .catch(error => {
            console.error(error);
        });

        if(isPartnerUser){
            partnerAccount()
            .then(result => {
            if (this.recordId == null){
              this.recordId = result;
            }

            if (this.accountId == null){
              this.accountId = result;
            }

           // this.recordId = result;
           // this.accountId = result;
            console.log(' 72 Under isPartnerUser');
            console.log('Account Id is '+ this.accountId);
            console.log('Record Id is '+ this.recordId);

        })
        .catch(error => {
            console.error(error);
        });
        }

        loadStyle(this, modal80width)
            .then(() => {
                console.log('Custom CSS loaded successfully');
                console.log('47 Under connectedCallback');
            })
            .catch(error => {
                console.error('Error loading custom CSS:', error);
            });
        this.isSubmitting = true;
    }
    // we Use this method to get the Opportunity and Account details Related to recordId so we can prepopulate the values
    @wire(getRecordDetails, { recordId: '$recordId' })
    opportunityData({ error, data }) {
        console.log('89 Under opportunityData');
        console.log('90 error => ' + error);
        console.log('91 data => ' + data);
        console.log(JSON.stringify(data)); 

        if (data) {
            if (data.errorMessage) {

                this.errorMessage = data.errorMessage;
                console.log('Data Error' + this.errorMessage);

            } else {
                console.log('Data ' +  data);
                this.opportunityId = data.opportunityId;
                this.accountId = data.accountId;
                console.log('Account id is '+ this.accountId);
                this.contactId = data.contactId;
                this.shipToAccount = data.shipToAccountId;
                console.log('Ship to Account data '+ this.shipToAccount);
                this.errorMessage = null;
            }
        } else if (error) {
            this.errorMessage = 'Error fetching Opportunity details.';
            console.error(error);
        }
    }

    
 
    // // Handle Opportunity selection
    handleOpportunityChange(event) {
        console.log('83 Under handleopportunity');
        this.opportunityId = event.target.value;
    }

    // Fetch opportunities for the combobox
    @wire(getOpportunitiesByAccount, { accountId: '$accountId' })
    wiredOpportunities({ error, data }) {
        console.log('90 Under wiredOpportunities');
        if (data) {
            this.opportunityOptions = data.map(opp => ({
                label: opp.Name,
                value: opp.Id
            }));
            // If opportunityId was prepopulated, ensure it’s still valid
            if (this.opportunityId && !data.some(opp => opp.Id === this.opportunityId)) {
                this.opportunityId = null; // Reset if invalid
            }
        } else if (error) {
            this.errorMessage = 'Error fetching opportunities.';
            console.error(error);
            this.opportunityOptions = [];
        }
     }

    // Handle the change event from the lightning-input-field
    handleFieldChange(event) {
        console.log('109 Under handleFieldChange');
        // to get the new value
        if (event.target.name === 'AccountId') {
            this.accountId = event.target.value;
        }  else if (event.target.name === 'ShipToContactId') {
            this.contactId = event.target.value;
            this.validateContact();
        } else if(event.target.name === 'Ship_To_Account__c'){
            this.shipToAccount = event.target.value;
        } else if(event.target.name === 'End_Customer__c') {
            this.endCustomer = event.target.value;
        } else if(event.target.name === 'Potential_Volume1__c') {
            this.potentialVolume = event.target.value;
        } else if(event.target.name === 'Application__c') {
            this.application = event.target.value;
        } else if(event.target.name === 'Name') {                               // SD1-T64+ 03/10/2025 Ankur O 
            this.orderName = event.target.value;
        }
    }

//Check for Ship to contact is related to the Account and is Active, if not then throw a warning message
validateContact() {
    console.log('123 Under validateContact');
    if (this.contactId  && this.accountId) {
        validateShipToContact({
            contactId: this.contactId,
            accountId: this.accountId
        })
        .then(result => {
            if (!result) {
                this.isShipToContactRelated = false;
                console.log(this.isShipToContactRelated);
                this.showToast(
                    'Warning',
                    'The selected Ship To Contact is not related to the Account',
                    'warning'
                );
            }
        })
        .catch(error => {
            console.error('Validation error:', error);
            this.showToast(
                'Error',
                'An error occurred while validating the contact.',
                'error'
            );
        });
    }
}
    
    handleKeyDown(event) {
        console.log('152 Under handleKeyDown');
        if (event.key === 'Enter') {
            event.preventDefault(); // Prevent default Enter behavior
        }
    }
    
    //handle the Submit Order with Order Items
    async handleSubmit(event) {
        console.log('Under handleSubmit => ' + this.accountId);
        console.log('206 Under handleSubmit');
        console.log('207 => endCustomer => ' + this.endCustomer + '  potentialVolume => ' + this.potentialVolume + ' application => ' + this.application );
        
        
        event.preventDefault();
            if (this.isSubmitting) {
            return;
        }
        this.isSubmitting = true;

        // Check if selected products are empty or invalid
        if (
            !Array.isArray(this.selectedProducts) || 
            this.selectedProducts.length === 0 || 
            !this.selectedProducts[0].tickedProducts
        ) {
            this.showToast('Error', 'Please select at least one product before creating the order.', 'error');
            return; // Prevent form submission
        }

        //check if the selected product is default product and its name is changed
        const invalidProducts = this.selectedProducts.filter(product => 
        product.isDefaultProduct && (product.productName.includes('<') || product.productName.includes('>') || !product.productName )
        );
        if (invalidProducts.length > 0) {
            // Show an error to the user
            this.showToast('Error', 'The name should be changed for the Lab Sample products.', 'error');
            return; // Stop order submission
        }
        
        console.log('Submitting order...');
        
        const fields = event.detail.fields;
        let evaluatedSoldToParty;

        fields.EffectiveDate = new Date().toISOString().split('T')[0];
        fields.Status = 'Draft';
        
        let accountIds = [];
        
        fields.AccountId = this.accountId;
        fields.Ship_To_Account__c = this.shipToAccount;
        fields.OpportunityId = this.opportunityId;
        fields.ShipToContactId = this.contactId;
        fields.isShipToContactRelated = this.isShipToContactRelated;

        fields.End_Customer__c = this.endCustomer;
        fields.Potential_Volume1__c = this.potentialVolume;
        fields.Application__c = this.application;
        fields.Name = this.orderName;                                                       // SD1-T64+ 03/10/2025 Ankur O                  

        //passing the account Id's to get the Billing and Shipping Address
        if(fields.AccountId) accountIds.push(fields.AccountId);
        if(fields.Ship_To_Account__c) accountIds.push(fields.Ship_To_Account__c);
        const accountMap = await getAccountDetails({ accountIdList : accountIds });
        // Set Billing and Shipping Addresses
        const account = accountMap[fields.AccountId];
        if (account) {
            fields.BillingStreet = account.BillingStreet;
            fields.BillingCity = account.BillingCity;
            fields.BillingState = account.BillingState;
            fields.BillingPostalCode = account.BillingPostalCode;
            fields.BillingCountry = account.BillingCountry;
        }

       const shipAccount = accountMap[fields.Ship_To_Account__c || fields.AccountId];
        if (shipAccount) {
            
            //check if shipping country is null for prospect Account
            if(shipAccount.ShippingCountry){
                fields.ShippingCountry = shipAccount.ShippingCountry;
                fields.ShippingStreet = shipAccount.ShippingStreet;
                fields.ShippingCity = shipAccount.ShippingCity;
                fields.ShippingState = shipAccount.ShippingState;
                fields.ShippingPostalCode = shipAccount.ShippingPostalCode;
            } else{
                fields.ShippingCountry = shipAccount.BillingCountry;
                fields.ShippingStreet = shipAccount.BillingStreet;
                fields.ShippingCity = shipAccount.BillingCity;
                fields.ShippingState = shipAccount.BillingState;
                fields.ShippingPostalCode = shipAccount.BillingPostalCode;
            }

             // Update the currency based on shipping account/ Account 
            fields.CurrencyIsoCode = shipAccount.CurrencyIsoCode;
            this.currencyIsoCode = fields.CurrencyIsoCode;
        }

        // Evaluate the Sold to Party & get Order currency
         try {
            console.log('279 Under Evaluate the Sold to Party & get Order currency => ' + fields.AccountId);
            console.log('280 salesforce orderType => ' + this.selectedProducts[0].tickedProducts.salesforceOrderType);
            console.log('281 PlantId => ' + this.selectedProducts[0].plantId);
            console.log('282 shipping country => ' + fields.ShippingCountry);

          if(this.selectedProducts[0].tickedProducts.salesforceOrderType == 'ZPLS'){
            const plantId = this.selectedProducts[0].plantId || '';
            const shippingCountry = fields.ShippingCountry || '';
            const evaluatedResult =  await getEvaluatedSoldToParty({
                accountId: fields.AccountId,
                plantId,
                shippingCountry
            });
            console.log('292');

            //Begin of for INC. 164768 - 21/07/2025 - Vishal S 
            //if(evaluatedResult.evaluatedSoldToParty != fields.AccountId && this.selectedProducts[0].tickedProducts.s4OrderType == 'ZBFD') {
            //  this.showToast('Error', 'Sample Product cannot be select for selected Account, please ask "CSR team" to create Sample order directly in S4', 'error');
            //   return;
            //}
            //End of for INC. 164768 - 21/07/2025 - Vishal S 

            // If Evaluated Sold to party found update the fields
            if (evaluatedResult) {
                fields.Evaluated_Sold_To_Party__c	 = evaluatedResult.evaluatedSoldToParty;
                fields.IncoTerms__c = evaluatedResult.incoterms;
                fields.Payment_Terms__c = evaluatedResult.paymentTerm;
                fields.IncoTerms_Location__c = evaluatedResult.incotermLocation;

                // Update the currency based on sold to party
                fields.CurrencyIsoCode = evaluatedResult.currencyIsoCode;
                this.currencyIsoCode = evaluatedResult.currencyIsoCode;
            }
        }else{
            const plantId = this.selectedProducts[0].plantId || '';
            const result = await getNonS4OrderCurrency({ accountId: fields.AccountId, plantId });
            //console.log('result:', result);
            this.currencyIsoCode = result;
            fields.CurrencyIsoCode = this.currencyIsoCode;
            console.log('currency in non zpls:', this.currencyIsoCode);
        }
        } catch (err) {
            console.error('Error in getEvaluatedSoldToParty:', err);
            this.showToast('Error', 'Failed to evaluate Sold-To Party data.', 'error');
            this.isSubmitting = false;
            return;
        }
     
        // Assigning the order fields based on the selected products
        if (Array.isArray(this.selectedProducts) &&
        this.selectedProducts.length > 0 &&
        this.selectedProducts[0] &&
        this.selectedProducts[0].tickedProducts){
        
        fields.Pricebook2Id = this.selectedProducts[0].tickedProducts.pricebookId;
        fields.Plant__c = this.selectedProducts[0].plantId || null;
        fields.Sales_Orgnization__c = this.selectedProducts[0].tickedProducts.salesOrg;
        fields.Delivery_Block__c = this.selectedProducts[0].tickedProducts.deliveryBlock;
        fields.Distribution_Channel__c = this.selectedProducts[0].tickedProducts.distributionChannel;
        fields.S4_Order_Type__c = this.selectedProducts[0].tickedProducts.s4OrderType;
        fields.Salesforce_Order_Type__c = this.selectedProducts[0].tickedProducts.salesforceOrderType;
        fields.Division__c = this.selectedProducts[0].tickedProducts.division;
        fields.Shipping_Condition__c = this.selectedProducts[0].tickedProducts.shippingCondition;
      
        }
        
        // Order product map assignment
         const formattedProducts = this.selectedProducts.map(product => ({
            Id: product.Id,
            productId: product.productId,
            quantity: product.quantity,
            unitPrice: product.unitPrice || 0,
            totalPrice: product.totalPrce || 0,
            description: product.productName,
            plantId: product.plantId,
            uomId: product.Unit,
            pricebookEntryId: product.tickedProducts.pricebookEntryId,
            SalesforceOrderType: product.tickedProducts.salesforceOrderType,
            s4OrderType: product.tickedProducts.s4OrderType,
            itemCategory: product.tickedProducts.s4ItemCategory,
            salesOrg: product.tickedProducts.salesOrg,
            distributionChannel: product.tickedProducts.distributionChannel,
            division: product.tickedProducts.division,
            stockLevel: product.stockLevel,
            shippingDate: product.shippingDate,
            defaultProductUsed: product.isDefaultProduct,
            currencyIsoCode: this.currencyIsoCode,
            pricebook2Id: product.tickedProducts.pricebookId
        }));

        console.log(fields);
        // this.showToast('Info', 'Order Creating...', 'info'); // 🔔 Show toast
        // Apex call
        createOrderWithProducts({
            orderFields: fields,
            orderProducts: formattedProducts
        })
        .then(orderId => {
            this.showToast('Success', 'Order created successfully.', 'success');
            this.dispatchEvent(new CloseActionScreenEvent());

            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: orderId,
                    objectApiName: 'Order',
                    actionName: 'view'
                }
            });
        })
        .catch(error => {
               console.error('Order item insert error:', JSON.stringify(error));

        let message = 'Unknown error occurred.';

        if (error?.body?.message) {
            message = error.body.message;
        } else if (error?.message) {
            message = error.message;
        } else if (typeof error === 'string') {
            message = error;
        }

        this.showToast('Error', message, 'error');
        this.isSubmitting = false; // Re-enable button on failure
            });
    }


    

    handleSuccess(event) {
        console.log('368 under handleSuccess');
        console.log('Success', event);
        this.newOrderId = event.detail.id;
    }
    

    handleError(event) {
        console.log('Eroror', event);
    }

    showToast(title, message, variant, messageData) {
        console.log('379 Under Toast');
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant,messageData }),
        );
    }

    
    @wire(getRecord, { recordId: "$newOrderId", fields: FIELDS })
    wiredRecord({ error, data }) {
        console.log('388 under wiredRecord');
        if (data) {
            this.showToast('Success', 'Order {0} is Successfully Created', 'success', [ data.fields.OrderNumber.value ]);
        } 
    }

    // product selector visibility logic and passing the region to product selector 
    async showProductSelector() {
        console.log('396 under showProductSelector');

        if (this.isPartnerUser && 
        ((!this.endCustomer || this.endCustomer.trim() === '') || (!this.potentialVolume || this.potentialVolume.trim() === '') || (!this.application || this.application.trim() === ''))) {
        this.showToast('Error', 'Required fields cannot be empty.', 'error');
        return; // Stop form submission
        }

        this.isOrderCreationVisible = false;
        this.isProductSelectorVisible = true;

        

        let accountIds = [];
        if (this.accountId) accountIds.push(this.accountId);
        if (this.shipToAccount) accountIds.push(this.shipToAccount);

        const accountMap = await getAccountDetails({ accountIdList: accountIds });

        const shipAccount = accountMap[this.shipToAccount || this.accountId];
        if (shipAccount) {
            this.accountRegion = shipAccount.Region__c; // This gets passed to the child
            console.log('in parent '+ this.accountRegion);
        }
    }

    hideProductSelector() {
        this.isOrderCreationVisible = true;;
        this.isProductSelectorVisible = false;
    }

     // This method will catch the custom event from the child
     handleSelectedProductsChange(event) {
        // Get selected products from the event detail
        this.selectedProducts = event.detail.selectedProducts;
        console.log('Received selected products from child:', JSON.stringify(this.selectedProducts));
        this.isSubmitting = false;

        // If there are no selected products, show error message
        if (this.selectedProducts.length === 0) {
            this.isSubmitting = true;
        }


    }

}