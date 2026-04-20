/**
 * @description DTO for creating TicketType__c records
 * Stores static properties matching API request keys
 */
public class TicketTypeCreateDto {
    public String name { get; set; }
    public String description { get; set; }
    public String iconUrl { get; set; }
    public String workflowId { get; set; }
    public String projectId { get; set; }

    public TicketTypeCreateDto() {
    }

    public TicketTypeCreateDto(String name, String workflowId, String projectId) {
        this.name = name;
        this.workflowId = workflowId;
        this.projectId = projectId;
    }

    public TicketTypeCreateDto(String name, String description, String iconUrl, String workflowId, String projectId) {
        this.name = name;
        this.description = description;
        this.iconUrl = iconUrl;
        this.workflowId = workflowId;
        this.projectId = projectId;
    }
}
