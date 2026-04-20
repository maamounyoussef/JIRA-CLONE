/**
 * @description DTO for creating Epic__c records
 * Stores static properties matching API request keys
 * 
 * Required fields: name, summary, projectId
 * Optional fields: description, startDate, endDate
 */
public with sharing class EpicCreateDto {
    // Required fields
    public String name { get; set; }
    public String summary { get; set; }
    public String projectId { get; set; }
    
    // Optional fields
    public String description { get; set; }
    public DateTime startDate { get; set; }
    public DateTime endDate { get; set; }

    /**
     * @description Default constructor
     */
    public EpicCreateDto() {
    }

    /**
     * @description Constructor with required fields only
     * @param name Epic name (required)
     * @param summary Epic summary (required)
     * @param projectId Project ID (required)
     */
    public EpicCreateDto(String name, String summary, String projectId) {
        if (String.isBlank(name)) {
            throw new IllegalArgumentException('Epic name is required');
        }
        if (String.isBlank(summary)) {
            throw new IllegalArgumentException('Epic summary is required');
        }
        if (String.isBlank(projectId)) {
            throw new IllegalArgumentException('Project ID is required');
        }
        this.name = name;
        this.summary = summary;
        this.projectId = projectId;
    }

    /**
     * @description Constructor with all fields (optional fields support null)
     * @param name Epic name (required)
     * @param summary Epic summary (required)
     * @param projectId Project ID (required)
     * @param description Epic description (optional, can be null)
     * @param startDate Start date (optional, can be null)
     * @param endDate End date (optional, can be null)
     */
    public EpicCreateDto(
        String name,
        String summary,
        String projectId,
        String description,
        DateTime startDate,
        DateTime endDate
    ) {
        if (String.isBlank(name)) {
            throw new IllegalArgumentException('Epic name is required');
        }
        if (String.isBlank(summary)) {
            throw new IllegalArgumentException('Epic summary is required');
        }
        if (String.isBlank(projectId)) {
            throw new IllegalArgumentException('Project ID is required');
        }
        this.name = name;
        this.summary = summary;
        this.projectId = projectId;
        this.description = description;
        this.startDate = startDate;
        this.endDate = endDate;
    }
}
