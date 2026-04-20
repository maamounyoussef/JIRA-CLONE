/**
 * @description Composite DTO for Workflow configuration response
 * Matches the PRD requirement structure with nested workflow and transitions
 */
public class WorkflowConfigDTO {
    
    @AuraEnabled
    public WorkflowInfo workflow { get; set; }
    
    @AuraEnabled
    public List<StatusInfo> projectStatus { get; set; }
    
    public WorkflowConfigDTO() {
        this.workflow = new WorkflowInfo();
        this.projectStatus = new List<StatusInfo>();
    }
    
    /**
     * @description Nested class for Workflow information with transitions
     */
    public class WorkflowInfo {
        @AuraEnabled
        public String id { get; set; }
        
        @AuraEnabled
        public String name { get; set; }
        
        @AuraEnabled
        public List<TransitionInfo> transitions { get; set; }
        
        public WorkflowInfo() {
            this.transitions = new List<TransitionInfo>();
        }
    }
    
    /**
     * @description Nested class for Workflow Transition information with validation rules
     */
    public class TransitionInfo {
        @AuraEnabled
        public String id { get; set; }
        
        @AuraEnabled
        public String name { get; set; }
        
        @AuraEnabled
        public String fromStatus { get; set; }
        
        @AuraEnabled
        public String toStatus { get; set; }
        
        @AuraEnabled
        public String recordStatus { get; set; }
        
        @AuraEnabled
        public List<ValidationRuleInfo> validationRules { get; set; }
        
        public TransitionInfo() {
            this.validationRules = new List<ValidationRuleInfo>();
        }
    }
    
    /**
     * @description Nested class for Validation Rule information
     */
    public class ValidationRuleInfo {
        @AuraEnabled
        public String id { get; set; }
        
        @AuraEnabled
        public String ticketField { get; set; }
        
        @AuraEnabled
        public String type { get; set; }
        
        @AuraEnabled
        public String recordStatus { get; set; }
    }
    
    /**
     * @description Nested class for Project Status information
     */
    public class StatusInfo {
        @AuraEnabled
        public String id { get; set; }
        
        @AuraEnabled
        public String name { get; set; }
    }
}