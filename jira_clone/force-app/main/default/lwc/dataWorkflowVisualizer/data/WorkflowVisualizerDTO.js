/**
 * DTO helpers for Apex responses (renamed with WorkflowVisualizer prefix)
 * Map server property names to a stable client DTO shape
 */

export function workflowVisualizerStatusFromApex(apexStatus = {}) {
    return {
        id: apexStatus.Id || apexStatus.id || String(apexStatus.sfid || apexStatus.externalId || ''),
        name: apexStatus.Name || apexStatus.name || apexStatus.label || ''
    };
}

export function workflowVisualizerTransitionFromApex(apexTransition = {}) {
    return {
        id: apexTransition.Id || apexTransition.id || '',
        name: apexTransition.Name || apexTransition.name || '',
        fromStatus: apexTransition.FromStatusId || apexTransition.fromStatus || apexTransition.from || '',
        toStatus: apexTransition.ToStatusId || apexTransition.toStatus || apexTransition.to || '',
        recordStatus: apexTransition.RecordStatus || apexTransition.recordStatus || 'pending'
    };
}

export default {
    workflowVisualizerStatusFromApex,
    workflowVisualizerTransitionFromApex
};
