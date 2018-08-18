module fsicalmanagement.business.authentication_service;

/**
 * Provides functionality to authenticate a user.
 */
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
    ///
    this(UserRepository userRepository, PasswordHashingService passwordHashingService) @safe @nogc pure nothrow
    {
        this.userRepository = userRepository;
        this.passwordHashingService = passwordHashingService;
    }

    /**
     * A default constructor which is needed for mocking to work. It should not
     * be used otherwise, because setting dependencies manually afterwards is
     * not possible.
     */
    this() @safe @nogc pure nothrow
    {
    }

    /**
     * Authenticates a user.
     * Params:
     * username = The username with which to try authentication.
     * password = The password with which to try authentication.
     *
     * Returns: `Nullable!AuthenticationInfo` containing `AuthenticationInfo`
     *          for the authenticated user or `null`, if authentiacation failed.
     */
    Nullable!AuthenticationInfo authenticate(const string username, char[] password) @safe
    {
        import std.typecons : nullable;
        import vibe.core.concurrency : async;
        import vibe.core.log : logInfo;

        immutable user = userRepository.findByUsername(username);

        if (!user.isNull)
        {
            if ((()@trusted{
                    return async(() => passwordHashingService.checkHash(password,
                    user.passwordHash)).getResult;
                })())
            {
                logInfo("Authentication for username %s was successfull", username);
                return AuthenticationInfo(user.id, user.username, user.privilege).nullable;
            }
        }
        logInfo("Authentication for username %s failed", username);
        return Nullable!AuthenticationInfo.init;
    }
}
