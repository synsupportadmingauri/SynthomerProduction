import { LightningElement, api } from 'lwc';

export default class PortalButton extends LightningElement {
  @api bannerText = 'Create Sample Order';
  @api backgroundColor = '#054A7A';

  isModalOpen = false;

  get bannerStyle() {
    return `background-color: ${this.backgroundColor}; cursor: pointer;`;
  }

  handleClick() {
    this.isModalOpen = true;
  }

  handleClose() {
    this.isModalOpen = false;
  }
}