/**
 * Mapper: convert DTOs into business models used by the component (renamed with WorkflowVisualizer prefix)
 */
import { WorkflowVisualizerStatusModel, WorkflowVisualizerTransitionModel, WorkflowVisualizerWorkflowModel } from './WorkflowVisualizerModel.js';

export function mapWorkflowVisualizerStatuses(dtoStatuses = []) {
    return dtoStatuses.map(s => new WorkflowVisualizerStatusModel({ id: s.id, name: s.name }));
}

export function mapWorkflowVisualizerTransitions(dtoTransitions = []) {
    return dtoTransitions.map(t => new WorkflowVisualizerTransitionModel({
        id: t.id,
        name: t.name,
        fromStatus: t.fromStatus,
        toStatus: t.toStatus,
        recordStatus: t.recordStatus
    }));
}

export function mapWorkflowVisualizer(dto) {
    return new WorkflowVisualizerWorkflowModel({
        id: dto?.id,
        statuses: mapWorkflowVisualizerStatuses(dto?.projectStatus || []),
        transitions: mapWorkflowVisualizerTransitions(dto?.workflow?.transitions || [])
    });
}

export default {
    mapWorkflowVisualizerStatuses,
    mapWorkflowVisualizerTransitions,
    mapWorkflowVisualizer
};