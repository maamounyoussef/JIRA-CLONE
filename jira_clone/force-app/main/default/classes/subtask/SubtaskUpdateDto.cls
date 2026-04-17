/**
 * DTO for updating Subtask fields from controllers
 * Stores API request keys with static properties (not dynamic)
 */
public with sharing class SubtaskUpdateDto {

    // Required field
    public String subtaskId { get; set; }
    
    // Optional fields
    public String summary { get; set; }
    public String description { get; set; }
    public String assigneeId { get; set; }
    public String currentStateId { get; set; }
    public Integer storyPoint { get; set; }

    /**
     * @description Default constructor
     */
    public SubtaskUpdateDto() {
    }

    /**
     * @description Constructor with required field only
     * @param subtaskId Subtask ID (required)
     */
    public SubtaskUpdateDto(String subtaskId) {
        this.subtaskId = subtaskId;
    }

    /**
     * @description Constructor with all fields (optional fields support null)
     * @param subtaskId Subtask ID (required)
     * @param summary Summary (optional, can be null)
     * @param description Description (optional, can be null)
     * @param assigneeId Assignee member ID (optional, can be null)
     * @param currentStateId Current status ID (optional, can be null)
     * @param storyPoint Story point estimate (optional, can be null)
     */
    public SubtaskUpdateDto(
        String subtaskId,
        String summary,
        String description,
        String assigneeId,
        String currentStateId,
        Integer storyPoint
    ) {
        this.subtaskId = subtaskId;
        this.summary = summary;
        this.description = description;
        this.assigneeId = assigneeId;
        this.currentStateId = currentStateId;
        this.storyPoint = storyPoint;
    }
    }

