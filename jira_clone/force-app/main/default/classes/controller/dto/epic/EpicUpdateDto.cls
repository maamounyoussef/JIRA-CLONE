/**
 * @description DTO for updating Epic__c records
 * Stores static properties matching API request keys
 */
public with sharing class EpicUpdateDto {
    // Required field
    public String epicId { get; set; }
    
    // Optional fields
    public String name { get; set; }
    public String summary { get; set; }
    public String description { get; set; }
    public DateTime startDate { get; set; }
    public DateTime endDate { get; set; }

    /**
     * @description Default constructor
     */
    public EpicUpdateDto() {
    }

    /**
     * @description Constructor with required field only
     * @param epicId Epic ID (required)
     */
    public EpicUpdateDto(String epicId) {
        this.epicId = epicId;
    }

    /**
     * @description Constructor with all fields (optional fields support null)
     * @param epicId Epic ID (required)
     * @param name Epic name (optional, can be null)
     * @param summary Epic summary (optional, can be null)
     * @param description Epic description (optional, can be null)
     * @param startDate Start date (optional, can be null)
     * @param endDate End date (optional, can be null)
     */
    public EpicUpdateDto(
        String epicId,
        String name,
        String summary,
        String description,
        DateTime startDate,
        DateTime endDate
    ) {
        this.epicId = epicId;
        this.name = name;
        this.summary = summary;
        this.description = description;
        this.startDate = startDate;
        this.endDate = endDate;
    }
}
