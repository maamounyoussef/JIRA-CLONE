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

        // Calculate line coordinates (center of rectangles)
        const fromX = fromPos.x + fromPos.width / 2;
        const fromY = fromPos.y + fromPos.height / 2;
        const toX = toPos.x + toPos.width / 2;
        const toY = toPos.y + toPos.height / 2;

        // Create a curved path and control point for the Bezier curve
        const { path, ctrlX, ctrlY } = createArrowPath(fromX, fromY, toX, toY);

        // Compute an explicit arrow polygon at the end of the curve (so markers aren't required)
        // Arrow size scales with distance but kept smaller for visual balance
        const distance = Math.sqrt(Math.pow(toX - fromX, 2) + Math.pow(toY - fromY, 2));
        const arrowLength = Math.min(Math.max(distance * 0.08, 6), 16); // between 6 and 16px
        const arrowWidth = Math.min(Math.max(arrowLength * 0.55, 5), 12);

        // Tangent at t=1 for quadratic Bezier is 2*(P2 - P1)
        let dx = toX - ctrlX;
        let dy = toY - ctrlY;
        let len = Math.sqrt(dx * dx + dy * dy);
        if (len === 0) {
            dx = toX - fromX;
            dy = toY - fromY;
            len = Math.sqrt(dx * dx + dy * dy) || 1;
        }
        const ux = dx / len;
        const uy = dy / len;

        // Base center of the arrow (a bit behind the tip)
        const baseCx = toX - ux * arrowLength;
        const baseCy = toY - uy * arrowLength;

        // Perpendicular vector for arrow base width
        const perpX = -uy;
        const perpY = ux;
        const halfW = arrowWidth / 2;

        const b1x = baseCx + perpX * halfW;
        const b1y = baseCy + perpY * halfW;
        const b2x = baseCx - perpX * halfW;
        const b2y = baseCy - perpY * halfW;

        const arrowPath = `M ${toX} ${toY} L ${b1x} ${b1y} L ${b2x} ${b2y} Z`;

        return {
            id: transition.id,
            path,
            arrowPath,
            name: transition.name,
            label: `${transition.fromStatus} → ${transition.toStatus}`,
            startX: fromX,
            startY: fromY,
            endX: toX,
            endY: toY,
            startLabelY: fromY - 12,
            endLabelY: toY - 12,
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
