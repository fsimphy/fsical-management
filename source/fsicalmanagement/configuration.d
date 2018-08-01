module fsicalmanagement.configuration;

import poodinis;

import vibe.db.mongo.collection : MongoCollection;

/**
 * Specifies which components are registered with the `DependencyContainer`.
 */
class Context : ApplicationContext
{
public:
    /**
     * Registers components with a dependency container.
     * Params:
     * container = The `DependencyContainer` to register components with.
     */
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
        import fsicalmanagement.resources.authentication_resource : AuthenticationResource;
        import fsicalmanagement.resources.event_resource : EventResource;
        import fsicalmanagement.resources.user_resource : UserResource;
        import vibe.core.log : logInfo;

        container.register!AuthenticationFacade;
        container.register!AuthenticationService;
        container.register!EventFacade;
        container.register!EventResource;
        container.register!(PasswordHashingService, SHA256PasswordHashingService);
        container.register!UserFacade;
        container.register!AuthenticationResource;
        container.register!UserResource;
        container.register!(ValueInjector!Arguments, ArgumentsInjector);
        container.register!(ValueInjector!string, ConfigurationInector);

        immutable arguments = container.resolve!(ArgumentsInjector).get("");
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

/**
 * Specifies configuration strings to be injected into components.
 */
class ConfigurationInector : ValueInjector!string
{
private:
    string[string] config;
    @Value() Arguments arguments;
    bool initialized;

public:

    /**
     * Gets a configuration string for a particular key.
     * Params:
     * key = The key of the configuration `string` to get.
     *
     * Returns: The configuration `string` corresponding to the given
     *          $(D_PARAM key).
     */
    override string get(const string key) @safe nothrow
    {
        if (!initialized)
        {
            // dfmt off
            config = ["mongodb.database.name" : arguments.mongodb.database,
                      "mysql.table.users"     : "users",
                      "mysql.table.events"    : "events"];
            // dfmt on
        }
        return config[key];
    }
}

/**
 * Implementation of `ValueInjector` which injects `MongoCollection`s.
 *
 * Which database to use is specified via the configuration string
 * "mongodb.database.name".
 */
class MongoCollectionInjector : ValueInjector!MongoCollection
{
private:
    import vibe.db.mongo.client : MongoClient;

    MongoClient mongoClient;
    @Value("mongodb.database.name") string databaseName;

public:

    ///
    this(MongoClient mongoClient)
    {
        this.mongoClient = mongoClient;
    }

    /**
     * Gets a MongoDB collection for a particular key.
     * Params:
     * key = The key of the `MongoCollection` to get.
     *
     * Returns: The `MongoCollection` corresponding to the given
     *          $(D_PARAM key).
     */
    override MongoCollection get(const string key) @safe
    {
        return mongoClient.getCollection(databaseName ~ "." ~ key);
    }
}

/**
 * Implementation of `ValueInjector` which injects `Arguments`s.
 * 
 * It reads the `Argument`s from the commandline and the vibe.d specific
 * configuration files.
 *
 * `Argument`s should always be injected with `@Value()` because there is only
 * a single instance of `Argument`s.
 */
class ArgumentsInjector : ValueInjector!Arguments
{
private:
    Arguments arguments;

public:
    ///
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

    /**
     * Gets the arguments.
     * Params:
     * key = Only needed for technical reasons. It should always be "".
     *
     * Returns: The `Arguments`.
     *
     * Throws: Exception if $(D_PARAM key) is not equal to "".
     */
    override Arguments get(const string key) @safe
    {
        import std.exception : enforce;

        enforce(key == "", "There is only a single instance of Arguments, to inject it use @Value().");
        return arguments;
    }
}

/**
 * The differenty types of database passable as argument.
 */
enum DatabaseArgument
{
    mongodb,
    mysql
}

/**
 * The MySQL configuration options.
 */
struct MySQLArguments
{
    ///
    string host = "localhost";
    ///
    string username = "username";
    ///
    string password = "password";
    ///
    string database = "FsicalManagement";
}

/**
 * The MongoDB configuration options.
 */
struct MongoDBArguments
{
    ///
    string host = "localhost";
    ///
    string database = "FsicalManagement";
}

/**
 * Represents the passable arguments.
 */
struct Arguments
{
    ///
    DatabaseArgument database = DatabaseArgument.mongodb;
    ///
    MySQLArguments mysql;
    ///
    MongoDBArguments mongodb;
}
