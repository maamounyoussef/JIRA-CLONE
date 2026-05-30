import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import loadAllProjects from '@salesforce/apex/ProjectSplashController.loadAllProjects';

export default class ChooseProject extends LightningElement {

    @track _projects = [];

    @wire(loadAllProjects)
    wiredLoadAllProjects(result) {
        if (result.data) {
            if (result.data.success) {
                this._projects = result.data.data || [];
            } else {
                this._toast('Error', result.data.message || 'Failed to load projects', 'error');
            }
        } else if (result.error) {
            this._toast('Error', result.error.body?.message || 'Error loading projects', 'error');
        }
    }

    get hasProjects() { return this._projects.length > 0; }
    get projects()    { return this._projects; }

    handleSelectProject(event) {
        const projectId   = event.currentTarget.dataset.projectId;
        const projectName = event.currentTarget.dataset.projectName;
        if (!projectId) return;
        localStorage.setItem('projectId', projectId);
        localStorage.setItem('projectName', projectName || '');
        this.dispatchEvent(new CustomEvent('projectchosen', {
            detail: { projectId, projectName },
            bubbles: true,
            composed: true
        }));
    }

    _toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
