import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getParentId from '@salesforce/apex/Syn_EventController.getParentId';

export default class RedirectToParentChatter extends NavigationMixin(LightningElement) {
    @api recordId;
    @track isLoading = true;

    connectedCallback() {
        console.log('recordId:', this.recordId);
        if (this.recordId) {
            this.fetchAndRedirect();
        } else {
            this.isLoading = false;
        }
    }

    fetchAndRedirect() {
        getParentId({ eventId: this.recordId })
            .then(parentId => {
                console.log('Fetched parentId:', parentId);
                this.isLoading = false;
                if (parentId) {
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: parentId,
                            objectApiName: 'Event',
                            actionName: 'view'
                        }
                    });
                }
            })
            .catch(error => {
                console.error('Error fetching parentId:', error);
                this.isLoading = false;
            });
    }
}