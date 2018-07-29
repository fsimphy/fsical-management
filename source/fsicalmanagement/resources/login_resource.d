module fsicalmanagement.resources.login_resource;

import vibe.web.auth;
import vibe.web.web;

@requiresAuth class LoginResource
{
    import fsicalmanagement.facade.authentication_facade : AuthenticationFacade;
    import fsicalmanagement.resources.mixins.authentication : Authentication;
    import poodinis : Autowire;

private:
    @Autowire AuthenticationFacade authenticationFacade;

    mixin Authentication;

public:
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
