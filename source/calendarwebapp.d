module calendarwebapp;

import authenticator : Authenticator, AuthInfo;

import core.time : days;

import event;

import poodinis;

import std.datetime.date : Date;
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
    @noRoute AuthInfo authenticate(scope HTTPServerRequest req, scope HTTPServerResponse res) @safe
    {
        if (!req.session || !req.session.isKeySet("auth"))
        {
            redirect("/login");
            return AuthInfo.init;
        }
        return req.session.get!AuthInfo("auth");
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
        enforce(authenticator.checkUser(username, password), "Benutzername oder Passwort ungültig");
        immutable AuthInfo authInfo = {username};
        auth = authInfo;
        redirect("/");
    }

    @anyAuth void getLogout() @safe
    {
        terminateSession();
        redirect("/");
    }

    @anyAuth void getCreate(ValidationErrorData _error = ValidationErrorData.init)
    {
        render!("create.dt", _error);
    }

    @anyAuth @errorDisplay!getCreate void postCreate(Date begin,
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

    @anyAuth void postRemove(BsonObjectID id) @safe
    {
        eventStore.removeEvent(id);
        redirect("/");
    }

private:
    struct ValidationErrorData
    {
        string msg;
        string field;
    }

    SessionVar!(AuthInfo, "auth") auth;

    @Autowire EventStore eventStore;
    @Autowire Authenticator authenticator;
}
