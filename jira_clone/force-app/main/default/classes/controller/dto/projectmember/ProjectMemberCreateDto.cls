/**
 * @description DTO for creating a new ProjectMember
 * Transfers data from client to server for project member creation operations
 */
public class ProjectMemberCreateDto {
    
    @AuraEnabled
    public String userId { get; set; }
    
    @AuraEnabled
    public String projectId { get; set; }
    
    @AuraEnabled
    public String recordStatus { get; set; }
    
    public ProjectMemberCreateDto() {
    }
    
    public ProjectMemberCreateDto(String userId, String projectId, String recordStatus) {
        this.userId = userId;
        this.projectId = projectId;
        this.recordStatus = recordStatus;
    }
}
