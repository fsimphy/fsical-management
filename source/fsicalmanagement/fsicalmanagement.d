module fsicalmanagement.fsicalmanagement;

import fsicalmanagement.authenticator;
import fsicalmanagement.jsonexport;
import fsicalmanagement.event : Event, EventStore, EventType;
import fsicalmanagement.passhash : PasswordHasher;

import core.time : days;

import poodinis : Autowire;

import std.datetime : Date;
import std.exception : enforce;
import std.typecons : Nullable;

import vibe.http.server : HTTPServerRequest, HTTPServerResponse;
import vibe.web.auth;
import vibe.web.web;

@requiresAuth class FsicalManagement
{
    import vibe.http.server : HTTPServerRequest;
    @noRoute AuthInfo authenticate(scope HTTPServerRequest, scope HTTPServerResponse) @safe
    {
        if (authInfo.value.isNone)
            redirect("/login");

        return authInfo.value;
    }

public:
    @auth(Role.user | Role.admin) void index()
    {
        auto events = eventStore.getAllEvents();
        auto authInfo = this.authInfo.value;
        render!("showevents.dt", events, authInfo);
    }

    @noAuth void getLogin(string _error = null)
    {
        auto authInfo = this.authInfo.value;
        render!("login.dt", _error, authInfo);
    }

    @noAuth @errorDisplay!getLogin void postLogin(string username, string password) @safe
    {
        auto authInfo = authenticator.checkUser(username, password);
        enforce(!authInfo.isNull, "Benutzername oder Passwort ungültig");
        this.authInfo = authInfo.get;
        redirect("/");
    }

    @auth(Role.user | Role.admin) void getLogout() @safe
    {
        terminateSession();
        redirect("/");
    }

    @auth(Role.user | Role.admin) void getCreateevent(
            ValidationErrorData _error = ValidationErrorData.init)
    {
        auto authInfo = this.authInfo.value;
        render!("createevent.dt", _error, authInfo);
    }

    @auth(Role.user | Role.admin) @errorDisplay!getCreateevent void postCreateevent(Date begin,
            Nullable!Date end, string description, string name, EventType type, bool shout)
    {
        import std.array : replace, split;

        if (!end.isNull)
            enforce(end - begin >= 1.days,
                    "Mehrtägige Ereignisse müssen mindestens einen Tag dauern");
        auto event = Event("", begin, end, name, description.replace("\r", ""), type, shout);

        eventStore.addEvent(event);
        exporter.exportJSON;
        redirect("/");
    }

    @auth(Role.user | Role.admin) void postRemoveevent(string id)
    {
        eventStore.removeEvent(id);
        exporter.exportJSON;
        redirect("/");
    }

    @auth(Role.admin) void getUsers(string _error = null)
    {
        auto users = authenticator.getAllUsers;
        auto authInfo = this.authInfo.value;
        render!("showusers.dt", _error, users, authInfo);
    }

    @auth(Role.admin) @errorDisplay!getUsers void postRemoveuser(string id)
    {
        enforce(id != authInfo.value.id, "Du kannst deinen eigenen Account nicht löschen.");
        authenticator.removeUser(id);
        redirect("/users");
    }

    @auth(Role.admin) void getCreateuser(ValidationErrorData _error = ValidationErrorData.init)
    {
        auto authInfo = this.authInfo.value;
        render!("createuser.dt", _error, authInfo);
    }

    @auth(Role.admin) @errorDisplay!getCreateuser void postCreateuser(string username,
            string password, Privilege role)
    {
        import vibe.core.concurrency : async;

        authenticator.addUser(AuthInfo("", username,
                async(() => passwordHasher.generateHash(password)).getResult, role));
        redirect("/users");
    }

private:
    struct ValidationErrorData
    {
        string msg;
        string field;
    }

    SessionVar!(AuthInfo, "authInfo") authInfo = AuthInfo("", string.init,
            string.init, Privilege.None);

    @Autowire EventStore eventStore;
    @Autowire Authenticator authenticator;
    @Autowire PasswordHasher passwordHasher;
    @Autowire JSONExporter exporter;
}
