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
 * burnupChart — sprint burn-up built from the same Sprint__History payload as
 * the burndown (ReportController.loadBurndownChart).
 *
 * A burn-up plots scope and completed work as two rising lines instead of a
 * single falling "remaining" line. The y-axis carries three series:
 *   • Total story point     — the committed scope, carried forward per day.
 *   • Total ended story point — completed work, carried forward per day.
 *   • Guide                 — straight reference line from 0 up to the commitment.
 *
 * Per-day values use the same rule as the burndown: rows arrive sorted (day,
 * then time), so the last write per day is that day's highest-time (closing)
 * value. When TotalStoryPoint__c rows are trimmed out, the scope line falls back
 * to the peak completed value so it still draws.
 */
export default class BurnupChart extends LightningElement {

    // ─── PRINCIPAL STATE ──────────────────────────────────────────────────────
    _rows = [];                 // raw history rows from Apex (only source of truth)

    // ─── NON-STRUCTURAL FLAGS ─────────────────────────────────────────────────
    isLoading = true;
    hasError = false;
    errorMessage = '';

    // ─── IMPERATIVE / LIBRARY HANDLES (not UI state) ──────────────────────────
    _chart;
    _chartJsReady = false;
    _dataReady = false;
    _scriptRequested = false;

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
                this._fail((res && res.message) || 'Unable to load burn-up data.');
            }
        } catch (e) {
            this._fail(this._reduce(e));
        }
    }

    // ─── DERIVED MODEL ────────────────────────────────────────────────────────
    /**
     * Collapse the raw rows into the burn-up series.
     * @returns {{labels:string[], total:number[], ended:number[], guide:number[], commitment:number}}
     */
    get _model() {
        const rows = this._rows;
        if (!rows.length) {
            return { labels: [], total: [], ended: [], guide: [], commitment: 0 };
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

        // commitment: prefer real TotalStoryPoint__c values; never sit below the
        // highest completed value (ended can't exceed scope).
        let commitment = 0;
        for (const r of rows) {
            if (r.field === FIELD_TOTAL || r.field === FIELD_ENDED) {
                commitment = Math.max(commitment, this._num(r.newValue));
            }
        }

        // Per-day closing values (last write per day wins because rows are sorted).
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

        // Walk days carrying forward the latest known scope + completed values.
        const labels = [];
        const total = [];
        const ended = [];
        let lastTotal = commitment;
        let lastEnded = 0;
        for (const day of dayOrder) {
            if (totalByDay.has(day)) lastTotal = totalByDay.get(day);
            if (endedByDay.has(day)) lastEnded = endedByDay.get(day);
            labels.push(day);
            total.push(lastTotal);
            ended.push(lastEnded);
        }

        // Guide line: straight from 0 up to the commitment across the sprint.
        const n = labels.length;
        const guide = labels.map((_, i) =>
            n > 1 ? Math.round((commitment * (i / (n - 1))) * 100) / 100 : commitment);

        return { labels, total, ended, guide, commitment };
    }

    // ─── DERIVED GETTERS (for the template) ───────────────────────────────────
    get hasModel() {
        return this._model.labels.length > 0;
    }

    get isEmpty() {
        return !this.isLoading && !this.hasError && !this.hasModel;
    }

    get commitment() {
        return this._model.commitment;
    }

    get dayCount() {
        return this._model.labels.length;
    }

    // ─── CHART RENDER ─────────────────────────────────────────────────────────
    _renderChart() {
        if (!this._chartJsReady || !this._dataReady) return;
        this.isLoading = false;

        const model = this._model;
        const canvas = this.template.querySelector('canvas.burnup-canvas');
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
                        label: 'Total story point',
                        data: model.total,
                        borderColor: '#0b5cab',
                        backgroundColor: 'rgba(11, 92, 171, 0.06)',
                        borderWidth: 2,
                        pointRadius: 3,
                        pointBackgroundColor: '#0b5cab',
                        tension: 0,
                        fill: false
                    },
                    {
                        label: 'Total ended story point',
                        data: model.ended,
                        borderColor: '#2e844a',
                        backgroundColor: 'rgba(46, 132, 74, 0.15)',
                        borderWidth: 2,
                        pointRadius: 4,
                        pointBackgroundColor: '#2e844a',
                        tension: 0,
                        fill: true
                    },
                    {
                        label: 'Guide',
                        data: model.guide,
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
                        title: { display: true, text: 'Story points' }
                    },
                    x: {
                        title: { display: true, text: 'Day' }
                    }
                },
                plugins: {
                    legend: { position: 'top' },
                    title: {
                        display: true,
                        text: `Sprint Burn-up — committed ${model.commitment} pts`
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
            title: 'Burn-up error',
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
