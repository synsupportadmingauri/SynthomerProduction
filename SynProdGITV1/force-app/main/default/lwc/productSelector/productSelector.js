import { LightningElement, track, wire, api } from 'lwc';
import searchProducts from '@salesforce/apex/Syn_ProductSelectorController.searchProducts';
import searchCategories from '@salesforce/apex/Syn_ProductSelectorController.searchCategories';
import searchProductNames from '@salesforce/apex/Syn_ProductSelectorController.searchProductNames';
import searchUoM from '@salesforce/apex/Syn_ProductSelectorController.searchUoM';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import validateTickedProducts from '@salesforce/apex/Syn_ProductSelectorController.validateTickedProducts'
import sampleProductSelectorLabel from '@salesforce/label/c.Sample_Product_Selector';
import sampleProductNameLabel from '@salesforce/label/c.Sample_Product_Name';
import productCategoryLabel from '@salesforce/label/c.Product_Category';
import requiredQuantityHelpText from '@salesforce/label/c.Required_Quantity_Help_Text';
import regionLabel from '@salesforce/label/c.Region';
import unitOfMeasureLabel from '@salesforce/label/c.Unit_of_Measure';
import requiredQuantityLabel from '@salesforce/label/c.Required_Quantity';
import productNameHelpText from '@salesforce/label/c.Product_Name_Help_Text';
import productCategoryHelpText from '@salesforce/label/c.Product_Category_Help_Text';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import RegionField from '@salesforce/schema/Sample_Master_Matrix_Data__c.Region__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import sampleMasterMatrixDataObject from '@salesforce/schema/Sample_Master_Matrix_Data__c';
import getOrderItemsFormOrder from '@salesforce/apex/Syn_ProductSelectorController.getOrderItemsFormOrder';
import {
    registerRefreshHandler,
    unregisterRefreshHandler
} from 'lightning/refresh';
import { refreshApex } from '@salesforce/apex';
import getPaginationSize from '@salesforce/apex/Syn_ProductSelectorController.getPaginationSize';



export default class ProductSelector extends LightningElement {
    
    @api recordId;

    //Product dropdown fields
    @track productName = '';
    @track productList = [];
    @track showProductDropdown = false;


    //category dropdown fields
    @track category = '';
    @track categoryList = [];
    @track showCategoryDropdown = false;

    // region fields
    @track region = '';
    regionPicklist = [];
     @api
    set accountregion(value) {
        this.region = value;
        console.log('Setter called in child. Region is:', this.region);
    }

    get accountregion() {
        return this.region;
    }

    @track ispartneruser = '';
     @api
    set partneruser(value) {
        this.ispartneruser = value;
        console.log('Setter called in partneruser:', this.ispartneruser);
    }

    get partneruser() {
        return this.ispartneruser;
    }

    @track requiredQuantity = '';

    // product searched and selected list fields
    @track products = [];
    @track selectedProducts = [];
    selectedRows = [];

    @track oldPlant;
 
    // unit of measure drop-down fields
    @track unitOfMeasure = '';
    @track unitOfMeasureList = [];
    @track showUnitOfMeasure = false;

    addedProductIds = new Set(); // Set for fast lookup

    // validation fields
    @track selectedPlant = null;
    @track tickedProducts = {};

    //pagination fields
    @track allProducts = [];      // Full list from Apex
    @track visibleProducts = [];  // Currently shown
    @track currentPage = 1;
    @track pageNumber = 1;
    @track pageSize = 10;         // Default value if Apex call fails
    totalPages = 0;
    totalRecords = 0;
    @track allSelectedProducts =[];
    @track visibleSelectedProducts = [];
    @track currentSelectedProductPage = 1;
    totalSelectedProductPages = 0;
   
    // page refresh fields
    wiredOrderProductsResult; 
    refreshHandlerID;
    isDefaultProduct = false;
    rendered = false;
    lastProcessedRecordId;  // Track the last recordId we processed

    isDeleteDisabled = false;

    label = {
        requiredQuantityLabel,
        unitOfMeasureLabel,
        regionLabel,
        productCategoryLabel,
        sampleProductNameLabel,
        sampleProductSelectorLabel,
        requiredQuantityHelpText,
        productNameHelpText,
        productCategoryHelpText
    };

    @wire(getPaginationSize)
    getPageSize(result){
        if(result.error){
            console.error('Error fetching pagination size:', result.error);
            // Keep the default value
        }
        else if(result.data){
            this.pageSize = parseInt(result.data.Value__c, 10) || 10; // Fallback to 10 if parsing fails
         
            this.updateSelectedVisibleProducts();
        }
    }

    @wire(getObjectInfo, { objectApiName: sampleMasterMatrixDataObject })
    objectInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: RegionField,
    })
    getPicklistValuesForRegion({ data, error }) {
        if (error) {
            console.error('Error fetching region picklist:', error);
        } else if (data) {
            const allOption = { label: 'All', value: '' };
        this.regionPicklist = [allOption, ...data.values];
        }
    }

    handleProductNameChange(event) {
        this.productName = event.currentTarget.dataset.name;
        this.showProductDropdown = false;
        document.removeEventListener('click', this.handleClickOutside);
    }
    
    handleProductNameInput(event){
        const searchTerm = event.target.value;

        console.log(searchTerm);
        this.productName = searchTerm;

        if(searchTerm.length > 1){
            searchProductNames({searchTerm})
                .then(result => {
                    this.productList = result; // Fixed variable name (was ProducList)
                    this.showProductDropdown = true;
                })
                .catch(error => {
                    console.error('Product name fetch error:', error);
                    this.showProductDropdown = false;
                });
        } else {
            this.showProductDropdown = false;
        }
        setTimeout(() => {
            document.addEventListener('click', this.handleClickOutside);
        }, 0);
     console.log(JSON.stringify(this.productList));
    }

    handleCategoryInput(event) {
        const searchTerm = event.target.value;
        this.category = searchTerm;

        if (searchTerm.length > 1) {
            searchCategories({ searchTerm })
                .then(result => {
                    this.categoryList = result;
                    this.showCategoryDropdown = true;
                })
                .catch(error => {
                    console.error('Category fetch error:', error);
                    this.showCategoryDropdown = false;
                });
        } else {
            this.showCategoryDropdown = false;
        }

         setTimeout(() => {
            document.addEventListener('click', this.handleClickOutside);
        }, 0);
    }

    handleCategorySelect(event) {
        this.category = event.currentTarget.dataset.name;
        this.showCategoryDropdown = false;
        document.removeEventListener('click', this.handleClickOutside);
    }

      handleClickOutside = (event) => {
        // If click is outside this component
        if (!this.template.contains(event.target)) {
            this.showCategoryDropdown = false;
            this.showProductDropdown = false;
            this.showUnitOfMeasure = false;
            document.removeEventListener('click', this.handleClickOutside);
        }
    };

    handleRequiredQuantity(event) {
        this.requiredQuantity = Number(event.target.value) || 0;
    }

    handleRegionChange(event) {
        this.region = event.detail.value;
    }

    handleUoMInput(event) {
        const searchTerm = event.target.value;
        this.unitOfMeasure = searchTerm;
        
        if (searchTerm.length > 1) {
            searchUoM({ searchTerm })
                .then(result => {
                    this.unitOfMeasureList = result;
                    this.showUnitOfMeasure = true;
                })
                .catch(error => {
                    console.error('UoM fetch error:', error);
                    this.showUnitOfMeasure = false;
                });
        } else {
            this.showUnitOfMeasure = false;
        }
        setTimeout(() => {
            document.addEventListener('click', this.handleClickOutside);
        }, 0);
    }

    handleUnitOfMeasure(event) {
        this.unitOfMeasure = event.currentTarget.dataset.name;
        this.showUnitOfMeasure = false;
        document.removeEventListener('click', this.handleClickOutside);
    }

    renderedCallback(){
        if (this.rendered) return;
        this.rendered = true;
        
        // Initialize the component with default pagination setup
      
        this.updateSelectedVisibleProducts();
    }

    get showingFrom() {
        return (this.pageNumber - 1) * this.pageSize + 1;
    }

    get showingTo() {
        const calcTo = this.pageNumber * this.pageSize;
        return calcTo > this.totalRecords ? this.totalRecords : calcTo;
    }

    get displaySummary() {
        return `Displaying ${this.showingFrom}–${this.showingTo} | Total ${this.totalRecords}`;
    }
    connectedCallback() {
        // default region from parent 
        //this.region = this.accountRegion;
        console.log('in child ', this.region, 'this.accountRegion', this.accountRegion);
        // Register refresh handler
        this.refreshHandlerID = registerRefreshHandler(this, this.refreshHandler.bind(this));
        
        // Reset component state whenever it's initialized
        this.resetComponentState();

        // Imperatively refresh from server
        console.log('in connected call back');
    if (this.recordId) {
        getOrderItemsFormOrder({ recordId: this.recordId })
            .then(data => {
                this.processOrderItems(data); // extract this from wired method
            })
            .catch(error => {
                console.error('Error loading order items imperatively:', error);
                this.showToast('Error', 'Could not load order products'+error.body.message, 'error');
            });
    }

    }
    
    disconnectedCallback() {
        unregisterRefreshHandler(this.refreshHandlerID);
    }

    // New method to properly reset component state
    resetComponentState() {
        // Clear any stale data
        this.addedProductIds = new Set();
        this.selectedProducts = [];
        this.products = [];
        this.currentPage = 1;
        this.currentSelectedProductPage = 1;
        this.selectedPlant = null;
        this.tickedProducts = {};
        
        // Initialize empty lists with pagination
        this.setProductList([]);
        this.setSelectedProductList([]);
        
        // If we have a recordId already, force refresh the data
        if (this.recordId && this.wiredOrderProductsResult) {
            refreshApex(this.wiredOrderProductsResult);
        }
    }

    refreshHandler() {
        // Always reset component state on refresh
        this.resetComponentState();
        
        // Return a promise for the refresh handler
        if (this.recordId && this.wiredOrderProductsResult) {
            return refreshApex(this.wiredOrderProductsResult);
        }
        return Promise.resolve();
    }

    @wire(getOrderItemsFormOrder, { recordId: '$recordId' })
    wiredOrderProducts(result) {
        // Detect when recordId changes and force a reset
        if (this.recordId !== this.lastProcessedRecordId) {
            this.lastProcessedRecordId = this.recordId;
            this.resetComponentState();
        }
        
        // Only process if we have a recordId (Order page context)
        if (!this.recordId) {
            this.selectedProducts = [];
            this.setSelectedProductList([]);
            return;
        }
        
        const {data, error} = result;
        this.wiredOrderProductsResult = result;

        if(data) {
            this.processOrderItems(data);
        } else if (error) {
            console.error('Error fetching order items:', error);
            this.showToast('Error', 'Could not load existing order products'+error.body.message, 'error');
        }
        
       
    }

    processOrderItems(data) {
        if (!data) return;
    
        this.addedProductIds = new Set();
        this.selectedProducts = data.map(item => {
            const uom = item.uom;
            this.tickedProducts = {
                salesforceOrderType: item.salesforceOrderType,
                s4OrderType: item.s4OrderType,
                shippingCondition: item.shippingCondition,
                deliveryBlock: item.deliveryBlock,
                plant: item.plantId,
                salesOrg: item.salesOrg,
                distributionChannel: item.distributionChannel,
                division: item.division,
                s4ItemCategory: item.itemCategory,
                pricebookEntryId: item.pricebookEntryId,
                pricebookId: item.pricebook2Id
            };
    
            let orderItemProductId = item.externalProductId;
            this.defaultProduct = false;
            if(item.defaultProductUsed){
                orderItemProductId = item.productName;
                this.defaultProduct = true; 
            }
            this.addedProductIds.add(item.Id);

            this.isDeleteDisabled = false;
            console.log(item.approvalStatus);
            if(item.approvalStatus === 'In Approval'){
                this.isDeleteDisabled = true; 
            }
    
            return {
                Id: item.Id,
                productId: item.productId,
                productName: item.description,
                categoryName: item.productCategoryName,
                possibleQuantity: item.possibleQuantity + (uom ? ' ' + uom : ''),
                quantity: item.possibleQuantity,
                plantName: item.plantName,
                regionName: item.region != null ? item.region : null,
                Min__c: item.minQty != null ?  item.minQty + (uom ? ' ' + uom : ''): null,
                Max__c: item.maxQty != null ? item.maxQty + (uom ? ' ' + uom : ''): null,
                estimatedStock: item.estimatedStock != null ? item.estimatedStock + (uom ? ' ' + uom : '') : null,
                ExternalProductId: orderItemProductId,
                orderProductId: item.orderProductId,
                isDefaultProduct: this.defaultProduct,
                isDeleteDisabled: this.isDeleteDisabled
            };
        });
    
        this.setSelectedProductList(this.selectedProducts);
        this.dispatchSelectedProducts();

    }
    
    handleUserSearch() {
    this.pageNumber = 1; // Always reset to page 1 for new searches
    this.handleSearch(); // Use the shared method for fetching
    }

    handleSearch() {
        // Show loading state if needed
        
        searchProducts({
            productName: this.productName,
            categoryName: this.category,
            unitOfMeasureName: this.unitOfMeasure,
            requiredQuantity: this.requiredQuantity,
            region: this.region,
            pageNumber: this.pageNumber,
            pageSize: this.pageSize
        })
        .then(result => {
            this.totalRecords = result.totalRecords; // store total count
            this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
            
            const reqQty = parseFloat(this.requiredQuantity) || 0;

            // Step 1: Map everything first
            let mappedProducts = result.records.map(item => {
                const matrix = item.matrixRecord;
                const UoM = matrix.Unit__r?.Name;
                const min = matrix.Min__c;
                const max = matrix.Max__c;
                let possibleQuantity = reqQty;

                let quantityClass = '';
                let stockClass = '';

                if (reqQty === 0) {
                    quantityClass = '';
                    possibleQuantity = min;
                } else {
                    let rounded = Math.ceil(reqQty / min) * min;
                    possibleQuantity = Math.min(rounded, max);

                    if (reqQty < min || reqQty > max) {
                        quantityClass = 'background-color: #ff4d4d; color: white;';
                    } else if (reqQty % min === 0) {
                        quantityClass = 'background-color: #2ecc71; color: white;';
                    } else {
                        quantityClass = 'background-color: #ffa500; color: black;';
                    }
                }

                if (possibleQuantity > item.stockLevel) {
                    stockClass = 'background-color: #ffa500; color: black;';
                }

                return {
                    Id: matrix.Id,
                    ExternalProductId: matrix.Product__r.Product_Id__c,
                    productName: matrix.Product__r?.Name,
                    categoryName: matrix.Product_Category_ID__r?.Name,
                    plantName: matrix.Plant_ID__r?.Name,
                    Min__c: min != null ? min + (UoM ? ' ' + UoM : '') : null,
                    Max__c: max != null ? max + (UoM ? ' ' + UoM : '') : null,
                    quantityClass: quantityClass,
                    possibleQuantity: possibleQuantity != null ? possibleQuantity + (UoM ? ' ' + UoM : '') : null,
                    regionName: matrix.Region__c,
                    estimatedStock: item?.stockLevel != null ? item.stockLevel + (UoM ? ' ' + UoM : '') : null,
                    stockClass: stockClass,
                    productId: matrix.Product__c,
                    quantity: possibleQuantity,
                    productCategoryId: matrix.Product_Category_ID__c,
                    plantId: matrix.Plant_ID__c,
                    Unit: matrix.Unit__c,
                    stockLevel: item?.stockLevel,
                    isDefaultProduct: this.isDefaultProduct
                };
            });

            // Step 2: Now filter out already added products
            this.products = mappedProducts.filter(
                prod => !this.addedProductIds.has(prod.Id)
            );

            this.setProductList(this.products);
           
        })
        .catch(error => {
            console.error('Product fetch error:', error);
            this.showToast('Error', 'Failed to search products', 'error');
            this.setProductList([]);
        });
    }

    handleRowCheckbox(event) {
        const checkbox = event.target;
        const selectedId = event.target.dataset.id;
        const isChecked = checkbox.checked;
        const selectedProduct = this.products.find(prod => prod.Id === selectedId);

        if (!selectedProduct) return;

        const selectedProductId = selectedProduct.productId;
        const selectedPlantId = selectedProduct.plantId;
        const selectedUoM = selectedProduct.Unit;

        if (this.selectedProducts.length === 0 && this.selectedRows.length === 0) {
            this.selectedPlant = null;
            this.tickedProducts = null;
        }
        
        // First selection: validate and set selected plant and tickedProducts
        if (!this.selectedPlant && isChecked && this.selectedProducts.length === 0) {
            this.selectedPlant = selectedProduct.plantName;

            validateTickedProducts({
                productId: selectedProductId,
                plantId: selectedPlantId,
                unitOfMeasure: selectedUoM
            })
            .then(result => {
                this.tickedProducts = result;  // Store as an object, not a string
                console.log('ticked product');
                if(this.tickedProducts.defaultProduct != null) {
                    selectedProduct.isDefaultProduct = true;
                    selectedProduct.productId = this.tickedProducts.defaultProduct;
                 } else if(selectedProduct.productName.includes('<') || selectedProduct.productName.includes('>')){
                     selectedProduct.isDefaultProduct = true;
                 }
                else {
                    selectedProduct.isDefaultProduct = false;
                }
                console.log('product Name: '+ selectedProduct.productName + ' '+  selectedProduct.isDefaultProduct);
                // Merge tickedProducts with selectedProduct
                const updatedSelectedProduct = {
                    ...selectedProduct,
                    tickedProducts: this.tickedProducts
                };

                // Add the updated product to selectedRows
                this.selectedRows = [...this.selectedRows, updatedSelectedProduct];
                
                this.handleAddSelected();
            })
            .catch(error => {
                console.error('Validation failed (first selection):', error);
                event.target.checked = false;
                this.showToast('Validation Error', error.body?.message || 'Invalid selection.', 'error');
            });

            return;
        }
        
        // Further validations for subsequent selections
        if (isChecked && this.tickedProducts) {
            validateTickedProducts({
                productId: selectedProductId,
                plantId: selectedPlantId,
                unitOfMeasure: selectedUoM,
                oldSelectedProductJson: JSON.stringify(this.tickedProducts)
            })
            .then(result => {
                const updatedSelectedProduct = {
                    ...selectedProduct,
                    tickedProducts: result
                };

                this.selectedRows = [...this.selectedRows, updatedSelectedProduct];     
                this.handleAddSelected();
            })
            .catch(error => {
                console.error('Validation failed (additional selection):', error);
                event.target.checked = false;
                this.showToast('Validation Error', error.body?.message || 'Invalid selection.', 'error');
            });
        } else if (!isChecked) {
            // Removing product from selection
            this.selectedRows = this.selectedRows.filter(row => row.Id !== selectedId);
        }
    }

    handleAddSelected() {
        const selectedIds = this.selectedRows.map(row => row.Id);
        
        this.selectedRows.forEach(row => this.addedProductIds.add(row.Id));
        const newSelections = this.selectedRows.filter(
            row => !this.selectedProducts.find(p => p.Id === row.Id)
        );

        this.selectedProducts = [...this.selectedProducts, ...newSelections];

        this.setSelectedProductList(this.selectedProducts);

        console.log('selected Prdocut: '+ this.selectedProducts);
        // Clear the product list to hide the table
        this.products = [];
        this.selectedRows = [];

        this.handleSearch();
        
        //after adding a product. dispatch the list
        this.dispatchSelectedProducts();
    }

    clearSearch() {
        // Clear the product list to hide the table
        this.products = [];
        this.selectedRows = [];

        //  Clear the correct fields
        this.productName = '';
        this.category = '';
        this.unitOfMeasure = '';
        this.requiredQuantity = '';
        this.region = '';

        // Clear dropdown data and visibility
        this.categoryList = [];
        this.unitOfMeasureList = [];
        this.showCategoryDropdown = false;
        this.showUnitOfMeasure = false;
        this.showProductDropdown = false;

        this.setProductList([]);
    }

    handleRemove(event) {
        const idToRemove = event.target.dataset.id;

       // this.selectedProducts = this.selectedProducts.filter(prod => prod.Id !== idToRemove);
        // Remove from selectedProducts
      const updatedList = this.selectedProducts.filter(prod => prod.Id !== idToRemove);
       this.selectedProducts = [...updatedList]; // <-- Trigger reactivity

       console.log('selected Prdocut: '+ this.selectedProducts);

        this.setSelectedProductList(this.selectedProducts);
        this.addedProductIds.delete(idToRemove);
        
        if(this.products && this.products.length > 0){
            this.handleSearch();
        }
        
        //after removing a product, dispatch the list
        this.dispatchSelectedProducts();
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(evt);
    }

    // method to change the name of default product
    handleDefaultProductNameChange(event) {
        const productId = event.target.dataset.id;
        const newName = event.target.value;
    
        // Find and update the product in the array
        this.selectedProducts = this.selectedProducts.map(product => {
            if (product.Id === productId) {
                return {
                    ...product,
                    productName: newName
                };
            }
            return product;
        });

        this.dispatchSelectedProducts();
    }
     
    // Pagination Logic - Fixed version
    setProductList(products) {
        this.allProducts = products || [];
       this.visibleProducts = this.allProducts;
     
    }

  
    handleNext(event ) {
        if (event) {
            event.preventDefault();
            event.stopPropagation();
        }

        if (this.pageNumber < this.totalPages) {
            this.pageNumber++;
            this.handleSearch();
          
        }
    }

    handlePrev(event ) {

        if (event) {
            event.preventDefault();
            event.stopPropagation();
        }

        if (this.pageNumber > 1) {
            this.pageNumber--;
            this.handleSearch();
          
        }
    }
    
    get isFirstPage() {
        return (this.pageNumber === 1)? false: true;
    }
    
    get isLastPage() {
        return (this.pageNumber === this.totalPages || this.totalPages === 0)? false:true;
    }

    setSelectedProductList(selectedProducts) {
        this.allSelectedProducts = selectedProducts || [];
        this.totalSelectedProductPages = Math.max(1, Math.ceil(this.allSelectedProducts.length / this.pageSize));
        this.currentSelectedProductPage = Math.min(this.currentSelectedProductPage, this.totalSelectedProductPages);
        this.updateSelectedVisibleProducts();
    }

    updateSelectedVisibleProducts() {
        const start = (this.currentSelectedProductPage - 1) * this.pageSize;
        const end = Math.min(start + this.pageSize, this.allSelectedProducts.length);
        
        this.visibleSelectedProducts = this.allSelectedProducts.slice(start, end);
    }
    
    handleSelectedNext(event) {

        if (event) {
            event.preventDefault();
            event.stopPropagation();
        }
        if (this.currentSelectedProductPage < this.totalSelectedProductPages) {
            this.currentSelectedProductPage++;
            this.updateSelectedVisibleProducts();
        }
    }
    
    handleSelectedPrev(event) {

        if (event) {
            event.preventDefault();
            event.stopPropagation();
        }
        if (this.currentSelectedProductPage > 1) {
            this.currentSelectedProductPage--;
            this.updateSelectedVisibleProducts();
        }
    }
    
    get isFirstSelectedProductPage() {
        return (this.currentSelectedProductPage === 1)? false: true;
    }
    
    get isLastSelectedProductPage() {
        return (this.currentSelectedProductPage === this.totalSelectedProductPages || this.totalSelectedProductPages === 0)? false: true;
    }

    // Method to dispatch selectedProducts list to parent
    dispatchSelectedProducts() {
        const selectedProductsEvent = new CustomEvent('selectedproductschange', {
            detail: { 
                selectedProducts: this.selectedProducts
            }
        });

        // Dispatch the event
        this.dispatchEvent(selectedProductsEvent);
    }
}