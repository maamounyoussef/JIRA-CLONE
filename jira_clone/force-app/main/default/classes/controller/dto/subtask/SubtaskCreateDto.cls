/**
 * @description DTO for creating Subtask__c records
 * Stores static properties matching API request keys
 * 
 * Required fields: summary, ticketId
 * Optional fields: description, assigneeId, currentStateId, storyPoint, startDate
 */
public with sharing class SubtaskCreateDto {
    // Required fields
    public String summary { get; set; }
    public String ticketId { get; set; }
    
    // Optional fields
    public String description { get; set; }
    public String assigneeId { get; set; }
    public String currentStateId { get; set; }
    public Integer storyPoint { get; set; }
    public DateTime startDate { get; set; }

    /**
     * @description Default constructor
     */
    public SubtaskCreateDto() {
    }

    /**
     * @description Constructor with required fields only
     * @param summary Subtask summary (required)
     * @param ticketId Ticket ID (required)
     */
    public SubtaskCreateDto(String summary, String ticketId) {
        this.summary = summary;
        this.ticketId = ticketId;
    }

    /**
     * @description Constructor with all fields (optional fields support null)
     * @param summary Subtask summary (required)
     * @param ticketId Ticket ID (required)
     * @param description Subtask description (optional, can be null)
     * @param assigneeId Assignee member ID (optional, can be null)
     * @param currentStateId Current status ID (optional, can be null)
     * @param storyPoint Story point estimate (optional, can be null)
     * @param startDate Start date (optional, can be null)
     */
    public SubtaskCreateDto(
        String summary,
        String ticketId,
        String description,
        String assigneeId,
        String currentStateId,
        Integer storyPoint,
        DateTime startDate
    ) {
        this.summary = summary;
        this.ticketId = ticketId;
        this.description = description;
        this.assigneeId = assigneeId;
        this.currentStateId = currentStateId;
        this.storyPoint = storyPoint;
        this.startDate = startDate;
    }
}
