import calendarwebapp;

import vibe.core.log : logInfo;
import vibe.http.fileserver : serveStaticFiles;
import vibe.http.router : URLRouter;
import vibe.http.server : HTTPServerSettings, listenHTTP, MemorySessionStore;
import vibe.web.web : registerWebInterface;

shared static this()
{
    auto router = new URLRouter;
    router.registerWebInterface(new CalendarWebapp);
    router.get("*", serveStaticFiles("public"));

    auto settings = new HTTPServerSettings;
    settings.port = 8080;
    settings.bindAddresses = ["::1", "127.0.0.1"];
    settings.sessionStore = new MemorySessionStore;
    listenHTTP(settings, router);

    logInfo("Please open http://127.0.0.1:8080/ in your browser.");
}
