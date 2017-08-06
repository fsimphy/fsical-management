import std.datetime.date;
import std.typecons : Nullable;

import vibe.vibe;

class CalendarWebapp
{
private:
    immutable fileName = Path("events.json");

    enum EventType
    {
        Holiday,
        Birthday,
        FSI_Event,
        General_University_Event,
        Any
    }

    struct Entry
    {
        @name("date") Date begin;
        @name("end_date") Nullable!Date end;
        Event event;
    }

    struct Event
    {
        @(vibe.data.serialization.name("eid")) string id;
        string name;
        @(vibe.data.serialization.name("desc")) string[] description;
        @(vibe.data.serialization.name("etype")) EventType type;
        bool shout;
    }

    Entry[] getEventsFromFile(in Path fileName)
    {
        Entry[] entries;
        try
        {
            auto entriesString = readFileUTF8(fileName);

            try
            {
                deserializeJson(entries, entriesString.parseJsonString);
            }
            catch (std.json.JSONException)
            {
            }
        }
        catch(Exception)
        {}
        return entries;
    }

public:

    @method(HTTPMethod.POST) @path("/event/create")
    void createEvent(Date begin, Nullable!Date end, string description,
            string name, EventType type, bool shout)
    {
        import std.array : split, replace;

        if (!end.isNull)
            enforce(end - begin >= 1.days);

        auto entry = Entry(begin, end, Event("", name,
                description.replace("\r", "").split('\n'), type, shout));

        auto entries = getEventsFromFile(fileName);
        entries ~= entry;
        writeFileUTF8(fileName, serializeToPrettyJson(entries));
        render!("showevents.dt", entries);
    }

    @method(HTTPMethod.GET) @path("create")
    void newEvent()
    {
        render!("create.dt");
    }

    void index()
    {
        auto entries = getEventsFromFile(fileName);
        render!("showevents.dt", entries);
    }

}

shared static this()
{
    auto router = new URLRouter;
    router.registerWebInterface(new CalendarWebapp);

    auto settings = new HTTPServerSettings;
    settings.port = 8080;
    settings.bindAddresses = ["::1", "127.0.0.1"];
    listenHTTP(settings, router);

    logInfo("Please open http://127.0.0.1:8080/ in your browser.");
}
