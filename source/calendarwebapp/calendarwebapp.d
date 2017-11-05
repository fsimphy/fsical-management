module calendarwebapp.calendarwebapp;

import calendarwebapp.authenticator;
import calendarwebapp.event;
import calendarwebapp.passhash : PasswordHasher;

import core.time : days;

import poodinis;

import std.datetime : Date;
import std.exception : enforce;
import std.typecons : Nullable;

import vibe.data.bson : BsonObjectID;
import vibe.http.common : HTTPStatusException;
import vibe.http.server : HTTPServerRequest, HTTPServerResponse;
import vibe.http.status : HTTPStatus;
import vibe.web.auth;
import vibe.web.web : errorDisplay, noRoute, redirect, render, SessionVar,
    terminateSession;

@requiresAuth class CalendarWebapp
{
    @noRoute AuthInfo authenticate(scope HTTPServerRequest req, scope HTTPServerResponse) @safe
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
            Nullable!Date end, string description, string name, EventType type, bool shout) @safe
    {
        import std.array : replace, split;

        if (!end.isNull)
            enforce(end - begin >= 1.days,
                    "Mehrtägige Ereignisse müssen mindestens einen Tag dauern");
        auto event = Event(BsonObjectID.generate, begin, end, name,
                description.replace("\r", ""), type, shout);

        eventStore.addEvent(event);

        redirect("/");
    }

    @auth(Role.user | Role.admin) void postRemoveevent(BsonObjectID id) @safe
    {
        eventStore.removeEvent(id);
        redirect("/");
    }

    @auth(Role.admin) void getUsers()
    {
        auto users = authenticator.getAllUsers;
        auto authInfo = this.authInfo.value;
        render!("showusers.dt", users, authInfo);
    }

    @auth(Role.admin) void postRemoveuser(BsonObjectID id) @safe
    {
        authenticator.removeUser(id);
        redirect("/users");
    }

    @auth(Role.admin) void getCreateuser(ValidationErrorData _error = ValidationErrorData.init)
    {
        auto authInfo = this.authInfo.value;
        render!("createuser.dt", _error, authInfo);
    }

    @auth(Role.admin) @errorDisplay!getCreateuser void postCreateuser(string username,
            string password, Privilege role) @safe
    {
        authenticator.addUser(AuthInfo(BsonObjectID.generate, username,
                passwordHasher.generateHash(password), role));
        redirect("/users");
    }

private:
    struct ValidationErrorData
    {
        string msg;
        string field;
    }

    SessionVar!(AuthInfo, "authInfo") authInfo = AuthInfo(BsonObjectID.init,
            string.init, string.init, Privilege.None);

    @Autowire EventStore eventStore;
    @Autowire Authenticator authenticator;
    @Autowire PasswordHasher passwordHasher;
}
