/**
 * Validation helpers (moved from UI layer into logic, renamed with WorkflowVisualizer prefix)
 */
import WorkflowVisualizerService from './WorkflowVisualizerService.js';

export function validateWorkflowVisualizerStatusInput(name) {
    // Delegate to business validation and convert to UI shape
    const result = WorkflowVisualizerService.validateWorkflowVisualizerStatusName(name);
    return {
        valid: result.valid,
        message: result.message || ''
    };
}

export function validateWorkflowVisualizerTransitionInput(transition) {
    const result = WorkflowVisualizerService.validateWorkflowVisualizerTransition(transition);
    return {
        valid: result.valid,
        message: result.message || ''
    };
}

export default {
    validateWorkflowVisualizerStatusInput,
    validateWorkflowVisualizerTransitionInput
};