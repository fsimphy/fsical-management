module fsicalmanagement.facade.user_facade;

/**
 * Provides functionality to get, create and remove users.
 */
class UserFacade
{
    import fsicalmanagement.business.password_hashing_service : PasswordHashingService;
    import fsicalmanagement.dataaccess.user_repository : UserRepository;
    import fsicalmanagement.model.user : Privilege, User;
    import std.range.interfaces : InputRange;
    import vibe.core.log : logInfo;

private:
    UserRepository userRepository;
    PasswordHashingService passwordHashingService;

public:
    ///
    this(UserRepository userRepository, PasswordHashingService passwordHashingService)
    {
        this.userRepository = userRepository;
        this.passwordHashingService = passwordHashingService;
    }

    /**
     * Gets all users.
     *
     * Returns: An `InputRange` containing all `User`s.
     */
    InputRange!User getAllUsers() @safe
    {
        return userRepository.findAll();
    }

    /**
     * Removes a user.
     * Params:
     * id = The id of the user to remove.
     */
    void removeUserById(const string id) @safe
    {
        userRepository.deleteById(id);
        logInfo("Deleted user with id %s from the database", id);
    }

    /**
     * Creates a user.
     * Params:
     * username = The name of the user.
     * password = The password of the user .
     * privilege = The privilege of the user.
     *
     * Returns: The created `User`.
     */
    User createUser(const string username, const string password, const Privilege privilege) @safe
    {
        import vibe.core.concurrency : async;

        immutable user = userRepository.save(User(username,
                (() @trusted => async(() => passwordHashingService.generateHash(password))
                .getResult)(), privilege));

        logInfo("Stored user %s in the database", user);
        return user;
    }
}
