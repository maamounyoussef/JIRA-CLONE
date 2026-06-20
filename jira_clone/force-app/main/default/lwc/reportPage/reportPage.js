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
 * reportPage — sprint report combining the burndown and burn-up charts that
 * were previously two standalone components (burndownChart, burnupChart).
 *
 * Both charts read the same Sprint__History payload
 * (ReportController.loadBurndownChart), so this component fetches it once into
 * the principal state `_rows` and derives both chart series from it:
 *   • burndown — a single falling "Remaining" line vs. an ideal straight line.
 *   • burn-up  — rising "Total" and "Total ended" lines vs. a guide line.
 *
 * Per-day values use one shared rule: rows arrive sorted (day, then time), so
 * the last write per day is that day's highest-time (closing) value. When
 * TotalStoryPoint__c rows are trimmed out, the committed scope falls back to the
 * peak completed value so the lines still draw.
 */
export default class ReportPage extends LightningElement {

    // ─── PRINCIPAL STATE ──────────────────────────────────────────────────────
    _rows = [];                 // raw history rows from Apex (only source of truth)
    activeView = 'burndown';    // which card is selected: 'burndown' (principal) | 'burnup' (secondary)

    // ─── NON-STRUCTURAL FLAGS ─────────────────────────────────────────────────
    isLoading = true;
    hasError = false;
    errorMessage = '';

    // ─── IMPERATIVE / LIBRARY HANDLES (not UI state) ──────────────────────────
    _burndownChart;             // Chart.js instance for the burndown
    _burnupChart;               // Chart.js instance for the burn-up
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
                this._renderCharts();
            })
            .catch((e) => {
                this._scriptRequested = false;
                this._fail('Chart.js failed to load: ' + this._reduce(e));
            });
    }

    disconnectedCallback() {
        if (this._burndownChart) {
            this._burndownChart.destroy();
            this._burndownChart = undefined;
        }
        if (this._burnupChart) {
            this._burnupChart.destroy();
            this._burnupChart = undefined;
        }
    }

    // ─── DATA LOAD ────────────────────────────────────────────────────────────
    async _fetchData() {
        try {
            const res = await loadBurndownChart();
            if (res && res.success) {
                this._rows = Array.isArray(res.data) ? res.data : [];
                this._dataReady = true;
                this._renderCharts();
            } else {
                this._fail((res && res.message) || 'Unable to load report data.');
            }
        } catch (e) {
            this._fail(this._reduce(e));
        }
    }

    // ─── SHARED DERIVED FOUNDATION ────────────────────────────────────────────
    /**
     * Collapse the raw rows into the per-day closing values both charts share.
     * @returns {{labels:string[], totalSeries:number[], endedSeries:number[], commitment:number}}
     */
    get _series() {
        const rows = this._rows;
        if (!rows.length) {
            return { labels: [], totalSeries: [], endedSeries: [], commitment: 0 };
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
        const totalSeries = [];
        const endedSeries = [];
        let lastTotal = commitment;
        let lastEnded = 0;
        for (const day of dayOrder) {
            if (totalByDay.has(day)) lastTotal = totalByDay.get(day);
            if (endedByDay.has(day)) lastEnded = endedByDay.get(day);
            labels.push(day);
            totalSeries.push(lastTotal);
            endedSeries.push(lastEnded);
        }

        return { labels, totalSeries, endedSeries, commitment };
    }

    // ─── DERIVED MODELS ───────────────────────────────────────────────────────
    /**
     * Burndown: remaining = committed − completed, vs. an ideal straight line.
     * @returns {{labels:string[], remaining:number[], ideal:number[], total:number}}
     */
    get _burndownModel() {
        const { labels, totalSeries, endedSeries, commitment } = this._series;
        const remaining = labels.map((_, i) => totalSeries[i] - endedSeries[i]);
        const n = labels.length;
        const ideal = labels.map((_, i) =>
            n > 1 ? Math.round((commitment * (1 - i / (n - 1))) * 100) / 100 : 0);
        return { labels, remaining, ideal, total: commitment };
    }

    /**
     * Burn-up: rising scope + completed lines, vs. a guide line up to commitment.
     * @returns {{labels:string[], total:number[], ended:number[], guide:number[], commitment:number}}
     */
    get _burnupModel() {
        const { labels, totalSeries, endedSeries, commitment } = this._series;
        const n = labels.length;
        const guide = labels.map((_, i) =>
            n > 1 ? Math.round((commitment * (i / (n - 1))) * 100) / 100 : commitment);
        return {
            labels,
            total: totalSeries,
            ended: endedSeries,
            guide,
            commitment
        };
    }

    // ─── VIEW SELECTION ───────────────────────────────────────────────────────
    /** Card click — switch the active view. `detail.value` is the card's value. */
    handleSelectView(event) {
        const value = event.detail && event.detail.value;
        if (value !== 'burndown' && value !== 'burnup') return;
        this.activeView = value;

        // A chart first drawn inside a display:none panel has a zero-size canvas;
        // once its panel becomes visible, ask Chart.js to re-fit to the container.
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        Promise.resolve().then(() => {
            const chart = value === 'burndown' ? this._burndownChart : this._burnupChart;
            if (chart) chart.resize();
        });
    }

    // ─── DERIVED GETTERS (for the template) ───────────────────────────────────
    get isBurndownActive() {
        return this.activeView === 'burndown';
    }

    get isBurnupActive() {
        return this.activeView === 'burnup';
    }

    /** Wrapper class marking the selected card. */
    get burndownCardClass() {
        return this.isBurndownActive ? 'report__card report__card--active' : 'report__card';
    }

    get burnupCardClass() {
        return this.isBurnupActive ? 'report__card report__card--active' : 'report__card';
    }

    /** Panel class hiding the inactive chart (canvas stays mounted for Chart.js). */
    get burndownPanelClass() {
        return this.isBurndownActive ? 'report__chart' : 'report__chart report__chart--hidden';
    }

    get burnupPanelClass() {
        return this.isBurnupActive ? 'report__chart' : 'report__chart report__chart--hidden';
    }

    get hasModel() {
        return this._series.labels.length > 0;
    }

    get isEmpty() {
        return !this.isLoading && !this.hasError && !this.hasModel;
    }

    get committedTotal() {
        return this._series.commitment;
    }

    get dayCount() {
        return this._series.labels.length;
    }

    // ─── CHART RENDER ─────────────────────────────────────────────────────────
    _renderCharts() {
        if (!this._chartJsReady || !this._dataReady) return;
        this.isLoading = false;

        if (!this._series.labels.length) return;

        this._burndownChart = this._draw(
            'canvas.burndown-canvas',
            this._burndownChart,
            this._burndownConfig(this._burndownModel)
        );
        this._burnupChart = this._draw(
            'canvas.burnup-canvas',
            this._burnupChart,
            this._burnupConfig(this._burnupModel)
        );
    }

    /** Destroy any prior instance and (re)draw onto the matching canvas. */
    _draw(selector, existing, config) {
        const canvas = this.template.querySelector(selector);
        if (!canvas) return existing;
        if (existing) existing.destroy();
        return new window.Chart(canvas, config);
    }

    _burndownConfig(model) {
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

    _burnupConfig(model) {
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
            title: 'Report error',
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
