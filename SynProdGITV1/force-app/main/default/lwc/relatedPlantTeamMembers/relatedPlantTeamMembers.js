import { LightningElement, api, track } from 'lwc';
import getPlantTeamMembers from '@salesforce/apex/Syn_RelatedPlantTeamController.getPlantTeamMembers';

export default class RelatedPlantTeamMembersFromOrder extends LightningElement {
    @api recordId;
    @track teamMembers = [];
    @track pageMembers = [];

    pageSize = 2;
    pageIndex = 0;
    isViewAll = false; // false = paginated mode, true = view all

    columns = [
    { label: 'Sr. no', fieldName: 'Number', type: 'number', initialWidth: 50 },
    { 
        label: 'Name', 
        fieldName: 'recordLink',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'Name' },
            target: '_blank'
        },
        wrapText: true
    },
    { label: 'Role', fieldName: 'Role__c', type: 'text', wrapText: true },
];

    connectedCallback() {
        this.loadTeamMembers();
    }

    loadTeamMembers() {
        getPlantTeamMembers({ orderId: this.recordId })
            .then(data => {
                this.teamMembers = (data || []).map(rec => {
                    const userName = rec.User__r?.Name;
                    const employeeName = rec.Employee__r?.Name;
                    const displayName = userName || employeeName || '';

                    return {
                        Id: rec.Id,
                        Name: displayName,
                        recordLink: `/lightning/r/${rec.Id}/view`, // Creates clickable link
                        Role__c: rec.Role__c || ''
                    };
                });
                this.pageIndex = 0;
                this.isViewAll = false;
                this.updatePageMembers();
            })
            .catch(error => {
                console.error('Error fetching plant team members:', error);
                this.teamMembers = [];
                this.pageMembers = [];
            });
    }

    updatePageMembers() {
        if (this.isViewAll) {
            this.pageMembers = this.teamMembers.map((record, index) => ({
                ...record,
                Number: index + 1
            }));
        } else {
            const start = this.pageIndex * this.pageSize;
            const end = start + this.pageSize;
            this.pageMembers = this.teamMembers.slice(start, end).map((record, index) => ({
                ...record,
                Number: start + index + 1
            }));
        }
    }

    handleNext() {
        if (this.isViewAll) return;
        const nextStart = (this.pageIndex + 1) * this.pageSize;
        if (nextStart < this.teamMembers.length) {
            this.pageIndex++;
            this.updatePageMembers();
        }
    }

    handlePrevious() {
        if (this.isViewAll) return;
        if (this.pageIndex > 0) {
            this.pageIndex--;
            this.updatePageMembers();
        }
    }

    handleViewAll() {
        this.isViewAll = true;
        this.updatePageMembers();
    }

    handleViewLess() {
        this.isViewAll = false;
        this.pageIndex = 0;
        this.updatePageMembers();
    }

    get pageNumber() {
        return this.isViewAll ? 1 : this.pageIndex + 1;
    }

    get totalPages() {
        if (this.isViewAll) return 1;
        return Math.ceil(this.teamMembers.length / this.pageSize) || 1;
    }

    get showPrevious() {
        return !this.isViewAll && this.pageIndex > 0;
    }

    get showNext() {
        const total = this.teamMembers.length;
        return !this.isViewAll && ((this.pageIndex + 1) * this.pageSize < total);
    }

    get showViewAll() {
        return !this.isViewAll && this.teamMembers.length > this.pageSize;
    }

    get showViewLess() {
        return this.isViewAll && this.teamMembers.length > this.pageSize;
    }

    get hasMembers() {
        return this.teamMembers && this.teamMembers.length > 0;
    }
}