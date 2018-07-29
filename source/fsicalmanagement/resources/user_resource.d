module fsicalmanagement.resources.user_resource;

import vibe.web.auth;
import vibe.web.web;

@requiresAuth class UserResource
{
    import fsicalmanagement.data.validation_error_data : ValidationErrorData;
    import fsicalmanagement.facade.user_facade : UserFacade;
    import fsicalmanagement.model.user : Privilege;
    import fsicalmanagement.resources.mixins.authentication : Authentication;
    import poodinis : Autowire;

private:
    @Autowire UserFacade userFacade;

    mixin Authentication;

public:
    @auth(Role.admin)
    void getUsers(string _error = null)
    {
        auto users = userFacade.getAllUsers;
        immutable authInfo = this.authInfo.value;
        render!("showusers.dt", _error, users, authInfo);
    }

    @auth(Role.admin)
    @errorDisplay!getUsers void postRemoveuser(string id)
    {
        import std.exception : enforce;

        enforce(id != authInfo.value.id, "You can not delete your own account.");
        userFacade.removeUserById(id);
        redirect("/users");
    }

    @auth(Role.admin)
    void getCreateuser(ValidationErrorData _error = ValidationErrorData.init)
    {
        immutable authInfo = this.authInfo.value;
        render!("createuser.dt", _error, authInfo);
    }

    @auth(Role.admin)
    @errorDisplay!getCreateuser void postCreateuser(string username,
            string password, Privilege privilege)
    {
        userFacade.createUser(username, password, privilege);
        redirect("/users");
    }
}
