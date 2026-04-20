/**
 * @description DTO for creating Sprint__c records
 * Stores static properties matching API request keys
 */
public class SprintCreateDto {
    public String name { get; set; }
    public Integer duration { get; set; }
    public Date startDate { get; set; }
    public String goal { get; set; }
    public String projectId { get; set; }

    public SprintCreateDto() {
    }

    public SprintCreateDto(String name, String projectId) {
        this.name = name;
        this.projectId = projectId;
    }

    public SprintCreateDto(String name, Integer duration, Date startDate, String goal, String projectId) {
        this.name = name;
        this.duration = duration;
        this.startDate = startDate;
        this.goal = goal;
        this.projectId = projectId;
    }
}
