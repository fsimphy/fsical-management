module fsicalmanagement.dataaccess.user_repository;

import fsicalmanagement.model.user : User;
import poodinis : Value;
import std.algorithm : map;
import std.conv : to;
import std.typecons : Nullable, nullable;
import std.range.interfaces : InputRange, inputRangeObject;

interface UserRepository
{
    User save(User user) @safe;
    InputRange!User findAll() @safe;
    Nullable!User findByUsername(const string username) @safe;
    void deleteById(const string id) @safe;
}

class MongoDBUserRepository : UserRepository
{
    import vibe.data.bson : deserializeBson;
    import vibe.db.mongo.collection : MongoCollection;

private:
    @Value("users")
    MongoCollection users;

public:
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

    InputRange!User findAll() @safe
    {
        return users.find().map!(deserializeBson!User).inputRangeObject;
    }

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

    void deleteById(const string id) @safe
    {
        users.remove(["_id" : id]);
    }
}

class MySQLUserRepository : UserRepository
{
private:
    import mysql : MySQLPool, Row, prepare;

    MySQLPool pool;
    @Value("mysql.table.users") string usersTableName;

public:
    this(MySQLPool pool)
    {
        this.pool = pool;
    }

    User save(User user) @trusted
    {
        auto cn = pool.lockConnection();
        scope (exit)
            cn.close;
        auto prepared = cn.prepare(
                "INSERT INTO " ~ usersTableName
                ~ " (username, passwordHash, privilege) VALUES(?, ?, ?)");
        prepared.setArgs(user.username, user.passwordHash, user.privilege.to!uint);
        prepared.exec();
        return user;
    }

    InputRange!User findAll() @trusted
    {
        auto cn = pool.lockConnection();
        scope (exit)
            cn.close;
        auto prepared = cn.prepare(
                "SELECT id, username, passwordHash, privilege FROM " ~ usersTableName ~ "");
        return prepared.querySet.map!(r => toUser(r)).inputRangeObject;
    }

    Nullable!User findByUsername(const string username) @trusted
    {
        auto cn = pool.lockConnection();
        scope (exit)
            cn.close();
        auto prepared = cn.prepare(
                "SELECT id, username, passwordHash, privilege FROM "
                ~ usersTableName ~ " WHERE username = ?");
        prepared.setArg(0, username);
        auto result = prepared.query();
        if (!result.empty)
        {
            auto user = toUser(result.front);
            return user.nullable;
        }
        return Nullable!User.init;
    }

    void deleteById(const string id) @trusted
    {
        auto cn = pool.lockConnection();
        scope (exit)
            cn.close;
        auto prepared = cn.prepare("DELETE FROM " ~ usersTableName ~ " WHERE id = ?");
        prepared.setArg(0, id.to!uint);
        prepared.exec();
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
