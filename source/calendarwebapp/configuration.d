module calendarwebapp.configuration;

import calendarwebapp.authenticator : Authenticator;
import calendarwebapp.calendarwebapp : CalendarWebapp;
import calendarwebapp.event : EventStore;
import calendarwebapp.jsonexport : JSONExporter;
import calendarwebapp.passhash : PasswordHasher, SHA256PasswordHasher;

import poodinis;

import vibe.core.log : logInfo;
import vibe.db.mongo.collection : MongoCollection;

class Context : ApplicationContext
{
public:
    override void registerDependencies(shared(DependencyContainer) container)
    {
        container.register!(ValueInjector!Arguments, AppArgumentsInjector);
        auto arguments = container.resolve!(AppArgumentsInjector).get("");
        final switch (arguments.database) with (DatabaseArgument)
        {
        case mongodb:
            import calendarwebapp.authenticator : MongoDBAuthenticator;
            import calendarwebapp.event : MongoDBEventStore;
            import vibe.db.mongo.client : MongoClient;
            import vibe.db.mongo.mongo : connectMongoDB;

            auto mongoClient = connectMongoDB(arguments.mongodb.host);
            container.register!MongoClient.existingInstance(mongoClient);
            container.register!(EventStore, MongoDBEventStore!());
            container.register!(Authenticator, MongoDBAuthenticator!());
            container.register!(ValueInjector!MongoCollection, MongoCollectionInjector);
            logInfo("Using MongoDB as database system");
            break;
        case mysql:
            import calendarwebapp.authenticator : MySQLAuthenticator;
            import calendarwebapp.event : MySQLEventStore;
            import mysql : MySQLPool;

            auto pool = new MySQLPool(arguments.mysql.host, arguments.mysql.username,
                    arguments.mysql.password, arguments.mysql.database);
            container.register!MySQLPool.existingInstance(pool);
            container.register!(EventStore, MySQLEventStore);
            container.register!(Authenticator, MySQLAuthenticator);
            logInfo("Using MySQL as database system");
            break;
        }
        container.register!JSONExporter;
        container.register!(PasswordHasher, SHA256PasswordHasher);
        container.register!CalendarWebapp;
        container.register!(ValueInjector!string, StringInjector);
    }
}

class StringInjector : ValueInjector!string
{
private:
    string[string] config;
    @Value() Arguments arguments;
    bool initialized = false;

public:

    override string get(string key) @safe nothrow
    {
        if (!initialized)
        {
            config = ["MongoDB database name" : arguments.mongodb.database,
                "mysql.table.users" : "users", "mysql.table.events" : "events"];
        }
        return config[key];
    }
}

class MongoCollectionInjector : ValueInjector!MongoCollection
{
private:
    import vibe.db.mongo.client : MongoClient;

    @Autowire MongoClient mongoClient;
    @Value("MongoDB database name")
    string databaseName;

public:
    override MongoCollection get(string key) @safe
    {
        return mongoClient.getCollection(databaseName ~ "." ~ key);
    }
}

class AppArgumentsInjector : ValueInjector!Arguments
{
private:
    Arguments arguments;

public:
    this()
    {
        import vibe.core.args : readOption;

        readOption("database", &arguments.database, "The database system to use.");
        readOption("mongodb.host", &arguments.mongodb.host,
                "The host of the MongoDB instance to use.");
        readOption("mongodb.database", &arguments.mongodb.database,
                "The name of the MongoDB database to use.");
        readOption("mysql.host", &arguments.mysql.host, "The host of the MySQL instance to use.");
        readOption("mysql.username", &arguments.mysql.username,
                "The username to use for logging into the MySQL instance.");
        readOption("mysql.password", &arguments.mysql.password,
                "The password to use for logging into the MySQL instance.");
        readOption("mysql.database", &arguments.mysql.database,
                "The name of the MySQL database to use.");
        readOption("output", &arguments.output, "The file to write JSON output to.");
    }

    override Arguments get(string key) @safe
    {
        import std.exception : enforce;

        enforce(key == "", "There is only one instance of Arguments, to inject it use @Value().");
        return arguments;
    }
}

class StubAppArgumentsInjector : ValueInjector!Arguments
{
public:
    override Arguments get(string key) @safe
    {
        import std.exception : enforce;

        enforce(key == "", "There is only one instance of Arguments, to inject it use @Value().");
        return Arguments.init;
    }
}

enum DatabaseArgument
{
    mongodb,
    mysql
}

struct MySQLArguments
{
    string host = "localhost";
    string username = "username";
    string password = "password";
    string database = "CalendarWebapp";
}

struct MongoDBArguments
{
    string host = "localhost";
    string database = "CalendarWebapp";
}

struct Arguments
{
    DatabaseArgument database = DatabaseArgument.mongodb;
    MySQLArguments mysql;
    MongoDBArguments mongodb;
    string output = "cal.json";
}
