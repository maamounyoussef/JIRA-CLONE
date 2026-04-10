/**
 * Business logic and validation for workflow visualizer (renamed with WorkflowVisualizer prefix)
 */
import WorkflowVisualizerRepository from '../data/WorkflowVisualizerRepository.js';

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

export default {
    validateWorkflowVisualizerStatusName,
    validateWorkflowVisualizerTransition,
    createWorkflowVisualizerStatus
};
