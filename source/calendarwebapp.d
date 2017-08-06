module calendarwebapp;

import event;

import std.datetime.date;
import std.typecons : Nullable;

import vibe.vibe;

class CalendarWebapp
{
private:
    enum auth = before!ensureAuth("userName");

    immutable fileName = Path("events.json");

    struct UserData
    {
        bool loggedIn;
        string name;
        string uuid;
    }

    SessionVar!(UserData, "user") user;

    Entry[] getEntriesFromFile(in Path fileName)
    {
        Entry[] entries;
        if (fileName.existsFile)
        {
            deserializeJson(entries, fileName.readFileUTF8.parseJsonString);
        }
        return entries;
    }

    string ensureAuth(HTTPServerRequest req, HTTPServerResponse res)
    {
        if (!user.loggedIn)
            redirect("/login");
        return user.name;
    }

    mixin PrivateAccessProxy;

public:

    @auth @method(HTTPMethod.POST) @path("/event/create")
    void createEvent(Date begin, Nullable!Date end, string description,
            string name, EventType type, bool shout, string userName)
    {
        import std.array : split, replace;

        if (!end.isNull)
            enforce(end - begin >= 1.days);

        auto entry = Entry(begin, end, Event("", name,
                description.replace("\r", "").split('\n'), type, shout));

        auto entries = getEntriesFromFile(fileName) ~ entry;
        fileName.writeFileUTF8(entries.serializeToPrettyJson);
        render!("showevents.dt", entries);
    }

    @auth @method(HTTPMethod.GET) @path("create")
    void newEvent(string userName)
    {
        render!("create.dt");
    }

    @auth void index(string userName)
    {
        auto entries = getEntriesFromFile(fileName);
        render!("showevents.dt", entries);
    }

    void getLogin()
    {
        render!("login.dt");
    }

    void postLogin(string username, string password)
    {
        import std.uuid : randomUUID;

        enforce(username == "foo" && password == "bar", "Invalid username / password");
        UserData d;
        d.loggedIn = true;
        d.name = username;
        d.uuid = randomUUID.toString;
        user = d;
        redirect("/");
    }
}
