/**
 * Visualization configuration
 */
export const VISUALIZATION_CONFIG = {
    statusWidth: 120,
    statusHeight: 60,
    horizontalSpacing: 180,
    verticalSpacing: 120,
    svgPadding: 40,
    statusesPerRow: 4
};

/**
 * Calculate positions for each status in a grid layout
 */
export function calculatePositions(sortedStatuses, config = VISUALIZATION_CONFIG) {
    const statusPositions = {};
    const statusesPerRow = 4;
    
    sortedStatuses.forEach((status, index) => {
        const row = Math.floor(index / statusesPerRow);
        const col = index % statusesPerRow;
        
        const x = config.svgPadding + col * config.horizontalSpacing;
        const y = config.svgPadding + row * config.verticalSpacing;
        
        // Use status ID as key for positioning
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
 * Compute intersection point between a ray from (cx,cy) towards (px,py) and the rectangle boundary.
 * Returns {x,y} on the rectangle edge. If no intersection found, returns the center (cx,cy).
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
 * Calculate lines for transitions
 */
export function calculateTransitionLines(workflowData, statusPositions, config = VISUALIZATION_CONFIG) {
    if (!workflowData || !workflowData.workflow || !workflowData.workflow.transitions) {
        return [];
    }

    return workflowData.workflow.transitions.map(transition => {
        // Look up positions using IDs (from/to status IDs)
        const fromPos = statusPositions[transition.fromStatus];
        const toPos = statusPositions[transition.toStatus];

        if (!fromPos || !toPos) {
            return null;
        }

        // Calculate center points for each rectangle
        const fromCenterX = fromPos.x + fromPos.width / 2;
        const fromCenterY = fromPos.y + fromPos.height / 2;
        const toCenterX = toPos.x + toPos.width / 2;
        const toCenterY = toPos.y + toPos.height / 2;

        // Compute start/end points at rectangle borders (towards the other rect)
        const startPt = getRectIntersection(fromPos, fromCenterX, fromCenterY, toCenterX, toCenterY);
        const endPt = getRectIntersection(toPos, toCenterX, toCenterY, fromCenterX, fromCenterY);

        // Create a curved path (quadratic Bezier) between the border points
        const { path, ctrlX, ctrlY } = createArrowPath(startPt.x, startPt.y, endPt.x, endPt.y);

        // Compute an explicit arrow polygon at the true end of the curve
        const distance = Math.sqrt(Math.pow(endPt.x - startPt.x, 2) + Math.pow(endPt.y - startPt.y, 2));
        const arrowLength = Math.min(Math.max(distance * 0.08, 6), 16);
        const arrowWidth = Math.min(Math.max(arrowLength * 0.55, 5), 12);

        // Tangent at t=1 for quadratic Bezier is based on control point
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

        const arrowPath = `M ${endPt.x} ${endPt.y} L ${b1x} ${b1y} L ${b2x} ${b2y} Z`;

        return {
            id: transition.id,
            path,
            arrowPath,
            name: transition.name,
            label: `${transition.fromStatus} → ${transition.toStatus}`,
            startX: startPt.x,
            startY: startPt.y,
            endX: endPt.x,
            endY: endPt.y,
            startLabelY: startPt.y - 10,
            endLabelY: endPt.y - 10,
            fromStatus: transition.fromStatus,
            toStatus: transition.toStatus
        };
    }).filter(line => line !== null);
}

/**
 * Create an SVG path with curved arrow for transition line
 * Uses quadratic Bezier curve to avoid passing through other rectangles
 */
export function createArrowPath(x1, y1, x2, y2) {
    // Calculate control point for curve (above the line)
    const midX = (x1 + x2) / 2;
    const midY = (y1 + y2) / 2;
    
    // Curve height based on distance between points
    const distance = Math.sqrt(Math.pow(x2 - x1, 2) + Math.pow(y2 - y1, 2));
    const curveHeight = Math.min(distance * 0.3, 80);
    
    // Calculate perpendicular vector to control the curve direction
    const dx = x2 - x1;
    const dy = y2 - y1;
    const len = Math.sqrt(dx * dx + dy * dy);
    const perpX = -dy / len;
    const perpY = dx / len;
    
    // Control point offset from midpoint
    const ctrlX = midX + perpX * curveHeight;
    const ctrlY = midY + perpY * curveHeight;
    
    // Quadratic Bezier curve
    const path = `M ${x1} ${y1} Q ${ctrlX} ${ctrlY} ${x2} ${y2}`;
    return { path, ctrlX, ctrlY };
}

/**
 * Get SVG viewBox dimensions
 */
export function getSvgViewBox(sortedStatuses, config = VISUALIZATION_CONFIG) {
    const statusesPerRow = 4;
    const maxRow = Math.ceil(sortedStatuses.length / statusesPerRow);
    const width = config.svgPadding * 2 + 3 * config.horizontalSpacing + config.statusWidth;
    const height = config.svgPadding * 2 + (maxRow - 1) * config.verticalSpacing + config.statusHeight;
    return `0 0 ${width} ${height}`;
}

/**
 * Get statuses with SVG rendering data
 * Uses status ID as unique key, displays status name
 */
export function getStatusesWithSVGData(sortedStatuses, statusPositions, config = VISUALIZATION_CONFIG) {
    return sortedStatuses.map(status => {
        const pos = statusPositions[status.id];
        return {
            id: status.id, // Unique identifier
            name: status.name, // Display name
            x: pos?.x || 0,
            y: pos?.y || 0,
            width: config.statusWidth,
            height: config.statusHeight,
            textX: (pos?.x || 0) + config.statusWidth / 2,
            textY: (pos?.y || 0) + config.statusHeight / 2
        };
    });
}

/**
 * Get marker arrow path for line endings
 */
export function getMarkerArrow() {
    return 'M 0 0 L 6 3 L 0 6 Z';
}

export default {
    VISUALIZATION_CONFIG,
    calculatePositions,
    calculateTransitionLines,
    createArrowPath,
    getSvgViewBox,
    getStatusesWithSVGData,
    getMarkerArrow
};
