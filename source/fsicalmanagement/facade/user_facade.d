module fsicalmanagement.facade.user_facade;

class UserFacade
{
    import fsicalmanagement.business.password_hashing_service : PasswordHashingService;
    import fsicalmanagement.dataaccess.user_repository : UserRepository;
    import fsicalmanagement.model.user : Privilege, User;
    import poodinis : Autowire;
    import std.range.interfaces : InputRange;
    import vibe.core.log : logInfo;

private:
    @Autowire UserRepository userRepository;
    @Autowire PasswordHashingService passwordHashingService;

public:
    this(UserRepository userRepository, PasswordHashingService passwordHashingService)
    {
        this.userRepository = userRepository;
        this.passwordHashingService = passwordHashingService;
    }

    InputRange!User getAllUsers() @safe
    {
        return userRepository.findAll();
    }

    void removeUserById(const string id) @safe
    {
        userRepository.deleteById(id);
        logInfo("Deleted user with id %s from the database", id);
    }

    User createUser(const string username, const string password, const Privilege privilege) @safe
    {
        import vibe.core.concurrency : async;

        immutable user = userRepository.save(User(username,
                (() @trusted => async(() => passwordHashingService.generateHash(password)).getResult)(),
                privilege));

        logInfo("Stored user %s in the database", user);
        return user;
    }
}
