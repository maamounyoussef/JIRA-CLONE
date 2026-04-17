/**
 * Business models for the workflowVisualizer (renamed with WorkflowVisualizer prefix)
 */

export class WorkflowVisualizerStatusModel {
    constructor({ id, name } = {}) {
        this.id = id;
        this.name = name;
    }
}

export class WorkflowVisualizerTransitionModel {
    constructor({ id, name, fromStatus, toStatus, recordStatus = 'pending' } = {}) {
        this.id = id;
        this.name = name;
        this.fromStatus = fromStatus;
        this.toStatus = toStatus;
        this.recordStatus = recordStatus;
    }
}

export class WorkflowVisualizerWorkflowModel {
    constructor({ id, statuses = [], transitions = [] } = {}) {
        this.id = id;
        this.statuses = statuses.map(s => new WorkflowVisualizerStatusModel(s));
        this.transitions = transitions.map(t => new WorkflowVisualizerTransitionModel(t));
    }
}

export default {
    WorkflowVisualizerStatusModel,
    WorkflowVisualizerTransitionModel,
    WorkflowVisualizerWorkflowModel
};