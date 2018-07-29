module fsicalmanagement.facade.authentication_facade;

class AuthenticationFacade
{
    import fsicalmanagement.business.authentication_service : AuthenticationService;
    import fsicalmanagement.data.authentication_info : AuthenticationInfo;
    import poodinis : Autowire;

private:
    @Autowire AuthenticationService authenticationService;

public:
    AuthenticationInfo authenticate(const string username, const string password) @safe
    {
        import std.exception : enforce;

        immutable authInfo = authenticationService.authenticate(username, password);
        enforce(!authInfo.isNull, "Invalid username or password.");
        return authInfo.get;
    }
}
