module fsicalmanagement.dataaccess.user_repository;

import fsicalmanagement.model.user : User;
import poodinis : Value;
import std.algorithm : filter, map;
import std.conv : to;
import std.typecons : Nullable, nullable;
import std.range.interfaces : InputRange, inputRangeObject;

/**
 * A repository which stores `User`s.
 */
interface UserRepository
{
    /**
     * Saves a user to the repository.
     * Params:
     * user = The `User` to save.
     * 
     * Returns: The saved `User`.
     */
    User save(User user) @safe;

    /**
     * Gets all users from the repository.
     *
     * Returns: An `InputRange` containing all `User`s from the repository.
     */
    InputRange!User findAll() @safe;

    /**
     * Gets a user by its id from the repository.
     * Params:
     * id = The id of the user to get.
     *
     * Returns: `Nullable!User` containing the `User` corresponding to
     *          $(D_PARAM id) in the repository or `null`, if no such user
     *          exists.
     */
    Nullable!User findByUsername(const string username) @safe;

    /**
     * Removes a user from the repository.
     * Params:
     * id = The id of the user to remove.
     */
    void deleteById(const string id) @safe;
}

/**
 * A MongoDB based implementation of `UserRepository`.
 */
class MongoDBUserRepository : UserRepository
{
    import fsicalmanagement.utility.serialization : deserializeBsonNothrow;
    import vibe.db.mongo.collection : MongoCollection;

private:
    @Value("users")
    MongoCollection users;

public:

    /**
     * Saves a user to the configured MongoDB collection.
     * Params:
     * user = The `User` to save.
     * 
     * Returns: The saved `User`.
     */
    User save(User user) @safe
    {
        import std.conv : ConvException;
        import vibe.data.bson : BsonObjectID, serializeToBson;

        try
        {
            if (!BsonObjectID.fromString(user.id).valid)
                throw new ConvException("invalid BsonObjectID.");
        }
        catch (ConvException)
        {
            user.id = BsonObjectID.generate.to!string;
        }

        users.insert(user.serializeToBson);
        return user;
    }

    /**
     * Gets all users from the configured MongoDB collection.
     *
     * Returns: An `InputRange` containing all `User`s from the configured
     *          MongoDB collection.
     */
    InputRange!User findAll() @safe
    {
        return users.find().map!(deserializeBsonNothrow!User)
            .filter!(nullableUser => !nullableUser.isNull)
            .map!(nullableUser => nullableUser.get)
            .inputRangeObject;
    }

    /**
     * Gets aa user by its id from the configured MongoDB collection.
     * Params:
     * id = The id of the user to get.
     *
     * Returns: `Nullable!User` containing the `User` corresponding to
     *          $(D_PARAM id) in the configured MongoDB collection or `null`, if
     *          no such user exists.
     */
    Nullable!User findByUsername(const string username) @safe
    {
        import std.typecons : nullable;
        import vibe.data.bson : Bson;

        immutable result = users.findOne(["username" : username]);

        if (result != Bson(null))
        {
            return result.deserializeBsonNothrow!User;
        }
        return Nullable!User.init;
    }

    /**
     * Removes a user from the configured MongoDB collection.
     * Params:
     * id = The id of the user to remove.
     */
    void deleteById(const string id) @safe
    {
        users.remove(["_id" : id]);
    }
}

/**
 * A MySQL based implementation of `UserRepository`.
 */
class MySQLUserRepository : UserRepository
{
private:
    import fsicalmanagement.utility.initialization : initOnce;
    import mysql.commands : exec, query;
    import mysql.connection : prepare;
    import mysql.pool : MySQLPool;
    import mysql.prepared : Prepared;
    import mysql.result : Row;

    MySQLPool pool;

    @Value("mysql.table.users")
    string usersTableName;

public:
    ///
    this(MySQLPool pool) @safe @nogc pure nothrow
    {
        this.pool = pool;
    }

    /**
     * Saves auser to the configured MySQL table.
     * Params:
     * user = The `User` to save.
     * 
     * Returns: The saved `User`.
     */
    User save(User user) @trusted
    {
        auto preparedStatement()
        {
            static Prepared prepared;
            return initOnce!prepared(({
                    auto cn = pool.lockConnection();
                    return cn.prepare(
                    "INSERT INTO " ~ usersTableName
                    ~ " (username, passwordHash, privilege) VALUES(?, ?, ?)");
                })());
        }

        auto prepared = preparedStatement;
        prepared.setArgs(user.username, user.passwordHash, user.privilege.to!uint);
        auto cn = pool.lockConnection();
        cn.exec(prepared);
        return user;
    }

    /**
     * Gets all users from the configured MySQL table.
     *
     * Returns: An `InputRange` containing all `User`s from the configured
     *          MySQL table.
     */
    InputRange!User findAll() @trusted
    {
        import std.array : array;

        auto preparedStatement()
        {
            static Prepared prepared;
            return initOnce!prepared(({
                    auto cn = pool.lockConnection();
                    return cn.prepare(
                    "SELECT id, username, passwordHash, privilege FROM " ~ usersTableName);
                })());
        }

        auto prepared = preparedStatement;
        auto cn = pool.lockConnection();
        return cn.query(prepared).array
            .map!(r => toUser(r))
            .filter!(nullableUser => !nullableUser.isNull)
            .map!(nullableUser => nullableUser.get)
            .inputRangeObject;
    }

    /**
     * Gets a user by its id from the configured MySQL table.
     * Params:
     * id = The id of the user to get.
     *
     * Returns: `Nullable!User` containing the `User` corresponding to
     *          $(D_PARAM id) in the configured MySQL table. or `null`, if no
     *          such user exists.
     */
    Nullable!User findByUsername(const string username) @trusted
    {
        auto preparedStatement()
        {
            static Prepared prepared;
            return initOnce!prepared(({
                    auto cn = pool.lockConnection();
                    return cn.prepare(
                    "SELECT id, username, passwordHash, privilege FROM "
                    ~ usersTableName ~ " WHERE username = ?");
                })());
        }

        auto prepared = preparedStatement;
        prepared.setArg(0, username);
        auto cn = pool.lockConnection();
        auto result = cn.query(prepared);
        if (!result.empty)
        {
            return toUser(result.front);
        }
        return Nullable!User.init;
    }

    /**
     * Removes a user from the configured MySQL table.
     * Params:
     * id = The id of the user to remove.
     */
    void deleteById(const string id) @trusted
    {
        auto preparedStatement()
        {
            static Prepared prepared;
            return initOnce!prepared(({
                    auto cn = pool.lockConnection();
                    return cn.prepare("DELETE FROM " ~ usersTableName ~ " WHERE id = ?");
                })());
        }

        auto prepared = preparedStatement;
        prepared.setArg(0, id.to!uint);
        auto cn = pool.lockConnection();
        cn.exec(prepared);
    }

private:
    Nullable!User toUser(const Row r) @trusted nothrow
    {
        import fsicalmanagement.model.user : Privilege;
        import std.traits : fullyQualifiedName;
        import vibe.core.log : logError;

        try
        {
            User user;
            user.id = r[0].get!uint
                .to!string;
            user.username = r[1].get!string;
            user.passwordHash = r[2].get!string;
            user.privilege = r[3].get!uint
                .to!Privilege;
            return user.nullable;
        }
        catch (Exception e)
        {
            logError("Error while converting Row %s to %s:\n%s", r, fullyQualifiedName!User, e);
        }
        return Nullable!User.init;
    }
}
