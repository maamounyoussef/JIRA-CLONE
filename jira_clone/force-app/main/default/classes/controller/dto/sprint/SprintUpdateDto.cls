/**
 * @description DTO for updating Sprint__c records
 * Stores static properties matching API request keys
 */
public class SprintUpdateDto {
    public String sprintId { get; set; }
    public String name { get; set; }
    public Integer duration { get; set; }
    public Date startDate { get; set; }
    public String goal { get; set; }

    public SprintUpdateDto() {
    }

    public SprintUpdateDto(String sprintId) {
        this.sprintId = sprintId;
    }

    public SprintUpdateDto(String sprintId, String name, Integer duration, Date startDate, String goal) {
        this.sprintId = sprintId;
        this.name = name;
        this.duration = duration;
        this.startDate = startDate;
        this.goal = goal;
    }
}
