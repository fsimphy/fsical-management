import vibe.vibe;

import std.datetime.date;

shared static this()
{
    auto router = new URLRouter;
    router.get("/", &listEvents);
    router.get("/create", staticTemplate!"create.dt");
    router.get("/event/create", &createEvent);
    router.post("/event/create", &createEvent);
    router.get("*", serveStaticFiles("/public"));

    auto settings = new HTTPServerSettings;
    settings.port = 8080;
    settings.bindAddresses = ["::1", "127.0.0.1"];
    listenHTTP(settings, router);

    logInfo("Please open http://127.0.0.1:8080/ in your browser.");
}

void listEvents(HTTPServerRequest req, HTTPServerResponse res)
{
    auto fileName = Path("events.json");

    auto events = fileName.getEventsFromFile;
    render!("listevents.dt", events)(res);
}

void createEvent(HTTPServerRequest req, HTTPServerResponse res)
{
    if (req.method != HTTPMethod.POST && req.method != HTTPMethod.GET)
        return;
    auto formdata = (req.method == HTTPMethod.POST) ? &req.form : &req.query;

    auto fileName = Path("events.json");
    Event event;

    event.name = formdata.get("Ereignisname");
    event.place = formdata.get("Ereignisort");

    event.begin = DateTime.fromISOExtString(formdata.get("Von") ~ ":00");
    event.end = DateTime.fromISOExtString(formdata.get("Bis") ~ ":00");

    auto events = fileName.getEventsFromFile;

    events ~= event;

    writeFileUTF8(fileName, events.serializeToJsonString());

    render!("listevents.dt", events)(res);
}

Event[] getEventsFromFile(in Path fileName)
{
    Event[] events;
    auto eventsString = readFileUTF8(fileName);
    try
    {
        deserializeJson(events, eventsString.parseJsonString);
    }
    catch(std.json.JSONException)
    {}
    return events;
}

struct Event
{
    string name, place;
    DateTime begin, end;
}
