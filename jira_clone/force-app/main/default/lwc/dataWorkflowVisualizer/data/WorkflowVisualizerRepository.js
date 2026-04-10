/**
 * WorkflowVisualizerRepository
 * Central place to call Apex (repository pattern). Replace TODOs with actual Apex imports.
 */

// Example Apex import (commented):
// import fetchWorkflowApex from '@salesforce/apex/WorkflowController.fetchWorkflow';
import createStatusApex from '@salesforce/apex/StatusController.createStatus';

export async function fetchWorkflowVisualizerWorkflow(workflowId) {
    // TODO: call Apex method and return result
    // return await fetchWorkflowApex({ workflowId });
    return Promise.resolve(null);
}

export async function createStatus({ name, projectId } = {}) {
    if (!name || !projectId) {
        return Promise.resolve({ success: false, message: 'Name and projectId are required' });
    }

    try {
        // Call Apex controller. StatusController.createStatus returns an APIResponse-like object
        const result = await createStatusApex({ name, projectId });
        return result;
    } catch (err) {
        console.error('Apex createStatus error', err);
        const message = err?.body?.message || err?.message || JSON.stringify(err);
        return { success: false, message };
    }
}

export async function createWorkflowVisualizerTransition(payload) {
    // TODO: call Apex to create transition
    return Promise.resolve({ id: 'tmp-t-' + Date.now(), ...payload });
}

export default {
    fetchWorkflowVisualizerWorkflow,
    createStatus,
    createWorkflowVisualizerTransition
};
