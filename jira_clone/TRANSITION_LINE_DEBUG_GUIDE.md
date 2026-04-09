# Transition Line Debugging Guide
## dataWorkflowVisualizer Component

---

## Table of Contents
1. [Overview](#overview)
2. [Architecture & Data Flow](#architecture--data-flow)
3. [Transition Line Creation](#transition-line-creation)
4. [Click Handler Logic](#click-handler-logic)
5. [Debugging Techniques](#debugging-techniques)
6. [Common Issues & Solutions](#common-issues--solutions)
7. [Console Logging Points](#console-logging-points)
8. [Step-by-Step Debugging](#step-by-step-debugging)

---

## Overview

The transition line feature visualizes workflow transitions as curved lines connecting status rectangles in an SVG canvas. This guide explains how lines are drawn and how clicks are handled.

### Key Components:
- **SVG Container**: Renders both statuses (rectangles) and transitions (lines)
- **JavaScript Logic**: Calculates positions and handles events
- **CSS Styling**: Provides visual feedback and animations
- **Click Handler**: Detects line clicks and displays transition details

---

## Architecture & Data Flow

### Data Structure
```
workflowData
├── workflow
│   ├── id: string
│   ├── name: string
│   └── transitions: WorkflowTransition[]
│       ├── id: string (IMPORTANT: This is the line ID)
│       ├── name: string (transition name)
│       ├── fromStatus: string (Status ID - source)
│       ├── toStatus: string (Status ID - destination)
│       ├── recordStatus: string (active/pending)
│       └── ... (other fields)
└── projectStatus: Status[]
    ├── id: string
    └── name: string
```

### Event Flow for Transition Line Click
```
1. User clicks on SVG line element
   ↓
2. handleTransitionClick() fires
   ↓
3. Extract lineId from event.currentTarget.dataset.lineId
   ↓
4. Find matching transition object in workflowData.workflow.transitions
   ↓
5. Log to console
   ↓
6. Set selectedTransitionId and showTransitionDetail = true
   ↓
7. workflowTransitionDetail component loads via ID
```

---

## Transition Line Creation

### Step 1: Process Data (processWorkflowData)
**Location:** Lines 37-67 in dataWorkflowVisualizer.js

```javascript
processWorkflowData() {
    if (!this.workflowData || !this.workflowData.workflow) {
        return; // Guard: No data available
    }

    // Create Map to prevent duplicate statuses (key = status ID)
    const statusMap = new Map();
    
    // Add all project statuses
    if (this.workflowData.projectStatus && this.workflowData.projectStatus.length > 0) {
        this.workflowData.projectStatus.forEach(status => {
            statusMap.set(status.id, { id: status.id, name: status.name });
        });
    }

    // Extract statuses from transitions (fallback for orphaned statuses)
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

    this.sortedStatuses = Array.from(statusMap.values()); // Convert Map to Array
    this.calculatePositions();  // Step 2
    this.calculateTransitionLines();  // Step 3
}
```

**Debug Point 1 - Check Data:**
```javascript
console.log('workflowData:', this.workflowData);
console.log('sortedStatuses:', this.sortedStatuses);
console.log('Number of transitions:', this.workflowData.workflow.transitions?.length);
```

### Step 2: Calculate Status Positions (calculatePositions)
**Location:** Lines 69-88 in dataWorkflowVisualizer.js

```javascript
calculatePositions() {
    this.statusPositions = {}; // Object: { [statusId]: { x, y, width, height } }
    
    const statusesPerRow = 4; // 4 statuses per row layout
    
    this.sortedStatuses.forEach((status, index) => {
        const row = Math.floor(index / statusesPerRow);
        const col = index % statusesPerRow;
        
        // Calculate X, Y coordinates
        const x = this.svgPadding + col * this.horizontalSpacing;
        const y = this.svgPadding + row * this.verticalSpacing;
        
        // Store position keyed by STATUS ID (not index!)
        this.statusPositions[status.id] = {
            x,
            y,
            width: this.statusWidth,      // 120
            height: this.statusHeight,    // 60
        };
    });
}
```

**Constants Used:**
```javascript
statusWidth = 120;          // Rectangle width
statusHeight = 60;          // Rectangle height
horizontalSpacing = 180;    // Distance between columns
verticalSpacing = 120;      // Distance between rows
svgPadding = 40;           // Margin from canvas edge
```

**Debug Point 2 - Check Positions:**
```javascript
console.log('statusPositions:', this.statusPositions);
// Should show: { "statusId1": { x: 40, y: 40, width: 120, height: 60 }, ... }
```

### Step 3: Calculate Transition Lines (calculateTransitionLines)
**Location:** Lines 90-120 in dataWorkflowVisualizer.js

```javascript
calculateTransitionLines() {
    if (!this.workflowData.workflow.transitions) {
        this.transitionLines = [];
        return;
    }

    // Map each transition to a line object with SVG path
    this.transitionLines = this.workflowData.workflow.transitions.map(transition => {
        // CRITICAL: Use transition.fromStatus and transition.toStatus as keys!
        // These are STATUS IDs (e.g., "a04d2000002yuarAAA")
        const fromPos = this.statusPositions[transition.fromStatus];
        const toPos = this.statusPositions[transition.toStatus];

        // Guard: If either position not found, skip this line
        if (!fromPos || !toPos) {
            console.warn('Position not found for transition:', transition.id);
            return null;
        }

        // Calculate center points of rectangles
        const fromX = fromPos.x + fromPos.width / 2;   // Left side center X
        const fromY = fromPos.y + fromPos.height / 2;  // Left side center Y
        const toX = toPos.x + toPos.width / 2;         // Right side center X
        const toY = toPos.y + toPos.height / 2;        // Right side center Y

        // Generate SVG path with curve
        const path = this.createArrowPath(fromX, fromY, toX, toY);

        // Return line object used in template
        return {
            id: transition.id,                    // IMPORTANT: Store transition ID
            path,                                 // SVG path string
            name: transition.name,                // Transition name
            label: `${transition.fromStatus} → ${transition.toStatus}`
        };
    }).filter(line => line !== null);  // Remove null entries
}
```

**What Gets Stored in transitionLines:**
```javascript
[
    {
        id: "a04d2000003abc123",           // Transition record ID (used for click detection)
        path: "M 100 100 Q 150 50 200 100", // SVG Bezier curve
        name: "Start Work",
        label: "a04d...111 → a04d...222"
    },
    // ... more transitions
]
```

**Debug Point 3 - Check Transition Lines:**
```javascript
console.log('transitionLines:', this.transitionLines);
// Should match transition objects in workflowData.workflow.transitions by ID
```

### Step 4: Create Arrow Path (createArrowPath)
**Location:** Lines 122-147 in dataWorkflowVisualizer.js

This creates a **quadratic Bezier curve** (smooth curved line):

```javascript
createArrowPath(x1, y1, x2, y2) {
    // x1, y1 = start point (from status center)
    // x2, y2 = end point (to status center)
    
    // Calculate midpoint
    const midX = (x1 + x2) / 2;
    const midY = (y1 + y2) / 2;
    
    // Calculate distance between points
    const distance = Math.sqrt(Math.pow(x2 - x1, 2) + Math.pow(y2 - y1, 2));
    const curveHeight = Math.min(distance * 0.3, 80); // 30% of distance, max 80px
    
    // Calculate perpendicular vector (for curve direction)
    const dx = x2 - x1;
    const dy = y2 - y1;
    const len = Math.sqrt(dx * dx + dy * dy);
    const perpX = -dy / len;  // Perpendicular X
    const perpY = dx / len;   // Perpendicular Y
    
    // Control point = midpoint + perpendicular offset
    const ctrlX = midX + perpX * curveHeight;
    const ctrlY = midY + perpY * curveHeight;
    
    // Generate SVG Path Command: "M x1 y1 Q ctrlX ctrlY x2 y2"
    // M = Move to (x1, y1)
    // Q = Quadratic Bezier to (x2, y2) with control point (ctrlX, ctrlY)
    return `M ${x1} ${y1} Q ${ctrlX} ${ctrlY} ${x2} ${y2}`;
}
```

**Visual Representation:**
```
From Status              To Status
   [FROM]                 [TO]
       ●—————————●———————————●
     (x1,y1)  (ctrl)    (x2,y2)
              (curve point above/below)
```

---

## Click Handler Logic

### HTML Template Structure
**Location:** Lines 50-56 in dataWorkflowVisualizer.html

```html
<!-- Transition Lines -->
<template for:each={transitionLines} for:item="line">
    <g key={line.id} class="transition-line-group" data-line-id={line.id} onclick={handleTransitionClick}>
        <path
            class="transition-line"
            d={line.path}
            stroke="#1b96ff"
            stroke-width="2"
            fill="none"
            marker-end="url(#arrowhead)"
        ></path>
    </g>
</template>
```

**Key Attributes:**
- `key={line.id}`: LWC unique identifier
- `data-line-id={line.id}`: HTML attribute storing transition ID
- `onclick={handleTransitionClick}`: Click event handler
- `d={line.path}`: SVG path data

### Click Handler Execution
**Location:** Lines 213-230 in dataWorkflowVisualizer.js

```javascript
handleTransitionClick(event) {
    // Step 1: Extract transition ID from HTML attribute
    const lineId = event.currentTarget.dataset.lineId;
    
    // Step 2: Find matching transition in data
    const transition = this.workflowData.workflow.transitions.find(t => t.id === lineId);
    
    // Step 3: Log to console (DEBUGGING!)
    console.log('Transition Clicked:', {
        id: lineId,
        name: transition?.name,
        fromStatus: transition?.fromStatus,
        toStatus: transition?.toStatus,
        fullObject: transition
    });

    // Step 4: Update component state
    this.selectedTransitionId = lineId;          // Store line ID
    this.showTransitionDetail = true;             // Show detail panel

    // Step 5: Child component workflowTransitionDetail receives:
    //   - transition-id={selectedTransitionId}
    //   - Then calls getWorkflowTransitionById(lineId)
}
```

**Event Object Details:**
```javascript
event.currentTarget         // The g element (SVG group)
event.currentTarget.dataset // { lineId: "a04d2000003abc123" }
event.currentTarget.dataset.lineId  // The transition ID
```

---

## Debugging Techniques

### 1. Browser DevTools

#### Open Console
```
Press: F12 or Ctrl+Shift+I → Console tab
```

#### Add Breakpoints in Template
Insert debug output in HTML:
```html
<!-- Temporary debug display -->
<div style="position: fixed; top: 10px; right: 10px; background: #ffeb3b; padding: 10px; z-index: 9999;">
    <pre>{transitionLines.length} lines | {selectedTransitionId}</pre>
</div>
```

#### Inspect SVG
```
Right-click > Inspect Element → Elements tab
Shows: <g data-line-id="..." onclick="...">
```

### 2. Console Debugging

#### Check Initial State
```javascript
// In Browser Console:
// After component loads
$0.workflowData
$0.transitionLines
$0.statusPositions
```

#### Log All Transitions
```javascript
// In Browser Console:
$0.workflowData.workflow.transitions.forEach(t => {
    console.log(`${t.id}: ${t.name} (${t.fromStatus} → ${t.toStatus})`);
});
```

#### Manually Trigger Click
```javascript
// In Browser Console - Simulate click:
const event = { currentTarget: { dataset: { lineId: 'YOUR_TRANSITION_ID' } } };
$0.handleTransitionClick(event);
```

### 3. Add Debug Logging

Add this to `calculateTransitionLines()`:
```javascript
calculateTransitionLines() {
    if (!this.workflowData.workflow.transitions) {
        this.transitionLines = [];
        console.warn('No transitions found');
        return;
    }

    console.log('=== CALCULATING TRANSITION LINES ===');
    console.table(this.statusPositions);

    this.transitionLines = this.workflowData.workflow.transitions.map((transition, index) => {
        const fromPos = this.statusPositions[transition.fromStatus];
        const toPos = this.statusPositions[transition.toStatus];

        console.log(`Line ${index}:`, {
            id: transition.id,
            name: transition.name,
            from: transition.fromStatus,
            to: transition.toStatus,
            fromPosFound: !!fromPos,
            toPosFound: !!toPos
        });

        if (!fromPos || !toPos) {
            console.error(`Missing position for transition: ${transition.id}`);
            return null;
        }

        const fromX = fromPos.x + fromPos.width / 2;
        const fromY = fromPos.y + fromPos.height / 2;
        const toX = toPos.x + toPos.width / 2;
        const toY = toPos.y + toPos.height / 2;

        const path = this.createArrowPath(fromX, fromY, toX, toY);

        return {
            id: transition.id,
            path,
            name: transition.name,
            label: `${transition.fromStatus} → ${transition.toStatus}`
        };
    }).filter(line => line !== null);

    console.log('Transition Lines Created:', this.transitionLines.length);
}
```

---

## Common Issues & Solutions

### Issue 1: Lines Not Appearing
**Symptoms:** SVG renders but no transition lines visible

**Debug Steps:**
```javascript
// 1. Check if lines are calculated
console.log('transitionLines.length:', this.transitionLines.length);

// 2. Check if statuses have positions
console.log('statusPositions keys:', Object.keys(this.statusPositions));

// 3. Check if transitions reference valid status IDs
this.workflowData.workflow.transitions.forEach(t => {
    const hasFromStatus = this.statusPositions.hasOwnProperty(t.fromStatus);
    const hasToStatus = this.statusPositions.hasOwnProperty(t.toStatus);
    console.log(`${t.name}: from=${hasFromStatus}, to=${hasToStatus}`);
});
```

**Solutions:**
- Verify transition.fromStatus and transition.toStatus are valid status IDs
- Check if status IDs match between projectStatus and transition references
- Ensure calculations happened via `this.processWorkflowData()`

### Issue 2: Click Not Triggering Detail Panel
**Symptoms:** Clicking line doesn't show transition details

**Debug Steps:**
```javascript
// In handleTransitionClick, add:
console.log('Event:', event);
console.log('LineId:', event.currentTarget.dataset.lineId);
console.log('Found transition:', this.workflowData.workflow.transitions.find(t => t.id === event.currentTarget.dataset.lineId));
```

**Solutions:**
- Verify `data-line-id={line.id}` is in HTML (check Inspect Element)
- Check console for transition found/not found
- Ensure `workflowData.workflow.transitions` array exists

### Issue 3: Wrong Transition Details When Clicking
**Symptoms:** Clicking one line shows data from different line

**Root Cause:** Line ID mismatch - typically:
- `transition.id` doesn't match `line.id`
- Multiple transitions with same ID
- ID not passed correctly to template

**Debug Steps:**
```javascript
// Check IDs match
this.transitionLines.forEach((line, idx) => {
    const transition = this.workflowData.workflow.transitions[idx];
    if (line.id !== transition.id) {
        console.error(`ID Mismatch at index ${idx}: line=${line.id}, transition=${transition.id}`);
    }
});
```

### Issue 4: Lines Pass Through or Over Rectangles
**Symptoms:** Curved lines go through status boxes instead of around them

**Root Cause:** Curve calculation `curveHeight` too small or control point calculation wrong

**Solution:** Adjust curve parameters:
```javascript
// In createArrowPath, increase curve:
const curveHeight = Math.min(distance * 0.5, 120); // Was 0.3, 80
```

---

## Console Logging Points

### Essential Logging Locations

**1. Input Data (processWorkflowData)**
```javascript
console.group('🔵 Workflow Data Received');
console.log('Total statuses:', this.workflowData.projectStatus?.length);
console.log('Total transitions:', this.workflowData.workflow.transitions?.length);
console.log('Workflow:', this.workflowData.workflow);
console.groupEnd();
```

**2. Position Calculation (calculatePositions)**
```javascript
console.group('📍 Status Positions');
console.log('Layout: 4 per row, spacing:', this.horizontalSpacing);
console.table(this.statusPositions);
console.groupEnd();
```

**3. Line Creation (calculateTransitionLines)**
```javascript
console.group('📈 Transition Lines');
console.log('Lines created:', this.transitionLines.length);
this.transitionLines.forEach(line => {
    console.log(`  ${line.id}: ${line.name}`);
});
console.groupEnd();
```

**4. Click Detection (handleTransitionClick)**
```javascript
console.group('🖱️ Transition Clicked');
console.log('Transition ID:', lineId);
console.log('Transition Data:', transition);
console.log('Show Detail:', this.showTransitionDetail);
console.groupEnd();
```

---

## Step-by-Step Debugging

### Scenario: "I clicked a line but nothing happened"

**Step 1: Check if line exists**
```javascript
// Console
$0.transitionLines
// Should show array with objects containing "id", "path", "name"
```

**Step 2: Check line is clickable**
```javascript
// In Inspector, hover over line in SVG
// Should see: <g data-line-id="..."> with onclick handler
```

**Step 3: Check click handler fired**
```javascript
// Add to handleTransitionClick temporarily:
handleTransitionClick(event) {
    alert('Line clicked! ID: ' + event.currentTarget.dataset.lineId);
    // ... rest of code
}
```

**Step 4: Check transition found**
```javascript
// Console, with a known transition ID:
$0.workflowData.workflow.transitions.find(t => t.id === 'YOUR_ID')
// Should return object with name, fromStatus, toStatus
```

**Step 5: Check state updated**
```javascript
// Console
$0.selectedTransitionId
$0.showTransitionDetail
// Should show ID and true respectively
```

**Step 6: Check child component rendered**
```javascript
// Inspector - look for <c-workflow-transition-detail> element
// Should have transition-id attribute set
```

### Scenario: "Lines show wrong data after data refresh"

**Step 1: Check data reprocess**
```javascript
// After data update:
$0.processWorkflowData()
console.log('Old lines:', $0.transitionLines.length);
// Then look at new count
```

**Step 2: Verify IDs unchanged**
```javascript
// Check if transition IDs are stable
$0.workflowData.workflow.transitions.map(t => t.id)
```

**Step 3: Check for ID collisions**
```javascript
// Detect duplicate IDs
const ids = $0.transitionLines.map(l => l.id);
const duplicates = ids.filter((id, idx) => ids.indexOf(id) !== idx);
console.log('Duplicate IDs:', duplicates);
```

---

## Performance Optimization Tips

### Monitor Rendering
```javascript
// Add performance marks
performance.mark('transition-calculation-start');
this.calculateTransitionLines();
performance.mark('transition-calculation-end');
performance.measure('Transition Calc', 'transition-calculation-start', 'transition-calculation-end');

console.table(performance.getEntriesByName('Transition Calc'));
```

### Check Rerender Triggers
```javascript
// LWC tracks visible properties - excessive @track can cause redraws:
// ✅ Good: Only track what's needed for rendering
// ❌ Bad: @track largeArray = entire workflow data multiple times
```

---

## Reference: Key Variables

| Variable | Type | Purpose | Debug Command |
|----------|------|---------|---|
| `workflowData` | Object | Input data | `$0.workflowData` |
| `transitionLines` | Array | Display lines | `$0.transitionLines` |
| `statusPositions` | Object | Cached positions | `$0.statusPositions` |
| `sortedStatuses` | Array | Unique statuses | `$0.sortedStatuses` |
| `selectedTransitionId` | String | Current selection | `$0.selectedTransitionId` |
| `showTransitionDetail` | Boolean | Panel visibility | `$0.showTransitionDetail` |

---

## Quick Reference: SVG Path Format

```
M x y      = Move to (x, y)
L x y      = Line to (x, y)
Q cx cy x y = Quadratic Bezier to (x, y) with control point (cx, cy)
A rx ry ... = Arc
Z          = Close path

Example: "M 100 100 Q 150 50 200 100"
- Move to (100, 100)
- Quadratic Bezier curve through control point (150, 50) to (200, 100)
```

---

## Useful Commands for DevTools

```javascript
// Copy formatted transition data to clipboard
copy(JSON.stringify($0.transitionLines, null, 2))

// Reload component
$0.processWorkflowData()

// Get SVG element
$0.template.querySelector('svg')

// Get all lines
$0.template.querySelectorAll('.transition-line-group')

// Simulate click on first line
$0.template.querySelectorAll('.transition-line-group')[0].click()

// Check if child component loaded
$0.template.querySelector('c-workflow-transition-detail')
```

---

## Summary

### How It Works:
1. **Data arrives** in `workflowData` property
2. **Positions calculated** for each status (grid layout)
3. **Paths generated** using quadratic Bezier curves
4. **SVG renders** with clickable line elements
5. **Click detected** via `data-line-id` attribute
6. **Transition found** by ID matching
7. **Detail panel shown** with transition data

### To Debug:
- Use console logs at each step
- Check if IDs match between transitions and lines
- Verify positions calculated for all statuses
- Inspect SVG to see data attributes
- Monitor click events firing

---

*Last Updated: April 9, 2026*
*Component: dataWorkflowVisualizer.js (.js, .html, .css)*
