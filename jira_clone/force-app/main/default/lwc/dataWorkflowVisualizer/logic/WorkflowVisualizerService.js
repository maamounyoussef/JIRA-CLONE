/**
 * Business logic and validation for workflow visualizer (renamed with WorkflowVisualizer prefix)
 */
import WorkflowVisualizerRepository from '../data/WorkflowVisualizerRepository.js';
import { mapWorkflowVisualizer } from './WorkflowVisualizerMapper.js';

export function validateWorkflowVisualizerStatusName(name) {
    if (!name || typeof name !== 'string' || name.trim().length === 0) {
        return { valid: false, message: 'Name is required' };
    }
    if (name.length > 80) {
        return { valid: false, message: 'Name must be 80 characters or less' };
    }
    return { valid: true };
}

export function validateWorkflowVisualizerTransition(transition) {
    if (!transition) return { valid: false, message: 'Transition required' };
    if (!transition.fromStatus || !transition.toStatus) {
        return { valid: false, message: 'Both from and to statuses are required' };
    }
    if (transition.fromStatus === transition.toStatus) {
        return { valid: false, message: 'From and To cannot be the same status' };
    }
    return { valid: true };
}

/**
 * Create a new status via repository after validation.
 * Returns the repository/Apex response shape: { success, data, message }
 */
export async function createWorkflowVisualizerStatus(name, projectId) {
    const validation = validateWorkflowVisualizerStatusName(name);
    if (!validation.valid) {
        return { success: false, message: validation.message };
    }
    if (!projectId) {
        return { success: false, message: 'Project ID is required' };
    }

    try {
        const result = await WorkflowVisualizerRepository.createStatus({ name, projectId });
        return result;
    } catch (err) {
        console.error('WorkflowVisualizerService.createStatus error', err);
        const message = err?.body?.message || err?.message || String(err);
        return { success: false, message };
    }
}

/**
 * Process normalized workflow data: map to business model, gather statuses, and ensure completeness.
 * Returns { workflowModel, sortedStatuses, allTransitions }
 */
export function processWorkflowVisualizerData(normalizedData = {}) {
    // Map to business model using the mapper
    const workflowModel = mapWorkflowVisualizer(normalizedData);

    // Gather statuses and transitions from the business model
    const statusMap = new Map();
    workflowModel.statuses.forEach(s => statusMap.set(s.id, { id: s.id, name: s.name }));

    // Map transitions for easier processing
    const allTransitions = workflowModel.transitions.map(t => ({
        id: t.id,
        name: t.name,
        fromStatus: t.fromStatus,
        toStatus: t.toStatus,
        recordStatus: t.recordStatus
    }));

    // Ensure any statuses referenced by transitions are included
    allTransitions.forEach(transition => {
        if (transition.fromStatus && !statusMap.has(transition.fromStatus)) {
            statusMap.set(transition.fromStatus, { id: transition.fromStatus, name: transition.fromStatus });
        }
        if (transition.toStatus && !statusMap.has(transition.toStatus)) {
            statusMap.set(transition.toStatus, { id: transition.toStatus, name: transition.toStatus });
        }
    });

    const sortedStatuses = Array.from(statusMap.values());

    return {
        workflowModel,
        sortedStatuses,
        allTransitions
    };
}

export default {
    validateWorkflowVisualizerStatusName,
    validateWorkflowVisualizerTransition,
    createWorkflowVisualizerStatus,
    processWorkflowVisualizerData
};
