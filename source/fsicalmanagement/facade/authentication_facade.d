module fsicalmanagement.facade.authentication_facade;

/**
 * Provides functionality to authenticate a user.
 */
class AuthenticationFacade
{
    import fsicalmanagement.business.authentication_service : AuthenticationService;
    import fsicalmanagement.data.authentication_info : AuthenticationInfo;

private:
    AuthenticationService authenticationService;

public:
    ///
    this(AuthenticationService authenticationService) @safe @nogc pure nothrow
    {
        this.authenticationService = authenticationService;
    }

    /**
     * Authenticates a user.
     * Params:
     * username = The username with which to try authentication.
     * password = The password with which to try authentication.
     *
     * Returns: `AuthenticationInfo` for the authenticated user.
     *
     * Throws: `Exception` on invalid $(D_PARAM username) or $(D_PARAM password).
     */
    AuthenticationInfo authenticate(const string username, const string password) @safe
    {
        import std.exception : enforce;

        immutable authInfo = authenticationService.authenticate(username, password);
        enforce(!authInfo.isNull, "Invalid username or password.");
        return authInfo.get;
    }
}
