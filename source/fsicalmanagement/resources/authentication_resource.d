module fsicalmanagement.resources.authentication_resource;

import vibe.web.auth;
import vibe.web.web;

/**
 * Resource containing endpoints for login and logout.
 */
@requiresAuth class AuthenticationResource
{
    import fsicalmanagement.facade.authentication_facade : AuthenticationFacade;
    import fsicalmanagement.resources.mixins.authentication : Authentication;

private:
    AuthenticationFacade authenticationFacade;

    mixin Authentication;

public:
    ///
    this(AuthenticationFacade authenticationFacade)
    {
        this.authenticationFacade = authenticationFacade;
    }

    /**
     * Displays the login page.
     * Params:
     * _error = An error message, set automatically by vibe.d when this
     *          endpoint is used as an error page.
     */
    @noAuth void getLogin(string _error = null)
    {
        immutable authInfo = this.authInfo.value;
        render!("login.dt", _error, authInfo);
    }

    /**
     * Handles login requests. Redirects to `getLogin` on failure.
     * Params:
     * username = The username with which to attempt login.
     * password = The password with which to attempt login.
     */
    @noAuth @errorDisplay!getLogin void postLogin(string username, string password) @safe
    {
        this.authInfo = authenticationFacade.authenticate(username, password);
        redirect("/");
    }

    /**
     * Handles logout requests.
     */
    @auth(Role.user | Role.admin)
    void getLogout() @safe
    {
        terminateSession();
        redirect("/");
    }
}
