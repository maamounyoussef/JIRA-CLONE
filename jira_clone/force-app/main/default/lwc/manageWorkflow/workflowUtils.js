/**
 * workflowUtils — pure helpers for the Manage Workflow page.
 *
 * Folds together what used to live in the workflowVisualizer sidecar layers:
 *   - SVG geometry / responsive config (old workflowVisualizerUtil.js)
 *   - Apex-shape → client-shape normalization (old data/WorkflowVisualizerDTO.js
 *     and the normalizeWorkflowData() in data/WorkflowVisualizerRepository.js)
 *   - status gathering (old logic/WorkflowVisualizerService.processWorkflowVisualizerData)
 *
 * Everything here is a pure function. No Apex, no component state.
 */

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                       VISUALIZATION CONFIG                                ║
// ╚══════════════════════════════════════════════════════════════════════════╝

export const VISUALIZATION_CONFIG = {
    statusWidth: 120,
    statusHeight: 60,
    horizontalSpacing: 180,
    verticalSpacing: 120,
    svgPadding: 40,
    statusesPerRow: 4,
    // Arrow size (fixed) to keep all arrow heads consistent
    arrowLength: 10,
    arrowWidth: 10,
    // Visual/tuning variables
    startPointRadius: 5,
    endPointRadius: 5,
    labelOffset: 10,
    // curve tuning
    curveFactor: 0.3,
    maxCurveHeight: 80,
    // line widths
    lineWidth: 3,
    lineHoverWidth: 4,
    lineDashArray: '5,5',
    // rectangle stroke
    rectStrokeWidth: 1.5,
    rectStrokeOpacity: 0.12,
    rectHoverStrokeOpacity: 0.18,
    rectRadius: 10
};

/**
 * Get a responsive config by merging overrides based on container / viewport width.
 * Returns a NEW config object — never mutates the base config.
 */
export function getResponsiveConfig(containerWidth, baseConfig = VISUALIZATION_CONFIG) {
    const overrides = {};

    if (containerWidth <= 480) {
        // Mobile: 2 columns, smaller cards
        overrides.statusesPerRow = 2;
        overrides.statusWidth = 100;
        overrides.statusHeight = 48;
        overrides.horizontalSpacing = 130;
        overrides.verticalSpacing = 90;
        overrides.svgPadding = 20;
        overrides.rectRadius = 8;
        overrides.arrowLength = 8;
        overrides.arrowWidth = 8;
        overrides.lineWidth = 2;
        overrides.lineHoverWidth = 3;
        overrides.startPointRadius = 4;
        overrides.endPointRadius = 4;
    } else if (containerWidth <= 768) {
        // Tablet: 3 columns
        overrides.statusesPerRow = 3;
        overrides.statusWidth = 110;
        overrides.statusHeight = 54;
        overrides.horizontalSpacing = 155;
        overrides.verticalSpacing = 105;
        overrides.svgPadding = 30;
    }
    // Desktop (>768): keep base config as-is

    return { ...baseConfig, ...overrides };
}


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                        DATA NORMALIZATION                                 ║
// ╚══════════════════════════════════════════════════════════════════════════╝

/**
 * Map a raw Apex Status SObject (Id/Name) to the stable client shape {id,name}.
 */
export function statusFromApex(apexStatus = {}) {
    return {
        id: apexStatus.Id || apexStatus.id || String(apexStatus.sfid || apexStatus.externalId || ''),
        name: apexStatus.Name || apexStatus.name || apexStatus.label || ''
    };
}

/**
 * Map a raw Apex WorkflowTransition SObject to the stable client shape.
 * Used for the transition-detail panel, which loads a raw SObject from Apex.
 */
export function transitionFromApex(apexTransition = {}) {
    return {
        id: apexTransition.Id || apexTransition.id || '',
        name: apexTransition.Name || apexTransition.name || '',
        fromStatus: apexTransition.FromStatusId || apexTransition.fromStatus || apexTransition.from || '',
        toStatus: apexTransition.ToStatusId || apexTransition.toStatus || apexTransition.to || '',
        recordStatus: apexTransition.RecordStatus__c || apexTransition.RecordStatus || apexTransition.recordStatus || 'pending',
        createdDate: apexTransition.CreatedDate || apexTransition.createdDate || '',
        fromStatusName: (apexTransition.FromStatus__r && apexTransition.FromStatus__r.Name) || apexTransition.FromStatusName || apexTransition.fromStatusName || '',
        toStatusName: (apexTransition.ToStatus__r && apexTransition.ToStatus__r.Name) || apexTransition.ToStatusName || apexTransition.toStatusName || ''
    };
}

/**
 * Normalize the workflow payload to a predictable client shape.
 * getWorkflow already returns a normalized WorkflowConfigDTO, but we normalize
 * defensively so locally-mutated entries (raw Apex SObjects pushed after a
 * create) are handled the same way.
 */
export function normalizeWorkflowData(raw = {}) {
    const normalized = {
        id: raw?.workflow?.id || raw?.id,
        projectStatus: [],
        workflow: { id: raw?.workflow?.id || '', transitions: [] }
    };

    if (Array.isArray(raw.projectStatus) && raw.projectStatus.length) {
        normalized.projectStatus = raw.projectStatus.map(s => {
            if (s.Id || s.Name) return statusFromApex(s);
            return { id: s.id || s.Id || '', name: s.name || s.Name || '' };
        });
    }

    if (raw.workflow && Array.isArray(raw.workflow.transitions) && raw.workflow.transitions.length) {
        normalized.workflow.transitions = raw.workflow.transitions.map(t => {
            if (t.Id || t.Name || t.FromStatusId) return transitionFromApex(t);
            return {
                id: t.id || t.Id || '',
                name: t.name || t.Name || '',
                fromStatus: t.fromStatus || t.FromStatus || t.from || '',
                toStatus: t.toStatus || t.ToStatus || t.to || '',
                recordStatus: t.recordStatus || t.RecordStatus__c || t.RecordStatus || 'pending'
            };
        });
    }

    return normalized;
}

/**
 * Build the ordered status list to render. Starts from projectStatus and adds
 * any status referenced by a transition but missing from projectStatus.
 */
export function gatherSortedStatuses(normalized = {}) {
    const statusMap = new Map();
    (normalized.projectStatus || []).forEach(s => statusMap.set(s.id, { id: s.id, name: s.name }));
    (normalized.workflow?.transitions || []).forEach(t => {
        if (t.fromStatus && !statusMap.has(t.fromStatus)) {
            statusMap.set(t.fromStatus, { id: t.fromStatus, name: t.fromStatus });
        }
        if (t.toStatus && !statusMap.has(t.toStatus)) {
            statusMap.set(t.toStatus, { id: t.toStatus, name: t.toStatus });
        }
    });
    return Array.from(statusMap.values());
}


// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                          SVG GEOMETRY                                     ║
// ╚══════════════════════════════════════════════════════════════════════════╝

/**
 * Calculate positions for each status in a grid layout.
 */
export function calculatePositions(sortedStatuses, config = VISUALIZATION_CONFIG) {
    const statusPositions = {};
    const statusesPerRow = config.statusesPerRow || 4;

    sortedStatuses.forEach((status, index) => {
        const row = Math.floor(index / statusesPerRow);
        const col = index % statusesPerRow;

        const x = config.svgPadding + col * config.horizontalSpacing;
        const y = config.svgPadding + row * config.verticalSpacing;

        statusPositions[status.id] = {
            x,
            y,
            width: config.statusWidth,
            height: config.statusHeight
        };
    });

    return statusPositions;
}

/**
 * Compute intersection point between a ray from (cx,cy) towards (px,py) and the
 * rectangle boundary. Returns {x,y} on the rectangle edge, or the center if none.
 */
export function getRectIntersection(rect, cx, cy, px, py) {
    const rx = rect.x;
    const ry = rect.y;
    const rw = rect.width;
    const rh = rect.height;

    const dx = px - cx;
    const dy = py - cy;
    const eps = 1e-6;
    const candidates = [];

    if (Math.abs(dx) > eps) {
        // left edge
        let t = (rx - cx) / dx;
        if (t > 0) {
            const y = cy + t * dy;
            if (y >= ry - eps && y <= ry + rh + eps) candidates.push({ t, x: rx, y });
        }
        // right edge
        t = (rx + rw - cx) / dx;
        if (t > 0) {
            const y = cy + t * dy;
            if (y >= ry - eps && y <= ry + rh + eps) candidates.push({ t, x: rx + rw, y });
        }
    }

    if (Math.abs(dy) > eps) {
        // top edge
        let t = (ry - cy) / dy;
        if (t > 0) {
            const x = cx + t * dx;
            if (x >= rx - eps && x <= rx + rw + eps) candidates.push({ t, x, y: ry });
        }
        // bottom edge
        t = (ry + rh - cy) / dy;
        if (t > 0) {
            const x = cx + t * dx;
            if (x >= rx - eps && x <= rx + rw + eps) candidates.push({ t, x, y: ry + rh });
        }
    }

    if (candidates.length === 0) {
        return { x: cx, y: cy };
    }

    candidates.sort((a, b) => a.t - b.t);
    return { x: candidates[0].x, y: candidates[0].y };
}

/**
 * Calculate lines for transitions.
 */
export function calculateTransitionLines(workflowData, statusPositions, config = VISUALIZATION_CONFIG) {
    if (!workflowData || !workflowData.workflow || !workflowData.workflow.transitions) {
        return [];
    }

    return workflowData.workflow.transitions.map(transition => {
        const fromPos = statusPositions[transition.fromStatus];
        const toPos = statusPositions[transition.toStatus];

        if (!fromPos || !toPos) {
            return null;
        }

        const fromCenterX = fromPos.x + fromPos.width / 2;
        const fromCenterY = fromPos.y + fromPos.height / 2;
        const toCenterX = toPos.x + toPos.width / 2;
        const toCenterY = toPos.y + toPos.height / 2;

        const startPt = getRectIntersection(fromPos, fromCenterX, fromCenterY, toCenterX, toCenterY);
        const endPt = getRectIntersection(toPos, toCenterX, toCenterY, fromCenterX, fromCenterY);

        const { ctrlX, ctrlY } = createArrowPath(startPt.x, startPt.y, endPt.x, endPt.y, config);

        const arrowLength = config.arrowLength || 10;
        const arrowWidth = config.arrowWidth || 10;

        // Tangent at t=1 for quadratic Bezier (direction: ctrl → end)
        let dx = endPt.x - ctrlX;
        let dy = endPt.y - ctrlY;
        let len = Math.sqrt(dx * dx + dy * dy);
        if (len === 0) {
            dx = endPt.x - startPt.x;
            dy = endPt.y - startPt.y;
            len = Math.sqrt(dx * dx + dy * dy) || 1;
        }
        const ux = dx / len;
        const uy = dy / len;

        const baseCx = endPt.x - ux * arrowLength;
        const baseCy = endPt.y - uy * arrowLength;
        const perpX = -uy;
        const perpY = ux;
        const halfW = arrowWidth / 2;

        const b1x = baseCx + perpX * halfW;
        const b1y = baseCy + perpY * halfW;
        const b2x = baseCx - perpX * halfW;
        const b2y = baseCy - perpY * halfW;

        // Shorten the bezier curve to end at the arrow base (not the tip).
        const shortenedPath = `M ${startPt.x} ${startPt.y} Q ${ctrlX} ${ctrlY} ${baseCx} ${baseCy}`;

        // Arrow triangle: tip at endPt, base at b1/b2.
        const arrowPath = `M ${endPt.x} ${endPt.y} L ${b1x} ${b1y} L ${b2x} ${b2y} Z`;

        // Midpoint of quadratic bezier curve for label positioning.
        const nameMidX = 0.25 * startPt.x + 0.5 * ctrlX + 0.25 * endPt.x;
        const nameMidY = 0.25 * startPt.y + 0.5 * ctrlY + 0.25 * endPt.y;

        const recordStatus = transition.recordStatus || 'active';
        const groupClass = `transition-line-group ${recordStatus === 'pending' ? 'pending-transition' : 'active-transition'}`;
        const lineClass = `transition-line${recordStatus === 'pending' ? ' pending' : ''}`;
        const arrowClass = `transition-arrow${recordStatus === 'pending' ? ' pending' : ''}`;

        return {
            id: transition.id,
            path: shortenedPath,
            arrowPath,
            name: transition.name,
            label: `${transition.fromStatus} → ${transition.toStatus}`,
            startX: startPt.x,
            startY: startPt.y,
            endX: endPt.x,
            endY: endPt.y,
            startLabelY: startPt.y - (config.labelOffset || 10),
            endLabelY: endPt.y - (config.labelOffset || 10),
            nameMidX: nameMidX,
            nameMidY: nameMidY - 6,
            fromStatus: transition.fromStatus,
            toStatus: transition.toStatus,
            recordStatus,
            groupClass,
            lineClass,
            arrowClass
        };
    }).filter(line => line !== null);
}

/**
 * Create an SVG path with a curved arrow for a transition line.
 * Uses a quadratic Bezier curve to avoid passing through other rectangles.
 */
export function createArrowPath(x1, y1, x2, y2, config = VISUALIZATION_CONFIG) {
    const midX = (x1 + x2) / 2;
    const midY = (y1 + y2) / 2;

    const distance = Math.sqrt(Math.pow(x2 - x1, 2) + Math.pow(y2 - y1, 2));
    const factor = typeof config.curveFactor === 'number' ? config.curveFactor : 0.3;
    const maxH = typeof config.maxCurveHeight === 'number' ? config.maxCurveHeight : 80;
    const curveHeight = Math.min(distance * factor, maxH);

    const dx = x2 - x1;
    const dy = y2 - y1;
    const len = Math.sqrt(dx * dx + dy * dy);
    const perpX = -dy / len;
    const perpY = dx / len;

    const ctrlX = midX + perpX * curveHeight;
    const ctrlY = midY + perpY * curveHeight;

    const path = `M ${x1} ${y1} Q ${ctrlX} ${ctrlY} ${x2} ${y2}`;
    return { path, ctrlX, ctrlY };
}

/**
 * Get SVG viewBox dimensions.
 */
export function getSvgViewBox(sortedStatuses, config = VISUALIZATION_CONFIG) {
    const statusesPerRow = config.statusesPerRow || 4;
    const maxRow = Math.ceil(sortedStatuses.length / statusesPerRow);
    const cols = Math.min(sortedStatuses.length, statusesPerRow);
    const width = config.svgPadding * 2 + (cols - 1) * config.horizontalSpacing + config.statusWidth;
    const height = config.svgPadding * 2 + (maxRow - 1) * config.verticalSpacing + config.statusHeight;
    return `0 0 ${width} ${height}`;
}

/**
 * Get statuses with SVG rendering data. Uses status ID as unique key, displays name.
 */
export function getStatusesWithSVGData(sortedStatuses, statusPositions, config = VISUALIZATION_CONFIG, clickedIds = []) {
    return sortedStatuses.map(status => {
        const pos = statusPositions[status.id];
        const isClicked = Array.isArray(clickedIds) && clickedIds.includes(status.id);
        return {
            id: status.id,
            name: status.name,
            x: pos?.x || 0,
            y: pos?.y || 0,
            width: config.statusWidth,
            height: config.statusHeight,
            textX: (pos?.x || 0) + config.statusWidth / 2,
            textY: (pos?.y || 0) + config.statusHeight / 2,
            groupClass: `status-group${isClicked ? ' clicked' : ''}`
        };
    });
}

/**
 * Get marker arrow path for line endings.
 */
export function getMarkerArrow() {
    return 'M 0 0 L 6 3 L 0 6 Z';
}

/**
 * Toggle a status id in the clicked list and return a new (immutable) array.
 */
export function toggleClick(clickedIds = [], statusId) {
    const set = new Set(Array.isArray(clickedIds) ? clickedIds : []);
    if (set.has(statusId)) {
        set.delete(statusId);
    } else {
        set.add(statusId);
    }
    return Array.from(set);
}

/**
 * Clear all clicked status IDs and return an empty array.
 */
export function clearClicks() {
    return [];
}
