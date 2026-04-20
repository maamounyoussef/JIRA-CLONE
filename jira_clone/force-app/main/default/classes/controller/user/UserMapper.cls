/**
 * @description Mapper class for User domain operations
 * Converts between DTOs and domain objects (User)
 */
public class UserMapper {
    
    /**
     * @description Map User to UserDto
     * @param user The User object
     * @return UserDto
     */
    public static UserDto toDto(User user) {
        if (user == null) {
            return null;
        }
        
        return new UserDto(user.Id, user.Name, user.Email);
    }
    
    /**
     * @description Map list of Users to list of UserDtos
     * @param users List of User objects
     * @return List of UserDtos
     */
    public static List<UserDto> toDtoList(List<User> users) {
        if (users == null || users.isEmpty()) {
            return new List<UserDto>();
        }
        
        List<UserDto> dtos = new List<UserDto>();
        for (User user : users) {
            dtos.add(toDto(user));
        }
        return dtos;
    }
}
