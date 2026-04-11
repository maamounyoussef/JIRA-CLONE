/**
 * WorkflowVisualizerRepository
 * Central place to call Apex (repository pattern). Replace TODOs with actual Apex imports.
 */

// Example Apex import (commented):
// import fetchWorkflowApex from '@salesforce/apex/WorkflowController.fetchWorkflow';
import createStatusApex from '@salesforce/apex/StatusController.createStatus';
import { workflowVisualizerStatusFromApex, workflowVisualizerTransitionFromApex } from './WorkflowVisualizerDTO.js';

/**
 * Normalize raw workflow data (from Apex) to a predictable client DTO shape.
 * Handles both Apex shapes and already-normalized shapes.
 */
export function normalizeWorkflowData(raw = {}) {
    const normalized = {
        id: raw?.workflow?.id || raw?.id,
        projectStatus: [],
        workflow: { transitions: [] }
    };

    // Normalize statuses (handle Apex shape with Id/Name or already normalized id/name)
    if (Array.isArray(raw.projectStatus) && raw.projectStatus.length) {
        normalized.projectStatus = raw.projectStatus.map(s => {
            if (s.Id || s.Name) return workflowVisualizerStatusFromApex(s);
            return { id: s.id || s.Id || '', name: s.name || s.Name || '' };
        });
    }

    // Normalize transitions (handle Apex shape or already-normalized)
    if (raw.workflow && Array.isArray(raw.workflow.transitions) && raw.workflow.transitions.length) {
        normalized.workflow.transitions = raw.workflow.transitions.map(t => {
            if (t.Id || t.Name || t.FromStatusId) return workflowVisualizerTransitionFromApex(t);
            return {
                id: t.id || t.Id || '',
                name: t.name || t.Name || '',
                fromStatus: t.fromStatus || t.FromStatus || t.from || '',
                toStatus: t.toStatus || t.ToStatus || t.to || '',
                recordStatus: t.recordStatus || t.RecordStatus || 'pending'
            };
        });
    }

    return normalized;
}

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
    normalizeWorkflowData,
    fetchWorkflowVisualizerWorkflow,
    createStatus,
    createWorkflowVisualizerTransition
};
