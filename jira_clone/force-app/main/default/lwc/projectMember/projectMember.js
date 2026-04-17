import { LightningElement, track } from 'lwc';
import loadUsers from '@salesforce/apex/UserController.loadUsers';
import createMember from '@salesforce/apex/ProjectMemberController.createMember';

export default class DataProjectMember extends LightningElement {
    @track newMember = {
        userId: '',
        projectId: '',
        recordStatus: ''
    };

    @track projectOptions = [];
    @track userOptions = [];
    @track isLoading = false;
    @track errorMessage = '';
    @track successMessage = '';
    @track showForm = false;

    connectedCallback() {
        this.loadProjectOptions();
        this.loadUserOptions();
    }

    loadProjectOptions() {
        loadProjects()
            .then(response => {
                if (response.success && response.data) {
                    this.projectOptions = [
                        { label: 'Select a Project...', value: '' },
                        ...response.data.map(project => ({ label: project.Name, value: project.Id }))
                    ];
                    this.errorMessage = '';
                } else {
                    this.errorMessage = response.message || 'Failed to load projects';
                    this.projectOptions = [{ label: 'Select a Project...', value: '' }];
                }
            })
            .catch(error => {
                this.errorMessage = 'Error loading projects: ' + (error.body?.message || error.message);
                this.projectOptions = [{ label: 'Select a Project...', value: '' }];
            });
    }

    loadUserOptions() {
        loadUsers()
            .then(response => {
                if (response.success && response.data) {
                    this.userOptions = [
                        { label: 'Select a User...', value: '' },
                        ...response.data.map(u => ({ label: u.Name, value: u.Id }))
                    ];
                    this.errorMessage = '';
                } else {
                    this.errorMessage = response.message || 'Failed to load users';
                    this.userOptions = [{ label: 'Select a User...', value: '' }];
                }
            })
            .catch(error => {
                this.errorMessage = 'Error loading users: ' + (error.body?.message || error.message);
                this.userOptions = [{ label: 'Select a User...', value: '' }];
            });
    }

    toggleForm() {
        this.showForm = !this.showForm;
        if (!this.showForm) this.resetForm();
    }

    handleUserChange(event) {
        this.newMember.userId = event.target.value;
        this.errorMessage = '';
    }

    handleProjectChange(event) {
        this.newMember.projectId = event.target.value;
        this.errorMessage = '';
    }

    handleRecordStatusChange(event) {
        this.newMember.recordStatus = event.target.value;
        this.errorMessage = '';
    }

    handleCreateMember() {
        if (!this.newMember.userId || !this.newMember.projectId) {
            this.errorMessage = 'Please select both User and Project';
            return;
        }

        this.isLoading = true;

        // Use server-side creator which adapts to the installed field names
        createMember({ userId: this.newMember.userId, projectId: this.newMember.projectId, recordStatus: this.newMember.recordStatus })
            .then(response => {
                if (response.success) {
                    this.successMessage = 'Project member added successfully!';
                    this.resetForm();
                    this.clearMessages();
                } else {
                    this.errorMessage = response.message || 'Failed to add project member';
                }
            })
            .catch(error => {
                this.errorMessage = 'Error adding project member: ' + (error.body?.message || error.message);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    resetForm() {
        this.newMember = { userId: '', projectId: '', recordStatus: '' };
    }

    clearMessages() {
        setTimeout(() => {
            this.successMessage = '';
            this.errorMessage = '';
        }, 5000);
    }
}