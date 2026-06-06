import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import loadReportDetailsByProject from '@salesforce/apex/ReportController.loadReportDetailsByProject';
import { validateReportId } from './reportPageValidator';

/**
 * reportPage — smart page component for the report gallery.
 *
 * Renders a responsive gallery of report-detail cards for the current project.
 * Clicking a card validates its linked Salesforce report id and navigates
 * straight to that report's run page, applying the project name as the report's
 * first filter value (fv0).
 *
 * Owns the principal state (`_reportDetails`), set only from the wired Apex
 * response. The wire gate (`_wiredProjectId`) is kept separate so the load
 * fires exactly once on entry.
 */
export default class ReportPage extends NavigationMixin(LightningElement) {

    // ─── PRINCIPAL STATE ──────────────────────────────────────────────────────
    @track _reportDetails = [];           // set from the wired Apex response only

    // ─── NON-STRUCTURAL FLAGS ─────────────────────────────────────────────────
    _showChooseProject = false;
    isLoading = false;

    // ─── WIRE GATE (separate from UI interaction) ─────────────────────────────
    _wiredProjectId;                      // undefined → wire dormant until seeded

    connectedCallback() {
        const projectId = localStorage.getItem('projectId');
        if (!projectId) {
            this._showChooseProject = true;
            return;
        }
        this.isLoading = true;
        this._wiredProjectId = projectId; // load on entry
    }

    @wire(loadReportDetailsByProject, { projectId: '$_wiredProjectId' })
    wiredReportDetails(result) {
        const { data, error } = result;
        if (data) {
            this.isLoading = false;
            if (data.success) {
                this._reportDetails = data.data || [];
            } else {
                this._toastError(data.message);
            }
        } else if (error) {
            this.isLoading = false;
            this._toastError(this._reduceError(error));
        }
    }

    // ─── DERIVED GETTERS ──────────────────────────────────────────────────────
    get showChooseProject() {
        return this._showChooseProject;
    }

    get showGallery() {
        return !this._showChooseProject;
    }

    get reportDetails() {
        return this._reportDetails;
    }

    get hasReportDetails() {
        return this._reportDetails.length > 0;
    }

    get isGalleryEmpty() {
        return !this.hasReportDetails;
    }

    // ─── EVENT HANDLERS ───────────────────────────────────────────────────────
    handleProjectChosen(event) {
        const { projectId } = event.detail || {};
        if (!projectId) return;
        this._showChooseProject = false;
        this.isLoading = true;
        this._wiredProjectId = projectId;
    }

    handleCardButtonSelect(event) {
        const detail = this._reportDetails.find(d => d.Id === event.detail.value);
        const reportId = detail && detail.Salesforce_Report__c;

        const result = validateReportId(reportId);
        if (!result.valid) {
            this._toastError(result.message);
            return;
        }

        // Navigate to the report run page with the project name as the first
        // filter value (fv0).
        const projectName = localStorage.getItem('projectName') || '';
        const url = `/lightning/r/Report/${reportId}/view?fv0=${encodeURIComponent(projectName)}`;
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: { url }
        });
    }

    // ─── ERROR CHANNEL ────────────────────────────────────────────────────────
    _toastError(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Something went wrong',
            message: message || 'Unable to load report details.',
            variant: 'error'
        }));
    }

    _reduceError(error) {
        return (error && error.body && error.body.message) || 'Unknown error';
    }
}
