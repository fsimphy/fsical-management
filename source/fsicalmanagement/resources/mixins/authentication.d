module fsicalmanagement.resources.mixins.authentication;

mixin template Authentication()
{
    import fsicalmanagement.data.authentication_info : AuthenticationInfo;
    import fsicalmanagement.model.user : Privilege;
    import vibe.http.server : HTTPServerRequest, HTTPServerResponse;
    import vibe.web.web : noRoute, SessionVar;

private:
    SessionVar!(AuthenticationInfo, "authInfo") authInfo = AuthenticationInfo(
            string.init, string.init, Privilege.None);

public:
    @noRoute AuthenticationInfo authenticate(scope HTTPServerRequest, scope HTTPServerResponse) @safe
    {
        if (authInfo.value.isNone)
            redirect("/login");

        return authInfo.value;
    }
}
