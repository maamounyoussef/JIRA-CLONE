import { LightningElement, track } from 'lwc';
import loadProjects from '@salesforce/apex/ManageBacklogController.loadProjects';

export default class ProjectSelector extends LightningElement {
    
    @track projectOptions = [];
    @track selectedProjectId = '';
    @track selectedProjectName = '';
    @track isLoading = false;
    @track errorMessage = null;
    @track projectSelected = false;
    
    get isLoadDisabled() {
        return !this.selectedProjectId;
    }
    
    connectedCallback() {
        // Check if project already selected in localStorage
        const savedProjectId = localStorage.getItem('projectId');
        const savedProjectName = localStorage.getItem('projectName');
        
        if (savedProjectId) {
            this.selectedProjectId = savedProjectId;
            this.selectedProjectName = savedProjectName || '';
            this.projectSelected = true;
        }
        
        this.loadProjects();
    }
    
    loadProjects() {
        this.isLoading = true;
        this.errorMessage = null;
        
        loadProjects()
            .then(result => {
                if (result.success) {
                    const projects = result.data || [];
                    this.projectOptions = projects.map(project => ({
                        label: project.Name,
                        value: project.Id
                    }));
                } else {
                    this.errorMessage = result.message || 'Failed to load projects';
                }
            })
            .catch(error => {
                this.errorMessage = error.body?.message || 'Error loading projects';
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
    
    handleProjectChange(event) {
        this.selectedProjectId = event.detail.value;
        const selectedOption = this.projectOptions.find(
            opt => opt.value === this.selectedProjectId
        );
        this.selectedProjectName = selectedOption ? selectedOption.label : '';
    }
    
    handleLoadBacklog() {
        if (!this.selectedProjectId) return;
        
        // Store in localStorage for manageBacklog to use
        localStorage.setItem('projectId', this.selectedProjectId);
        localStorage.setItem('projectName', this.selectedProjectName);
        
        this.projectSelected = true;
    }
    
    handleChangeProject() {
        // Clear selection and show selector again
        this.projectSelected = false;
        // Don't clear localStorage yet - keep it if they reselect same project
    }
}
