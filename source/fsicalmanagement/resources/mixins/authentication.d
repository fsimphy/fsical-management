module fsicalmanagement.resources.mixins.authentication;

/**
 * Adds authentication functionality to a resource.
 */
mixin template Authentication()
{
    import fsicalmanagement.data.authentication_info : AuthenticationInfo;
    import fsicalmanagement.model.user : Privilege;
    import vibe.http.server : HTTPServerRequest, HTTPServerResponse;
    import vibe.web.web : noRoute, SessionVar;

private:
    SessionVar!(AuthenticationInfo, "authInfo") authInfo = AuthenticationInfo.init;

public:
    /**
     * Provides information about a users permission to access a certain
     * endpoint. This is called, whenever a request to an endpoint which is
     * annotated with `auth` or `anyAuth` is received.
     *
     * Returns: `AuthenticationInfo` corresponding to the current session.
     */
    @noRoute AuthenticationInfo authenticate(const scope HTTPServerRequest,
            const scope HTTPServerResponse) @safe
    {
        if (authInfo.value.isNone)
            redirect("/login");

        return authInfo.value;
    }
}
