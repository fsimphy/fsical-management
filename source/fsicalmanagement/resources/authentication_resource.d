module fsicalmanagement.resources.authentication_resource;

import vibe.web.auth;
import vibe.web.web;

@requiresAuth class AuthenticationResource
{
    import fsicalmanagement.facade.authentication_facade : AuthenticationFacade;
    import fsicalmanagement.resources.mixins.authentication : Authentication;

private:
    AuthenticationFacade authenticationFacade;

    mixin Authentication;

public:
    this(AuthenticationFacade authenticationFacade)
    {
        this.authenticationFacade = authenticationFacade;
    }

    @noAuth void getLogin(string _error = null)
    {
        immutable authInfo = this.authInfo.value;
        render!("login.dt", _error, authInfo);
    }

    @noAuth @errorDisplay!getLogin void postLogin(string username, string password) @safe
    {
        this.authInfo = authenticationFacade.authenticate(username, password);
        redirect("/");
    }

    @auth(Role.user | Role.admin)
    void getLogout() @safe
    {
        terminateSession();
        redirect("/");
    }
}
