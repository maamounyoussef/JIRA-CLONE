/**
 * @description DTO for User operations
 * Transfers data between client and server for user operations
 */
public class UserDto {
    
    @AuraEnabled
    public String id { get; set; }
    
    @AuraEnabled
    public String name { get; set; }
    
    @AuraEnabled
    public String email { get; set; }
    
    public UserDto() {
    }
    
    public UserDto(String id, String name, String email) {
        this.id = id;
        this.name = name;
        this.email = email;
    }
}
