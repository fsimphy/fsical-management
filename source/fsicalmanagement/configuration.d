module fsicalmanagement.configuration;

public import poodinis;

import vibe.db.mongo.collection : MongoCollection;

class Context : ApplicationContext
{
private:
    import fsicalmanagement.authenticator : Authenticator;
    import fsicalmanagement.event : EventStore;
    import fsicalmanagement.fsicalmanagement : FsicalManagement;
    import fsicalmanagement.passhash : PasswordHasher, SHA256PasswordHasher;
    import vibe.core.log : logInfo;
public:
    override void registerDependencies(shared(DependencyContainer) container)
    {
        container.register!(ValueInjector!Arguments, AppArgumentsInjector);
        auto arguments = container.resolve!(AppArgumentsInjector).get("");
        final switch (arguments.database) with (DatabaseArgument)
        {
        case mongodb:
            import vibe.db.mongo.client : MongoClient;
            import vibe.db.mongo.mongo : connectMongoDB;
            import fsicalmanagement.authenticator : MongoDBAuthenticator;
            import fsicalmanagement.event : MongoDBEventStore;

            auto mongoClient = connectMongoDB(arguments.mongodb.host);
            container.register!MongoClient.existingInstance(mongoClient);
            container.register!(EventStore, MongoDBEventStore!());
            container.register!(Authenticator, MongoDBAuthenticator!());
            container.register!(ValueInjector!MongoCollection, MongoCollectionInjector);
            logInfo("Using MongoDB as database system");
            break;
        case mysql:
            import mysql : MySQLPool;
            import fsicalmanagement.authenticator : MySQLAuthenticator;
            import fsicalmanagement.event : MySQLEventStore;

            auto pool = new MySQLPool(arguments.mysql.host, arguments.mysql.username,
                    arguments.mysql.password, arguments.mysql.database);
            container.register!MySQLPool.existingInstance(pool);
            container.register!(EventStore, MySQLEventStore);
            container.register!(Authenticator, MySQLAuthenticator);
            logInfo("Using MySQL as database system");
            break;
        }
        container.register!(PasswordHasher, SHA256PasswordHasher);
        container.register!FsicalManagement;
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
    }

    override Arguments get(string key) @safe
    {
        import std.exception : enforce;

        enforce(key == "", "There is only one instance of Arguments, to inject it use @Value().");
        return arguments;
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
    string database = "FsicalManagement";
}

struct MongoDBArguments
{
    string host = "localhost";
    string database = "FsicalManagement";
}

struct Arguments
{
    DatabaseArgument database = DatabaseArgument.mongodb;
    MySQLArguments mysql;
    MongoDBArguments mongodb;
}
