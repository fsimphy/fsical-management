module calendarwebapp.calendarwebapp;

import botan.rng.rng : RandomNumberGenerator;

import calendarwebapp.authenticator : Authenticator, AuthInfo, Privilege = Role;
import calendarwebapp.event;

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
        if (!req.session || !req.session.isKeySet("authInfo"))
        {
            redirect("/login");
            return AuthInfo.init;
        }
        return req.session.get!AuthInfo("authInfo");
    }

public:
    @anyAuth void index()
    {
        auto events = eventStore.getAllEvents();
        render!("showevents.dt", events);
    }

    @noAuth void getLogin(string _error = null)
    {
        render!("login.dt", _error);
    }

    @noAuth @errorDisplay!getLogin void postLogin(string username, string password) @safe
    {
        auto authInfo = authenticator.checkUser(username, password);
        enforce(!authInfo.isNull, "Benutzername oder Passwort ungültig");
        this.authInfo = authInfo.get;
        redirect("/");
    }

    @anyAuth void getLogout() @safe
    {
        terminateSession();
        redirect("/");
    }

    @anyAuth void getCreateevent(ValidationErrorData _error = ValidationErrorData.init)
    {
        render!("createevent.dt", _error);
    }

    @anyAuth @errorDisplay!getCreateevent void postCreateevent(Date begin,
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

    @anyAuth void postRemoveevent(BsonObjectID id) @safe
    {
        eventStore.removeEvent(id);
        redirect("/");
    }

    @auth(Role.admin) void getUsers()
    {
        auto users = authenticator.getAllUsers;
        render!("showusers.dt", users);
    }

    @auth(Role.admin) void postRemoveuser(BsonObjectID id) @safe
    {
        authenticator.removeUser(id);
        redirect("/users");
    }

    @auth(Role.admin) void getCreateuser(ValidationErrorData _error = ValidationErrorData.init)
    {
        render!("createuser.dt", _error);
    }

    @auth(Role.admin) @errorDisplay!getCreateuser void postCreateuser(string username,
            string password, Privilege role)
    {
        import botan.passhash.bcrypt;

        authenticator.addUser(AuthInfo(BsonObjectID.generate, username,
                generateBcrypt(password, rng, 10), role));
        redirect("/users");
    }

private:
    struct ValidationErrorData
    {
        string msg;
        string field;
    }

    SessionVar!(AuthInfo, "authInfo") authInfo;

    @Autowire EventStore eventStore;
    @Autowire Authenticator authenticator;
    @Autowire RandomNumberGenerator rng;
}
