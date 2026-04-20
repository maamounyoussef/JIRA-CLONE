/**
 * @description DTO for creating a new Project
 * Transfers data from client to server for project creation operations
 */
public class ProjectCreateDto {
    
    @AuraEnabled
    public String name { get; set; }
    
    public ProjectCreateDto() {
    }
    
    public ProjectCreateDto(String name) {
        if (String.isBlank(name)) {
            throw new IllegalArgumentException('Project name is required');
        }
        this.name = name;
    }
}