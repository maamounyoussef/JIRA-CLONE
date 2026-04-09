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

        // Create a path from one rectangle to another with arrow
        const path = createArrowPath(fromX, fromY, toX, toY);

        return {
            id: transition.id,
            path,
            name: transition.name,
            label: `${transition.fromStatus} → ${transition.toStatus}`
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
    return `M ${x1} ${y1} Q ${ctrlX} ${ctrlY} ${x2} ${y2}`;
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
