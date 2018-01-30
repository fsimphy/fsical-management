module fsicalmanagement.app;

import fsicalmanagement.fsicalmanagement : FsicalManagement;
import fsicalmanagement.configuration : Context;

import poodinis : DependencyContainer, registerContext;

import vibe.core.core : runApplication;

import vibe.http.fileserver : serveStaticFiles;
import vibe.http.router : URLRouter;
import vibe.http.server : HTTPServerSettings, listenHTTP, MemorySessionStore;
import vibe.web.web : registerWebInterface;

void main()
{
    auto container = new shared DependencyContainer();
    container.registerContext!Context;

    auto router = new URLRouter;
    router.registerWebInterface(container.resolve!FsicalManagement);
    router.get("*", serveStaticFiles("public"));

    auto settings = new HTTPServerSettings;
    settings.port = 8080;
    settings.bindAddresses = ["::1", "127.0.0.1"];
    settings.sessionStore = new MemorySessionStore;
    listenHTTP(settings, router);
    runApplication();
}
