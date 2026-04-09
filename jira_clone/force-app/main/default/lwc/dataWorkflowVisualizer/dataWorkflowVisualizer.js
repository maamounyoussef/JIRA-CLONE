import { LightningElement, api, track } from 'lwc';

export default class DataWorkflowVisualizer extends LightningElement {
    @api workflowData;
    @track statusPositions = {};
    @track transitionLines = [];
    @track sortedStatuses = [];
    
    // Configuration for visualization
    statusWidth = 120;
    statusHeight = 60;
    horizontalSpacing = 180;
    verticalSpacing = 120;
    svgPadding = 40;

    connectedCallback() {
        this.processWorkflowData();
    }

    @api
    get workflow() {
        return this.workflowData;
    }

    set workflow(value) {
        this.workflowData = value;
        this.processWorkflowData();
    }

    /**
     * Process workflow data and calculate positions
     */
    processWorkflowData() {
        if (!this.workflowData || !this.workflowData.workflow) {
            return;
        }

        // Extract all statuses using ID as key (prevents duplicates)
        const statusMap = new Map();
        
        // Add all statuses from projectStatus
        if (this.workflowData.projectStatus && this.workflowData.projectStatus.length > 0) {
            this.workflowData.projectStatus.forEach(status => {
                statusMap.set(status.id, { id: status.id, name: status.name });
            });
        }

        // Also extract any statuses mentioned in transitions that aren't in projectStatus
        if (this.workflowData.workflow.transitions) {
            this.workflowData.workflow.transitions.forEach(transition => {
                if (transition.fromStatus && !statusMap.has(transition.fromStatus)) {
                    statusMap.set(transition.fromStatus, { id: transition.fromStatus, name: transition.fromStatus });
                }
                if (transition.toStatus && !statusMap.has(transition.toStatus)) {
                    statusMap.set(transition.toStatus, { id: transition.toStatus, name: transition.toStatus });
                }
            });
        }

        this.sortedStatuses = Array.from(statusMap.values());
        this.calculatePositions();
        this.calculateTransitionLines();
    }

    /**
     * Calculate positions for each status in a grid layout
     */
    calculatePositions() {
        this.statusPositions = {};
        
        // Optimize layout: 4 per row for standard layout
        const statusesPerRow = 4;
        
        this.sortedStatuses.forEach((status, index) => {
            const row = Math.floor(index / statusesPerRow);
            const col = index % statusesPerRow;
            
            const x = this.svgPadding + col * this.horizontalSpacing;
            const y = this.svgPadding + row * this.verticalSpacing;
            
            // Use status ID as key for positioning
            this.statusPositions[status.id] = {
                x,
                y,
                width: this.statusWidth,
                height: this.statusHeight
            };
        });
    }

    /**
     * Calculate lines for transitions
     */
    calculateTransitionLines() {
        if (!this.workflowData.workflow.transitions) {
            this.transitionLines = [];
            return;
        }

        this.transitionLines = this.workflowData.workflow.transitions.map(transition => {
            // Look up positions using IDs (from/to status IDs)
            const fromPos = this.statusPositions[transition.fromStatus];
            const toPos = this.statusPositions[transition.toStatus];

            if (!fromPos || !toPos) {
                return null;
            }

            // Calculate line coordinates (center of rectangles)
            const fromX = fromPos.x + fromPos.width / 2;
            const fromY = fromPos.y + fromPos.height / 2;
            const toX = toPos.x + toPos.width / 2;
            const toY = toPos.y + toPos.height / 2;

            // Create a path from one rectangle to another with arrow
            const path = this.createArrowPath(fromX, fromY, toX, toY);

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
    createArrowPath(x1, y1, x2, y2) {
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
    get svgViewBox() {
        const statusesPerRow = 4;
        const maxRow = Math.ceil(this.sortedStatuses.length / statusesPerRow);
        const width = this.svgPadding * 2 + 3 * this.horizontalSpacing + this.statusWidth;
        const height = this.svgPadding * 2 + (maxRow - 1) * this.verticalSpacing + this.statusHeight;
        return `0 0 ${width} ${height}`;
    }

    /**
     * Get statuses with SVG rendering data
     * Uses status ID as unique key, displays status name
     */
    get statusesWithSVGData() {
        return this.sortedStatuses.map(status => {
            const pos = this.statusPositions[status.id];
            return {
                id: status.id, // Unique identifier
                name: status.name, // Display name
                x: pos?.x || 0,
                y: pos?.y || 0,
                width: this.statusWidth,
                height: this.statusHeight,
                textX: (pos?.x || 0) + this.statusWidth / 2,
                textY: (pos?.y || 0) + this.statusHeight / 2
            };
        });
    }

    /**
     * Get marker arrow path for line endings
     */
    get markerArrow() {
        return 'M 0 0 L 6 3 L 0 6 Z';
    }
}
