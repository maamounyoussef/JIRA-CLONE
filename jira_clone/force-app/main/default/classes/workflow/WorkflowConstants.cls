/**
 * @description Constants for Workflow management system
 */
public class WorkflowConstants {
    
    // Record Status Constants
    public static final String RECORD_STATUS_PENDING = 'pending';
    public static final String RECORD_STATUS_ACTIVE = 'active';
    public static final String RECORD_STATUS_DELETED = 'deleted';
    
    // Validation Rule Types
    public static final String VALIDATION_TYPE_NOT_EQUALS = 'not equals';
    
    // Ticket Field Names Map
    public static final Map<String, String> TICKET_FIELD_API_NAMES = new Map<String, String>{
        'ASSIGNED_TO' => 'AssignedTo__c',
        'CREATOR' => 'Creator__c',
        'CURRENT_STATE' => 'CurrentState__c',
        'DESCRIPTION' => 'Description__c',
        'END_DATE' => 'EndDate__c',
        'EPIC' => 'Epic__c',
        'PRIORITY' => 'Priority__c',
        'START_DATE' => 'StartDate__c',
        'STORY_POINT' => 'StoryPoint__c',
        'SUMMARY' => 'Summary__c',
        'TYPE' => 'Type__c'
    };
    
    // Ticket Field Display Names
    public static final Map<String, String> TICKET_FIELD_DISPLAY_NAMES = new Map<String, String>{
        'ASSIGNED_TO' => 'Assigned To',
        'CREATOR' => 'Creator',
        'CURRENT_STATE' => 'Current State',
        'DESCRIPTION' => 'Description',
        'END_DATE' => 'End Date',
        'EPIC' => 'Epic',
        'PRIORITY' => 'Priority',
        'START_DATE' => 'Start Date',
        'STORY_POINT' => 'Story Point',
        'SUMMARY' => 'Summary',
        'TYPE' => 'Type'
    };
}
