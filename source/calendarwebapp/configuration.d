module calendarwebapp.configuration;

import calendarwebapp.authenticator : Authenticator, MongoDBAuthenticator,
    MySQLAuthenticator;
import calendarwebapp.calendarwebapp : CalendarWebapp;
import calendarwebapp.event : EventStore, MongoDBEventStore, MySQLEventStore;
import calendarwebapp.passhash : PasswordHasher, SHA256PasswordHasher;

import mysql : MySQLPool;

import poodinis;

import vibe.db.mongo.client : MongoClient;
import vibe.db.mongo.collection : MongoCollection;
import vibe.db.mongo.mongo : connectMongoDB;

class Context : ApplicationContext
{
public:
    override void registerDependencies(shared(DependencyContainer) container)
    {
        auto mongoClient = connectMongoDB("localhost");
        auto pool = new MySQLPool("localhost", "username", "password", "CalendarWebapp");
        container.register!MySQLPool.existingInstance(pool);
        container.register!MongoClient.existingInstance(mongoClient);
        container.register!(EventStore, MySQLEventStore);
        container.register!(Authenticator, MySQLAuthenticator);
        container.register!(PasswordHasher, SHA256PasswordHasher);
        container.register!CalendarWebapp;
        container.register!(ValueInjector!string, StringInjector);
        container.register!(ValueInjector!MongoCollection, MongoCollectionInjector);
    }
}

class StringInjector : ValueInjector!string
{
private:
    string[string] config;

public:
    this() const @safe pure nothrow
    {
        // dfmt off
        config = ["Database name" :           "CalendarWebapp",
                  "Users collection name":    "users",
                  "Events collection name" :  "events"];
        // dfmt on
    }

    override string get(string key) const @safe pure nothrow
    {
        return config[key];
    }
}

class MongoCollectionInjector : ValueInjector!MongoCollection
{
private:
    @Autowire MongoClient mongoClient;
    @Value("Database name")
    string databaseName;

public:
    override MongoCollection get(string key) @safe
    {
        return mongoClient.getCollection(databaseName ~ "." ~ key);
    }
}
