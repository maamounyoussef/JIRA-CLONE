import { LightningElement, track } from 'lwc';
import loadAllProjects   from '@salesforce/apex/ManageProjectMemberController.loadAllProjects';
import loadMembers       from '@salesforce/apex/ManageProjectMemberController.loadMembers';
import searchUsersByTerm from '@salesforce/apex/ManageProjectMemberController.searchUsersByTerm';
import addMemberApex     from '@salesforce/apex/ManageProjectMemberController.addMember';
import updateMemberRole  from '@salesforce/apex/ManageProjectMemberController.updateMemberRole';
import deleteMemberApex  from '@salesforce/apex/ManageProjectMemberController.deleteMember';

import {
    ALLOWED_ROLES,
    isSearchTermLongEnough,
    isUserNotAlreadyMember,
    isRoleAllowed,
    isDeleteConfirmed
} from './manageProjectMemberValidator';

const SEARCH_DEBOUNCE_MS = 180;
const TOAST_VISIBLE_MS   = 2600;

export default class ManageProjectMember extends LightningElement {

    @track _projects     = [];
    @track _members      = [];
    @track _searchResults = [];

    _selectedProjectId = null;
    _searchTerm        = '';
    _searchTimer       = null;
    _showDropdown      = false;

    @track _editingMember   = null;
    @track _editingRole     = null;
    @track _deletingMember  = null;

    @track _toast = null; // { variant: 'success'|'default'|'error', message: string }
    _toastTimer  = null;

    _roleOptions = ALLOWED_ROLES.map(r => ({ label: r, value: r }));

    // ─── LIFECYCLE ────────────────────────────────────────────────────────────

    connectedCallback() {
        this._loadProjectsAndMembers();
    }

    _loadProjectsAndMembers() {
        loadAllProjects()
            .then(res => {
                if (!res || !res.success) {
                    this._showToast('error', (res && res.message) || 'Failed to load projects');
                    return;
                }
                this._projects = res.data || [];
                if (this._projects.length > 0) {
                    this._selectedProjectId = this._projects[0].Id;
                    this._loadMembersForProject(this._selectedProjectId);
                }
            })
            .catch(err => this._showToast('error', this._readErr(err)));
    }

    _loadMembersForProject(projectId) {
        loadMembers({ projectId })
            .then(res => {
                if (!res || !res.success) {
                    this._showToast('error', (res && res.message) || 'Failed to load members');
                    return;
                }
                this._members = res.data || [];
            })
            .catch(err => this._showToast('error', this._readErr(err)));
    }

    // ─── PROJECT SELECTOR ─────────────────────────────────────────────────────

    handleProjectChange(event) {
        const projectId = event.detail.value;
        if (!projectId) return;
        this._selectedProjectId = projectId;
        this._searchTerm = '';
        this._searchResults = [];
        this._showDropdown = false;
        this._loadMembersForProject(projectId);
    }

    get projectOptions() {
        return this._projects.map(p => ({ label: p.Name, value: p.Id }));
    }

    get projectCount() {
        return this._projects.length;
    }

    get memberCount() {
        return this._members.length;
    }

    get hasMembers() {
        return this._members.length > 0;
    }

    get memberRows() {
        return this._members.map(m => ({
            Id: m.Id,
            userId: m.User__c,
            name: (m.User__r && m.User__r.Name) || m.Name || '',
            accountId: m.User__c || '',
            role: m.Role__c || '',
            roleLabel: m.Role__c || '—'
        }));
    }

    // ─── SEARCH ───────────────────────────────────────────────────────────────

    handleSearchInput(event) {
        const term = (event.detail && event.detail.value) || '';
        this._searchTerm = term;

        if (this._searchTimer) {
            clearTimeout(this._searchTimer);
            this._searchTimer = null;
        }

        if (!isSearchTermLongEnough(term)) {
            this._searchResults = [];
            this._showDropdown = false;
            return;
        }

        this._searchTimer = setTimeout(() => this._runSearch(term), SEARCH_DEBOUNCE_MS);
    }

    _runSearch(term) {
        const projectId = this._selectedProjectId;
        if (!projectId || !isSearchTermLongEnough(term)) return;

        searchUsersByTerm({ projectId, searchTerm: term.trim() })
            .then(res => {
                if (!res || !res.success) {
                    this._searchResults = [];
                    this._showDropdown = false;
                    return;
                }
                const results = (res.data || []).map(u => ({
                    Id: u.Id,
                    name: u.Name,
                    username: u.Username,
                    initials: this._initialsFor(u.Name)
                }));
                this._searchResults = results;
                this._showDropdown = results.length > 0;
            })
            .catch(() => {
                this._searchResults = [];
                this._showDropdown = false;
            });
    }

    handleSearchBlur() {
        setTimeout(() => {
            this._searchTerm = '';
            this._searchResults = [];
            this._showDropdown = false;
        }, 120);
    }

    get showSearchDropdown() {
        return this._showDropdown && this._searchResults.length > 0;
    }

    // ─── ADD ──────────────────────────────────────────────────────────────────

    handleAddMember(event) {
        const userId = event.currentTarget.dataset.userid;
        if (!userId) return;

        if (!isUserNotAlreadyMember(userId, this._members)) {
            this._showToast('error', 'Already a member of this project');
            return;
        }

        const projectId = this._selectedProjectId;
        addMemberApex({ projectId, userId })
            .then(res => {
                if (!res || !res.success) {
                    this._showToast('error', (res && res.message) || 'Failed to add member');
                    return;
                }
                this._members = [...this._members, res.data];
                this._searchTerm = '';
                this._searchResults = [];
                this._showDropdown = false;
                const name = (res.data && res.data.User__r && res.data.User__r.Name) || 'Member';
                this._showToast('success', `${name} added to project`);
            })
            .catch(err => this._showToast('error', this._readErr(err)));
    }

    // ─── EDIT ─────────────────────────────────────────────────────────────────

    handleOpenEdit(event) {
        const memberId = event.currentTarget.dataset.id;
        const member = this._members.find(m => m.Id === memberId);
        if (!member) return;
        this._editingMember = member;
        this._editingRole = member.Role__c || ALLOWED_ROLES[0];
    }

    handleEditRoleChange(event) {
        this._editingRole = event.detail.value;
    }

    handleSaveEdit() {
        const member = this._editingMember;
        if (!member) return;

        if (!isRoleAllowed(this._editingRole)) {
            this._showToast('error', 'Please pick a valid role');
            return;
        }

        updateMemberRole({ memberId: member.Id, role: this._editingRole })
            .then(res => {
                if (!res || !res.success) {
                    this._showToast('error', (res && res.message) || 'Failed to update member');
                    return;
                }
                this._members = this._members.map(m =>
                    m.Id === member.Id ? { ...m, Role__c: res.data.Role__c } : m
                );
                this._editingMember = null;
                this._editingRole = null;
                this._showToast('success', 'Member updated');
            })
            .catch(err => this._showToast('error', this._readErr(err)));
    }

    handleCloseEdit() {
        this._editingMember = null;
        this._editingRole = null;
    }

    get showEditModal() {
        return this._editingMember !== null;
    }

    get editingMemberName() {
        const m = this._editingMember;
        if (!m) return '';
        return (m.User__r && m.User__r.Name) || m.Name || '';
    }

    get editingMemberAccountId() {
        return this._editingMember ? this._editingMember.User__c : '';
    }

    // ─── DELETE ───────────────────────────────────────────────────────────────

    handleOpenDelete(event) {
        const memberId = event.currentTarget.dataset.id;
        const member = this._members.find(m => m.Id === memberId);
        if (!member) return;
        this._deletingMember = member;
    }

    handleConfirmDelete() {
        const member = this._deletingMember;
        if (!member) return;
        if (!isDeleteConfirmed(true)) return;

        deleteMemberApex({ memberId: member.Id })
            .then(res => {
                if (!res || !res.success) {
                    this._showToast('error', (res && res.message) || 'Failed to remove member');
                    return;
                }
                const removedName = (member.User__r && member.User__r.Name) || 'Member';
                this._members = this._members.filter(m => m.Id !== member.Id);
                this._deletingMember = null;
                this._showToast('default', `${removedName} removed from project`);
            })
            .catch(err => this._showToast('error', this._readErr(err)));
    }

    handleCloseDelete() {
        this._deletingMember = null;
    }

    get showDeleteModal() {
        return this._deletingMember !== null;
    }

    get deletingMemberName() {
        const m = this._deletingMember;
        if (!m) return '';
        return (m.User__r && m.User__r.Name) || m.Name || '';
    }

    // ─── TOAST ────────────────────────────────────────────────────────────────

    _showToast(variant, message) {
        this._toast = { variant, message };
        if (this._toastTimer) clearTimeout(this._toastTimer);
        this._toastTimer = setTimeout(() => {
            this._toast = null;
            this._toastTimer = null;
        }, TOAST_VISIBLE_MS);
    }

    get toastClass() {
        if (!this._toast) return 'toast';
        return `toast toast--${this._toast.variant}`;
    }

    // ─── HELPERS ──────────────────────────────────────────────────────────────

    _initialsFor(name) {
        if (!name) return '';
        const parts = name.trim().split(/\s+/);
        return (parts[0][0] + (parts[1] ? parts[1][0] : '')).toUpperCase();
    }

    _readErr(err) {
        if (!err) return 'Unexpected error';
        if (err.body && err.body.message) return err.body.message;
        if (err.message) return err.message;
        return String(err);
    }
}
