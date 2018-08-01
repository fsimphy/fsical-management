module fsicalmanagement.dataaccess.user_repository;

import fsicalmanagement.model.user : User;
import poodinis : Value;
import std.algorithm : map;
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
    import vibe.data.bson : deserializeBson;
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
        return users.find().map!(deserializeBson!User).inputRangeObject;
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
            auto user = result.deserializeBson!User;
            return user.nullable;
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
    import mysql.commands : exec, query;
    import mysql.connection : prepare;
    import mysql.pool : MySQLPool;
    import mysql.result : Row;

    MySQLPool pool;
    @Value("mysql.table.users") string usersTableName;

public:
    ///
    this(MySQLPool pool)
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
        auto cn = pool.lockConnection();
        scope (exit)
            cn.close;
        auto prepared = cn.prepare(
                "INSERT INTO " ~ usersTableName
                ~ " (username, passwordHash, privilege) VALUES(?, ?, ?)");
        prepared.setArgs(user.username, user.passwordHash, user.privilege.to!uint);
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

        auto cn = pool.lockConnection();
        scope (exit)
            cn.close;
        auto prepared = cn.prepare(
                "SELECT id, username, passwordHash, privilege FROM " ~ usersTableName ~ "");
        return cn.query(prepared).array.map!(r => toUser(r)).inputRangeObject;
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
        auto cn = pool.lockConnection();
        scope (exit)
            cn.close();
        auto prepared = cn.prepare(
                "SELECT id, username, passwordHash, privilege FROM "
                ~ usersTableName ~ " WHERE username = ?");
        prepared.setArg(0, username);
        auto result = cn.query(prepared);
        if (!result.empty)
        {
            auto user = toUser(result.front);
            return user.nullable;
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
        auto cn = pool.lockConnection();
        scope (exit)
            cn.close;
        auto prepared = cn.prepare("DELETE FROM " ~ usersTableName ~ " WHERE id = ?");
        prepared.setArg(0, id.to!uint);
        cn.exec(prepared);
    }

private:
    User toUser(const Row r) @trusted
    {
        import fsicalmanagement.model.user : Privilege;
        import std.conv : to;

        User user;
        user.id = r[0].get!uint
            .to!string;
        user.username = r[1].get!string;
        user.passwordHash = r[2].get!string;
        user.privilege = r[3].get!uint
            .to!Privilege;
        return user;
    }
}
