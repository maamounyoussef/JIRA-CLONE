/**
 * @description DTO for creating Ticket__c records
 * Stores static properties matching API request keys
 * 
 * Required fields: name, summary, ticketTypeId, currentStateId
 * Optional fields: description, storyPoint, assignedToId, epicId, sprintId, priority
 */
public with sharing class TicketCreateDto {
    // Required fields
    public String name { get; set; }
    public String summary { get; set; }
    public String ticketTypeId { get; set; }
    public String currentStateId { get; set; }
    
    // Optional fields
    public String description { get; set; }
    public Integer storyPoint { get; set; }
    public String assignedToId { get; set; }
    public String epicId { get; set; }
    public String sprintId { get; set; }
    public String priority { get; set; }

    /**
     * @description Default constructor
     */
    public TicketCreateDto() {
    }

    /**
     * @description Constructor with required fields only
     * @param name Ticket name
     * @param summary Ticket summary (required)
     * @param ticketTypeId Ticket type ID (required)
     * @param currentStateId Current status ID (required)
     */
    public TicketCreateDto(String name, String summary, String ticketTypeId, String currentStateId) {
        if (String.isBlank(name)) {
            throw new IllegalArgumentException('Ticket name is required');
        }
        if (String.isBlank(summary)) {
            throw new IllegalArgumentException('Ticket summary is required');
        }
        if (String.isBlank(ticketTypeId)) {
            throw new IllegalArgumentException('Ticket type ID is required');
        }
        if (String.isBlank(currentStateId)) {
            throw new IllegalArgumentException('Current state ID is required');
        }
        this.name = name;
        this.summary = summary;
        this.ticketTypeId = ticketTypeId;
        this.currentStateId = currentStateId;
    }

    /**
     * @description Constructor with all fields (optional fields support null)
     * @param name Ticket name
     * @param summary Ticket summary (required)
     * @param ticketTypeId Ticket type ID (required)
     * @param currentStateId Current status ID (required)
     * @param description Ticket description (optional, can be null)
     * @param storyPoint Story point estimate (optional, can be null)
     * @param assignedToId Assigned member ID (optional, can be null)
     * @param epicId Epic ID (optional, can be null)
     * @param sprintId Sprint ID (optional, can be null)
     * @param priority Priority level (optional, can be null)
     */
    public TicketCreateDto(
        String name,
        String summary,
        String ticketTypeId,
        String currentStateId,
        String description,
        Integer storyPoint,
        String assignedToId,
        String epicId,
        String sprintId,
        String priority
    ) {
        if (String.isBlank(name)) {
            throw new IllegalArgumentException('Ticket name is required');
        }
        if (String.isBlank(summary)) {
            throw new IllegalArgumentException('Ticket summary is required');
        }
        if (String.isBlank(ticketTypeId)) {
            throw new IllegalArgumentException('Ticket type ID is required');
        }
        if (String.isBlank(currentStateId)) {
            throw new IllegalArgumentException('Current state ID is required');
        }
        this.name = name;
        this.summary = summary;
        this.ticketTypeId = ticketTypeId;
        this.currentStateId = currentStateId;
        this.description = description;
        this.storyPoint = storyPoint;
        this.assignedToId = assignedToId;
        this.epicId = epicId;
        this.sprintId = sprintId;
        this.priority = priority;
    }
}
