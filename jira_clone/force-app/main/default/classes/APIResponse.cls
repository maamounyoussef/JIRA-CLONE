/**
 * @description Generic API Response wrapper for all controller responses
 */
public class APIResponse {
    
    @AuraEnabled
    public Boolean success { get; set; }
    
    @AuraEnabled
    public String message { get; set; }
    
    @AuraEnabled
    public Object data { get; set; }
    
    public APIResponse() {
        this.success = false;
        this.message = '';
        this.data = null;
    }
    
    public APIResponse(Boolean success, String message) {
        this.success = success;
        this.message = message;
        this.data = null;
    }
    
    public APIResponse(Boolean success, String message, Object data) {
        this.success = success;
        this.message = message;
        this.data = data;
    }
}
