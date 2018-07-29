module fsicalmanagement.business.authentication_service;

class AuthenticationService
{
    import fsicalmanagement.business.password_hashing_service : PasswordHashingService;
    import fsicalmanagement.data.authentication_info : AuthenticationInfo;
    import fsicalmanagement.dataaccess.user_repository : UserRepository;
    import std.typecons : Nullable;

private:
    UserRepository userRepository;
    PasswordHashingService passwordHashingService;

public:
    this(UserRepository userRepository, PasswordHashingService passwordHashingService)
    {
        this.userRepository = userRepository;
        this.passwordHashingService = passwordHashingService;
    }

    this()
    {
    }

    Nullable!AuthenticationInfo authenticate(const string username, const string password) @safe
    {
        import std.typecons : nullable;
        import vibe.core.concurrency : async;
        import vibe.core.log : logInfo;

        immutable user = userRepository.findByUsername(username);

        if (!user.isNull)
        {
            if ((()@trusted => async(() => passwordHashingService.checkHash(password,
                    user.passwordHash)).getResult)())
            {
                logInfo("Authentication for username %s was successfull", username);
                return AuthenticationInfo(user.id, user.username, user.privilege).nullable;
            }
        }
        logInfo("Authentication for username %s failed", username);
        return Nullable!AuthenticationInfo.init;
    }
}
