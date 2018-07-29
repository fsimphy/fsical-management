module fsicalmanagement.configuration;

import poodinis;

import vibe.db.mongo.collection : MongoCollection;

class Context : ApplicationContext
{
public:
    override void registerDependencies(shared(DependencyContainer) container)
    {

        import fsicalmanagement.business.password_hashing_service : PasswordHashingService,
            SHA256PasswordHashingService;
        import fsicalmanagement.business.authentication_service : AuthenticationService;
        import fsicalmanagement.dataaccess.event_repository : EventRepository;
        import fsicalmanagement.dataaccess.user_repository : UserRepository;
        import fsicalmanagement.facade.authentication_facade : AuthenticationFacade;
        import fsicalmanagement.facade.event_facade : EventFacade;
        import fsicalmanagement.facade.user_facade : UserFacade;
        import fsicalmanagement.resources.login_resource : LoginResource;
        import fsicalmanagement.resources.event_resource : EventResource;
        import fsicalmanagement.resources.user_resource : UserResource;
        import vibe.core.log : logInfo;

        container.register!AuthenticationFacade;
        container.register!AuthenticationService;
        container.register!EventFacade;
        container.register!EventResource;
        container.register!(PasswordHashingService, SHA256PasswordHashingService);
        container.register!UserFacade;
        container.register!LoginResource;
        container.register!UserResource;
        container.register!(ValueInjector!Arguments, AppArgumentsInjector);
        container.register!(ValueInjector!string, ConfigurationInector);

        immutable arguments = container.resolve!(AppArgumentsInjector).get("");
        final switch (arguments.database) with (DatabaseArgument)
        {
        case mongodb:
            import vibe.db.mongo.client : MongoClient;
            import vibe.db.mongo.mongo : connectMongoDB;
            import fsicalmanagement.dataaccess.user_repository : MongoDBUserRepository;
            import fsicalmanagement.dataaccess.event_repository : MongoDBEventRepository;

            auto mongoClient = connectMongoDB(arguments.mongodb.host);
            container.register!MongoClient.existingInstance(mongoClient);
            container.register!(EventRepository, MongoDBEventRepository);
            container.register!(UserRepository, MongoDBUserRepository);
            container.register!(ValueInjector!MongoCollection, MongoCollectionInjector);
            logInfo("Using MongoDB as database system");
            break;
        case mysql:
            import mysql : MySQLPool;
            import fsicalmanagement.dataaccess.user_repository : MySQLUserRepository;
            import fsicalmanagement.dataaccess.event_repository : MySQLEventRepository;

            auto pool = new MySQLPool(arguments.mysql.host, arguments.mysql.username,
                    arguments.mysql.password, arguments.mysql.database);
            container.register!MySQLPool.existingInstance(pool);
            container.register!(EventRepository, MySQLEventRepository);
            container.register!(UserRepository, MySQLUserRepository);
            logInfo("Using MySQL as database system");
            break;
        }
    }
}

class ConfigurationInector : ValueInjector!string
{
private:
    string[string] config;
    @Value() Arguments arguments;
    bool initialized;

public:

    override string get(const string key) @safe nothrow
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

    MongoClient mongoClient;
    @Value("MongoDB database name") string databaseName;

public:

    this(MongoClient mongoClient)
    {
        this.mongoClient = mongoClient;
    }

    override MongoCollection get(const string key) @safe
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

    override Arguments get(const string key) @safe
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
