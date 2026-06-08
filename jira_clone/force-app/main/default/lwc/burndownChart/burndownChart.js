import { LightningElement } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ChartJS from '@salesforce/resourceUrl/ChartJS';
import loadBurndownChart from '@salesforce/apex/ReportController.loadBurndownChart';

const FIELD_TOTAL = 'TotalStoryPoint__c';        // committed scope
const FIELD_ENDED = 'TotalEndedStoryPoint__c';   // completed scope
const FIELD_STATUS = 'RecordStatus__c';          // sprint lifecycle
const STATUS_START = 'in_progress';              // value that marks sprint start

/**
 * burndownChart — sprint burndown built from Sprint__History rows.
 *
 * Calls ReportController.loadBurndownChart, which returns the history rows from
 * the `RecordStatus__c → in_progress` change (sprint start) onward, sorted
 * chronologically (day, then time within the day).
 *
 * Principal state is `_rows` (the raw Apex payload); everything the chart needs
 * is derived from it in `_model`:
 *   • start day  — the day of the RecordStatus__c → in_progress row.
 *   • per day    — the latest (highest-time) value wins, so iterating the
 *                  already-sorted rows and letting the last write win per day
 *                  gives each day's closing TotalStoryPoint / TotalEndedStoryPoint.
 *   • remaining  — committedTotal − totalEndedStoryPoint (carried forward).
 *
 * The committed total is read from TotalStoryPoint__c rows when present; if the
 * controller trimmed them out (they can land just before the start row), it
 * falls back to the peak TotalEndedStoryPoint__c value so the line still draws.
 */
export default class BurndownChart extends LightningElement {

    // ─── PRINCIPAL STATE ──────────────────────────────────────────────────────
    _rows = [];                 // raw history rows from Apex (only source of truth)

    // ─── NON-STRUCTURAL FLAGS ─────────────────────────────────────────────────
    isLoading = true;
    hasError = false;
    errorMessage = '';

    // ─── IMPERATIVE / LIBRARY HANDLES (not UI state) ──────────────────────────
    _chart;                     // Chart.js instance
    _chartJsReady = false;      // static resource loaded
    _dataReady = false;         // Apex payload received
    _scriptRequested = false;   // loadScript fired once

    connectedCallback() {
        this._fetchData();
    }

    renderedCallback() {
        if (this._scriptRequested) return;
        this._scriptRequested = true;
        loadScript(this, ChartJS)
            .then(() => {
                this._chartJsReady = true;
                this._renderChart();
            })
            .catch((e) => {
                this._scriptRequested = false;
                this._fail('Chart.js failed to load: ' + this._reduce(e));
            });
    }

    disconnectedCallback() {
        if (this._chart) {
            this._chart.destroy();
            this._chart = undefined;
        }
    }

    // ─── DATA LOAD ────────────────────────────────────────────────────────────
    async _fetchData() {
        try {
            const res = await loadBurndownChart();
            if (res && res.success) {
                this._rows = Array.isArray(res.data) ? res.data : [];
                this._dataReady = true;
                this._renderChart();
            } else {
                this._fail((res && res.message) || 'Unable to load burndown data.');
            }
        } catch (e) {
            this._fail(this._reduce(e));
        }
    }

    // ─── DERIVED MODEL ────────────────────────────────────────────────────────
    /**
     * Collapse the raw rows into the chart series.
     * @returns {{labels:string[], remaining:number[], ideal:number[], total:number}}
     */
    get _model() {
        const rows = this._rows;
        if (!rows.length) {
            return { labels: [], remaining: [], ideal: [], total: 0 };
        }

        // start day = day of the RecordStatus__c → in_progress row (fallback: first row)
        let startDay = null;
        for (const r of rows) {
            if (r.field === FIELD_STATUS && r.newValue === STATUS_START) {
                startDay = r.day;
                break;
            }
        }
        if (!startDay) startDay = rows[0].day;

        // committed total: prefer real TotalStoryPoint__c values; never let it sit
        // below the highest completed value (ended can't exceed scope).
        let total = 0;
        for (const r of rows) {
            if (r.field === FIELD_TOTAL || r.field === FIELD_ENDED) {
                total = Math.max(total, this._num(r.newValue));
            }
        }

        // Per-day closing values. Rows arrive sorted (day, then time), so iterating
        // and letting the last write win per day yields the highest-time value.
        const totalByDay = new Map();
        const endedByDay = new Map();
        const dayOrder = [];
        const seenDay = new Set();
        for (const r of rows) {
            const day = r.day;
            if (!day || day < startDay) continue;
            if (!seenDay.has(day)) { seenDay.add(day); dayOrder.push(day); }
            if (r.field === FIELD_TOTAL) totalByDay.set(day, this._num(r.newValue));
            else if (r.field === FIELD_ENDED) endedByDay.set(day, this._num(r.newValue));
        }
        dayOrder.sort(); // ISO date strings sort chronologically

        // Walk days carrying forward the latest known total + ended.
        const labels = [];
        const remaining = [];
        let lastTotal = total;
        let lastEnded = 0;
        for (const day of dayOrder) {
            if (totalByDay.has(day)) lastTotal = totalByDay.get(day);
            if (endedByDay.has(day)) lastEnded = endedByDay.get(day);
            labels.push(day);
            remaining.push(lastTotal - lastEnded);
        }

        // Ideal burndown: straight line from the commitment down to 0.
        const n = labels.length;
        const ideal = labels.map((_, i) =>
            n > 1 ? Math.round((total * (1 - i / (n - 1))) * 100) / 100 : 0);

        return { labels, remaining, ideal, total };
    }

    // ─── DERIVED GETTERS (for the template) ───────────────────────────────────
    get hasModel() {
        return this._model.labels.length > 0;
    }

    get isEmpty() {
        return !this.isLoading && !this.hasError && !this.hasModel;
    }

    get committedTotal() {
        return this._model.total;
    }

    get dayCount() {
        return this._model.labels.length;
    }

    // ─── CHART RENDER ─────────────────────────────────────────────────────────
    _renderChart() {
        if (!this._chartJsReady || !this._dataReady) return;
        this.isLoading = false;

        const model = this._model;
        const canvas = this.template.querySelector('canvas.burndown-canvas');
        if (!canvas || !model.labels.length) return;

        if (this._chart) this._chart.destroy();
        this._chart = new window.Chart(canvas, this._chartConfig(model));
    }

    _chartConfig(model) {
        return {
            type: 'line',
            data: {
                labels: model.labels,
                datasets: [
                    {
                        label: 'Remaining',
                        data: model.remaining,
                        borderColor: '#0b5cab',
                        backgroundColor: 'rgba(11, 92, 171, 0.12)',
                        borderWidth: 2,
                        pointRadius: 4,
                        pointBackgroundColor: '#0b5cab',
                        tension: 0,
                        fill: true
                    },
                    {
                        label: 'Ideal',
                        data: model.ideal,
                        borderColor: '#9aa5b1',
                        borderWidth: 1.5,
                        borderDash: [6, 6],
                        pointRadius: 0,
                        tension: 0,
                        fill: false
                    }
                ]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                interaction: { mode: 'index', intersect: false },
                scales: {
                    y: {
                        beginAtZero: true,
                        title: { display: true, text: 'Remaining story points' }
                    },
                    x: {
                        title: { display: true, text: 'Day' }
                    }
                },
                plugins: {
                    legend: { position: 'top' },
                    title: {
                        display: true,
                        text: `Sprint Burndown — committed ${model.total} pts`
                    }
                }
            }
        };
    }

    // ─── HELPERS / ERROR CHANNEL ──────────────────────────────────────────────
    _num(v) {
        const n = Number(v);
        return Number.isFinite(n) ? n : 0;
    }

    _fail(message) {
        this.isLoading = false;
        this.hasError = true;
        this.errorMessage = message || 'Something went wrong.';
        this.dispatchEvent(new ShowToastEvent({
            title: 'Burndown error',
            message: this.errorMessage,
            variant: 'error'
        }));
    }

    _reduce(error) {
        return (error && error.body && error.body.message)
            || (error && error.message)
            || 'Unknown error';
    }
}
