/**
 * WorkflowVisualizerRepository
 * Central place to call Apex (repository pattern). Replace TODOs with actual Apex imports.
 */

// Example Apex import (commented):
// import fetchWorkflowApex from '@salesforce/apex/WorkflowController.fetchWorkflow';
import createStatusApex from '@salesforce/apex/StatusController.createStatus';
import getWorkflowTransitionByIdApex from '@salesforce/apex/WorkflowTransitionController.getWorkflowTransitionById';
import activateWorkflowTransitionApex from '@salesforce/apex/WorkflowTransitionController.activateWorkflowTransition';
import deleteWorkflowTransitionApex from '@salesforce/apex/WorkflowTransitionController.deleteWorkflowTransition';
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
                recordStatus: t.recordStatus || t.RecordStatus__c || t.RecordStatus || 'pending'
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

/**
 * Fetch a single workflow transition by id and normalize it to client DTO
 */
export async function fetchTransitionById(transitionId) {
    if (!transitionId) {
        return Promise.resolve({ success: false, message: 'transitionId is required' });
    }

    try {
        const response = await getWorkflowTransitionByIdApex({ transitionId });

        // Support APIResponse-like wrappers or raw SObject
        const raw = (response && response.success && response.data) ? response.data : response;

        if (!raw) {
            return { success: false, message: 'Transition not found' };
        }

        const normalized = workflowVisualizerTransitionFromApex(raw);
        return { success: true, data: normalized };
    } catch (err) {
        console.error('Apex fetchTransitionById error', err);
        const message = err?.body?.message || err?.message || String(err);
        return { success: false, message };
    }
}

/**
 * Activate a transition via Apex
 */
export async function activateTransition(transitionId) {
    if (!transitionId) return Promise.resolve({ success: false, message: 'transitionId is required' });
    try {
        const result = await activateWorkflowTransitionApex({ workflowTransitionId: transitionId });
        return result;
    } catch (err) {
        console.error('Apex activateTransition error', err);
        const message = err?.body?.message || err?.message || String(err);
        return { success: false, message };
    }
}

/**
 * Delete a transition via Apex
 */
export async function deleteTransition(transitionId) {
    if (!transitionId) return Promise.resolve({ success: false, message: 'transitionId is required' });
    try {
        const result = await deleteWorkflowTransitionApex({ workflowTransitionId: transitionId });
        return result;
    } catch (err) {
        console.error('Apex deleteTransition error', err);
        const message = err?.body?.message || err?.message || String(err);
        return { success: false, message };
    }
}

export default {
    normalizeWorkflowData,
    fetchWorkflowVisualizerWorkflow,
    createStatus,
    createWorkflowVisualizerTransition,
    fetchTransitionById,
    activateTransition,
    deleteTransition
};