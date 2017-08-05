import std.datetime.date;

import vibe.vibe;

class CalendarWebapp
{
private:
    immutable fileName = Path("events.json");

    struct Event
    {
        string name, place;
        DateTime begin, end;
    }

    Event[] getEventsFromFile(in Path fileName)
    {
        Event[] events;
        auto eventsString = readFileUTF8(fileName);
        try
        {
            deserializeJson(events, eventsString.parseJsonString);
        }
        catch (std.json.JSONException)
        {
        }
        return events;
    }

public:

    @method(HTTPMethod.POST) @path("/event/create")
    void createEvent(string Ereignisname, string Ereignisort, string Von, string Bis)
    {
        Event event;

        event.name = Ereignisname;
        event.place = Ereignisort;

        event.begin = DateTime.fromISOExtString(Von ~ ":00");
        event.end = DateTime.fromISOExtString(Bis ~ ":00");
        enforce(event.end - event.begin > 0.seconds);

        auto events = getEventsFromFile(fileName);

        events ~= event;

        writeFileUTF8(fileName, events.serializeToJsonString());

        render!("listevents.dt", events);
    }

    @method(HTTPMethod.GET) @path("create")
    void newEvent()
    {
        render!("create.dt");
    }

    void index()
    {
        auto events = getEventsFromFile(fileName);
        render!("listevents.dt", events);
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
