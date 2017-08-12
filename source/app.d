module app;

import authenticator : Authenticator, MongoDBAuthenticator;
import calendarwebapp : CalendarWebapp;
import configuration : StringInjector;
import event : EventStore, MongoDBEventStore;

import poodinis;

import vibe.core.log : logInfo;
import vibe.db.mongo.client : MongoClient;
import vibe.db.mongo.mongo : connectMongoDB;
import vibe.http.fileserver : serveStaticFiles;
import vibe.http.router : URLRouter;
import vibe.http.server : HTTPServerSettings, listenHTTP, MemorySessionStore;
import vibe.web.web : registerWebInterface;

shared static this()
{
    auto dependencies = new shared DependencyContainer();
    auto db = connectMongoDB("localhost");
    dependencies.register!MongoClient.existingInstance(db);
    dependencies.register!(EventStore, MongoDBEventStore);
    dependencies.register!(Authenticator, MongoDBAuthenticator);
    dependencies.register!CalendarWebapp;
    dependencies.register!(ValueInjector!string, StringInjector);

    auto router = new URLRouter;
    router.registerWebInterface(dependencies.resolve!CalendarWebapp);
    router.get("*", serveStaticFiles("public"));

    auto settings = new HTTPServerSettings;
    settings.port = 8080;
    settings.bindAddresses = ["::1", "127.0.0.1"];
    settings.sessionStore = new MemorySessionStore;
    listenHTTP(settings, router);

    logInfo("Please open http://127.0.0.1:8080/ in your browser.");
}
