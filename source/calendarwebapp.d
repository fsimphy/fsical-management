module calendarwebapp;

import core.time : days;

import event;

import std.datetime.date : Date;
import std.exception : enforce;
import std.typecons : Nullable;

import vibe.core.path : Path;
import vibe.http.common : HTTPStatusException;
import vibe.http.server : HTTPServerRequest, HTTPServerResponse;
import vibe.http.status : HTTPStatus;
import vibe.web.auth;
import vibe.web.web : errorDisplay, noRoute, redirect, render, SessionVar, terminateSession;

struct AuthInfo
{
    string userName;
}

@requiresAuth class CalendarWebapp
{
    @noRoute AuthInfo authenticate(scope HTTPServerRequest req, scope HTTPServerResponse res)
    {
        if (!req.session || !req.session.isKeySet("auth"))
        {
            redirect("/login");
            throw new HTTPStatusException(HTTPStatus.forbidden, "Du musst dich erst einloggen");
        }
        return req.session.get!AuthInfo("auth");
    }

public:
    @anyAuth @errorDisplay!getLogin void index()
    {
        auto entries = getEntriesFromFile(fileName);
        render!("showevents.dt", entries);
    }

    @noAuth void getLogin(string _error = null)
    {
        render!("login.dt", _error);
    }

    @noAuth @errorDisplay!getLogin void postLogin(string username, string password)
    {
        enforce(username == "foo" && password == "bar", "Benutzername oder Passwort ungültig");
        immutable AuthInfo authInfo = {username};
        auth = authInfo;
        redirect("/");
    }

    @anyAuth void getLogout()
    {
        terminateSession();
        redirect("/");
    }

    @anyAuth void getCreate(ValidationErrorData _error = ValidationErrorData.init)
    {
        render!("create.dt", _error);
    }

    @anyAuth @errorDisplay!getCreate void postCreate(Date begin,
            Nullable!Date end, string description, string name, EventType type, bool shout)
    {
        import std.array : split, replace;

        if (!end.isNull)
            enforce(end - begin >= 1.days,
                    "Mehrtägige Ereignisse müssen mindestens einen Tag dauern");

        auto entry = Entry(begin, end, Event("", name,
                description.replace("\r", "").split('\n'), type, shout));

        auto entries = getEntriesFromFile(fileName) ~ entry;
        entries.writeEntriesToFile(fileName);
        render!("showevents.dt", entries);
    }

    struct ValidationErrorData
    {
        string msg;
        string field;
    }

private:
    immutable fileName = Path("events.json");

    SessionVar!(AuthInfo, "auth") auth;
}
