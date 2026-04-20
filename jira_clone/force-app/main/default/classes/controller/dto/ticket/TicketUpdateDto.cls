/**
 * @description DTO for updating Ticket__c records
 * Stores static properties matching API request keys
 */
public with sharing class TicketUpdateDto {
    public String ticketId { get; set; }
    public String summary { get; set; }
    public String description { get; set; }
    public Integer storyPoint { get; set; }
    public String priority { get; set; }
    public String assignedToId { get; set; }
    public String currentStateId { get; set; }

    public TicketUpdateDto() {
    }

    public TicketUpdateDto(String ticketId) {
        this.ticketId = ticketId;
    }

    public TicketUpdateDto(String ticketId, String summary, String description, Integer storyPoint, String priority, String assignedToId, String currentStateId) {
        this.ticketId = ticketId;
        this.summary = summary;
        this.description = description;
        this.storyPoint = storyPoint;
        this.priority = priority;
        this.assignedToId = assignedToId;
        this.currentStateId = currentStateId;
    }
}
