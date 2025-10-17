import { LightningElement, api } from 'lwc';

export default class GlobalTestAction extends LightningElement {
    @api recordId; // received from Aura wrapper

    connectedCallback() {
        console.log('Record Id:', this.recordId);
    }
}