/**
 * @description Utility class for Ticket Field operations
 * Provides helper methods to work with ticket fields
 */
public class TicketFieldUtil {
    
    /**
     * @description Get all available ticket fields as a list of maps for combo boxes
     * @return List of maps containing field API names and display names
     */
    public static List<Map<String, String>> getAvailableFields() {
        List<Map<String, String>> fields = new List<Map<String, String>>();
        //CREATE FOR EACH FIELD A MAP WITH API NAME, DISPLAY NAME AND KEY AND PUT ALL THESE MAPS IN A LIST TO RETURN 
        for (String fieldKey : WorkflowConstants.TICKET_FIELD_API_NAMES.keySet()) {//GET ALL FIELD KEY
            Map<String, String> field = new Map<String, String>();
            field.put('apiName', WorkflowConstants.TICKET_FIELD_API_NAMES.get(fieldKey));//GET THE VALUE OF THIS FIELD KEY
            field.put('displayName', WorkflowConstants.TICKET_FIELD_DISPLAY_NAMES.get(fieldKey));
            field.put('key', fieldKey);
            fields.add(field);
        }
        
        return fields;
    }
    
    /**
     * @description Get available validation rule types
     * @return List of available validation types
     */
    public static List<String> getAvailableValidationTypes() {
        return new List<String>{
            WorkflowConstants.VALIDATION_TYPE_NOT_EQUALS
        };
    }
    
    /**
     * @description Validate if a ticket field exists in the allowed fields
     * @param fieldName - The field name to validate
     * @return Boolean - true if field is valid, false otherwise
     */
    public static Boolean isValidTicketField(String fieldName) {
        return WorkflowConstants.TICKET_FIELD_API_NAMES.values().contains(fieldName);
    }
    
    /**
     * @description Get API name for a ticket field by its key
     * @param fieldKey - The field key (enum name)
     * @return String - The API name of the field
     */
    public static String getApiName(String fieldKey) {
        return WorkflowConstants.TICKET_FIELD_API_NAMES.get(fieldKey);
    }
    
    /**
     * @description Get display name for a ticket field by its key
     * @param fieldKey - The field key (enum name)
     * @return String - The display name of the field
     */
    public static String getDisplayName(String fieldKey) {
        return WorkflowConstants.TICKET_FIELD_DISPLAY_NAMES.get(fieldKey);
    }
}