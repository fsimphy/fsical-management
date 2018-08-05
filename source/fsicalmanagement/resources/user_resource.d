module fsicalmanagement.resources.user_resource;

import vibe.web.auth;
import vibe.web.web;

/**
 * Resource containing endpoints for displaying, creating and deleting users.
 */
@requiresAuth class UserResource
{
    import fsicalmanagement.data.validation_error_data : ValidationErrorData;
    import fsicalmanagement.facade.user_facade : UserFacade;
    import fsicalmanagement.model.user : Privilege;
    import fsicalmanagement.resources.mixins.authentication : Authentication;

private:
    UserFacade userFacade;

    mixin Authentication;

public:
    ///
    this(UserFacade userFacade) @safe @nogc pure nothrow
    {
        this.userFacade = userFacade;
    }

    /**
     * Displays a list of all users.
     * _error = An error message, set automatically by vibe.d when this
     *          endpoint is used as an error page.
     */
    @auth(Role.admin)
    void getUsers(string _error = null)
    {
        auto users = userFacade.getAllUsers;
        immutable authInfo = this.authInfo.value;
        render!("showusers.dt", _error, users, authInfo);
    }

    /**
     * Removes a user. Redirects to `getUsers` on failure.
     * Params:
     * id = The id of the user to remove.
     */
    @auth(Role.admin)
    @errorDisplay!getUsers void postRemoveuser(string id)
    {
        import std.exception : enforce;

        enforce(id != authInfo.value.id, "You can not delete your own account.");
        userFacade.removeUserById(id);
        redirect("/users");
    }

    /**
     * Displays the user creation page.
     * Params:
     * _error = Information about which fields failed validation.
     *          Automatically provided by vibe.d, when this endpoint is used
     *          as an error page.
     */
    @auth(Role.admin)
    void getCreateuser(ValidationErrorData _error = ValidationErrorData.init)
    {
        immutable authInfo = this.authInfo.value;
        render!("createuser.dt", _error, authInfo);
    }

    /**
     * Creates a user. Redirects to `getCreateevent` on failure.
     * Params:
     * username = The name of the user.
     * password = The password of the user .
     * privilege = The privilege of the user.
     */
    @auth(Role.admin)
    @errorDisplay!getCreateuser void postCreateuser(string username,
            string password, Privilege privilege)
    {
        userFacade.createUser(username, password, privilege);
        redirect("/users");
    }
}
