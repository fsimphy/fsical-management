module fsicalmanagement.business.authentication_service;

class AuthenticationService
{
    import fsicalmanagement.business.password_hashing_service : PasswordHashingService;
    import fsicalmanagement.data.authentication_info : AuthenticationInfo;
    import fsicalmanagement.dataaccess.user_repository : UserRepository;
    import poodinis : Autowire;
    import std.typecons : Nullable;

private:
    @Autowire UserRepository userRepository;
    @Autowire PasswordHashingService passwordHashingService;

public:
    Nullable!AuthenticationInfo authenticate(string username, string password) @safe
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
                logInfo("Authentication for username %s was sucessfull", username);
                return AuthenticationInfo(user.id, user.username, user.privilege).nullable;
            }
        }
        logInfo("Authentication for username %s failed", username);
        return Nullable!AuthenticationInfo.init;
    }
}
