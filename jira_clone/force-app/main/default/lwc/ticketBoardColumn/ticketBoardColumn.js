import { LightningElement, api, track } from 'lwc';
import { dispatchTicketDragStart, dispatchTicketDrop, dispatchTicketDragEnd } from './ticketBoardColumnEvents';

export default class TicketBoardColumn extends LightningElement {

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                         COLUMN SECTION                                   ║
// ╚══════════════════════════════════════════════════════════════════════════╝

    // ─── PROPERTIES & STATE ───────────────────────────────────────────────────
    @api statusId      = '';
    @api statusName    = '';
    @api tickets       = [];
    @api isValidTarget = false;
    @api memberOptions = [];

    @track _isDragOver = false;

    // ─── GETTERS ──────────────────────────────────────────────────────────────
    get columnClass() {
        let cls = 'status-column';
        if (this.isValidTarget)                   cls += ' valid-target';
        if (this._isDragOver && this.isValidTarget) cls += ' drag-over';
        return cls;
    }

    get ticketCount() {
        return this.tickets ? this.tickets.length : 0;
    }

    // ─── EVENT HANDLERS ───────────────────────────────────────────────────────
    handleTicketDragStart(evt) {
        const ticketId     = evt.currentTarget.dataset.ticketId;
        const ticketTypeId = evt.currentTarget.dataset.ticketTypeId;
        evt.dataTransfer.effectAllowed = 'move';
        dispatchTicketDragStart(this, ticketId, this.statusId, ticketTypeId);
    }

    handleTicketDragEnd() {
        this._isDragOver = false;
        dispatchTicketDragEnd(this);
    }

    handleDragOver(evt) {
        if (this.isValidTarget) {
            evt.preventDefault();
            evt.dataTransfer.dropEffect = 'move';
            this._isDragOver = true;
        }
    }

    handleDragLeave() {
        this._isDragOver = false;
    }

    handleDrop(evt) {
        evt.preventDefault();
        this._isDragOver = false;
        if (this.isValidTarget) {
            dispatchTicketDrop(this, this.statusId);
        }
    }
}
