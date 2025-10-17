import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadStyle } from 'lightning/platformResourceLoader';
import modal80width from '@salesforce/resourceUrl/modal80width';
import { CloseActionScreenEvent } from 'lightning/actions';
import updateOrderProducts from '@salesforce/apex/Syn_UpdateOrderProductsController.updateOrderProducts';
import { NavigationMixin } from 'lightning/navigation';
import { RefreshEvent } from 'lightning/refresh';
import isPartnerUser from '@salesforce/apex/Syn_UpdateOrderProductsController.isPartnerUser';
import partnerAccount from '@salesforce/apex/Syn_UpdateOrderProductsController.getAccountRegion';

export default class UpdateOrderProducts2 extends NavigationMixin(LightningElement) {
    @api recordId;
    @track showModal = true;
    @track selectedProducts = [];
    @track isUpdateButtonDisabled = false;
    @track isPartnerUser = false; 
    @track accountRegion;
    accountId;
    

    connectedCallback() {
        isPartnerUser()
        .then(result => {
            this.isPartnerUser = result;
            console.log('Under isPartnerUser');
            console.log('Under isPartnerUser'+this.isPartnerUser);

        })
        .catch(error => {
            console.error(error);
        });

        if(isPartnerUser){
            partnerAccount()
            .then(result => {
            if (this.accountRegion == null){
              this.accountRegion = result;
              console.log('account Region is '+  this.accountRegion);
            }

        })
        .catch(error => {
            console.error(error);
        });
        }

        this.showModal = true;
        loadStyle(this, modal80width)
            .then(() => console.log('modal style loaded'))
            .catch(error => console.error('Failed to load modal CSS:', error));

        console.log('recordId: '+ this.recordId);
    }

    renderedCallback() {
        console.log('Record ID:', this.recordId);
    }

    // get trigger by child if any change in selected product list
    handleSelectedProductsChange(event) {
        this.selectedProducts = event.detail.selectedProducts;
        this.isUpdateButtonDisabled = false; 
    }

    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    //add, delete or update the selected product
    handleUpdateProducts() {
        console.log('Updating products:', JSON.stringify(this.selectedProducts));
        const invalidProducts = this.selectedProducts.filter(product => 
        product.isDefaultProduct && (product.productName.includes('<') || product.productName.includes('>') || !product.productName )
        );

        if (invalidProducts.length > 0) {
            // Show an error to the user
            this.showToast('Error', 'The name should be changed for the Lab Sample products.', 'error');
            return; // Stop order submission
        }
        this.isUpdateButtonDisabled = true; 

        const formattedProducts = this.selectedProducts.map(product => ({
            Id: product.Id,
            productId: product.productId,
            quantity: product.quantity || null,
            unitPrice: product.unitPrice || 0,
            totalPrice: product.totalPrice || 0,
            description: product.productName || null,
            plantId: product.plantId || null,
            uomId: product.Unit || null,
            pricebookEntryId: product.tickedProducts?.pricebookEntryId || null,
            SalesforceOrderType: product.tickedProducts?.salesforceOrderType || null,
            s4OrderType: product.tickedProducts?.s4OrderType || null,
            itemCategory: product.tickedProducts?.s4ItemCategory || null,
            salesOrg: product.tickedProducts?.salesOrg || null,
            distributionChannel: product.tickedProducts?.distributionChannel || null,
            division: product.tickedProducts?.division || null,
            stockLevel: product.stockLevel || null,
            shippingDate: product.shippingDate || null,
            isDefaultProduct : product.isDefaultProduct,
            shippingCondition : product.tickedProducts?.shippingCondition || null,
            deliveryBlock : product.tickedProducts?.deliveryBlock || null

        }));

        // this.showToast('Info', 'Updating Order Products...', 'info'); // 🔔 Show toast

        updateOrderProducts({ 
            orderId: this.recordId, 
            orderProduct: formattedProducts 
        })
        .then((wasUpdated) => {
        if (wasUpdated) {
            this.showToast('Success', 'Products updated!', 'success');
        } else {
            this.showToast('Info', 'Products were not updated.', 'info');
        }

            // Dispatch refresh event to update record page
            this.dispatchEvent(new RefreshEvent());
            this.dispatchEvent(new CloseActionScreenEvent());

            // Wait a moment to ensure the modal has closed
            setTimeout(() => {
                // Refresh the current page to update related lists
                this.refreshCurrentPage();
            }, 300);

        })
        .catch(error => {
            console.error('Update failed:', error);

            let errorMessage = 'Failed to update products';

            // Check for AuraHandledException message
            if (error?.body?.message) {
                errorMessage = error.body.message;
            }

            this.showToast('Error', errorMessage, 'error');
                });
        }

    refreshCurrentPage() {
        // Get current page reference
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view'
            }
        });
    }

    showToast(title, message, variant) {
    this.dispatchEvent(
        new ShowToastEvent({
            title,
            message,
            variant
        })
    );
}


}