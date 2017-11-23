module calendarwebapp.authenticator;

import calendarwebapp.passhash : PasswordHasher;

import poodinis;

import std.conv : to;
import std.range : InputRange;
import std.typecons : nullable, Nullable;

import vibe.data.bson;

import vibe.db.mongo.collection : MongoCollection;

interface Authenticator
{
    Nullable!AuthInfo checkUser(string username, string password) @safe;
    void addUser(AuthInfo authInfo);
    InputRange!AuthInfo getAllUsers();
    void removeUser(string id);
}

class MongoDBAuthenticator(Collection = MongoCollection) : Authenticator
{
private:
    @Value("users")
    Collection users;
    @Autowire PasswordHasher passwordHasher;

public:
    Nullable!AuthInfo checkUser(string username, string password) @safe
    {
        import vibe.core.concurrency : async;

        immutable result = users.findOne(["username" : username]);

        if (result != Bson(null))
        {
            auto authInfo = result.deserializeBson!AuthInfo;
            if ((()@trusted => async(() => passwordHasher.checkHash(password,
                    authInfo.passwordHash)).getResult)())
            {
                return authInfo.nullable;
            }
        }
        return Nullable!AuthInfo.init;
    }

    void addUser(AuthInfo authInfo) @safe
    {
        import std.conv : ConvException;

        try
        {
            if (!BsonObjectID.fromString(authInfo.id).valid)
                throw new ConvException("invalid BsonObjectID.");
        }
        catch (ConvException)
        {
            authInfo.id = BsonObjectID.generate.to!string;
        }

        users.insert(authInfo.serializeToBson);
    }

    InputRange!AuthInfo getAllUsers() @safe
    {
        import std.algorithm : map;
        import std.range : inputRangeObject;

        return users.find().map!(deserializeBson!AuthInfo).inputRangeObject;
    }

    void removeUser(string id) @safe
    {
        users.remove(["_id" : id]);
    }
}

enum Privilege
{
    None,
    User,
    Admin
}

class MySQLAuthenticator : Authenticator
{
private:
    import mysql;

    @Autowire MySQLPool pool;
    @Autowire PasswordHasher passwordHasher;

public:
    Nullable!AuthInfo checkUser(string username, string password) @trusted
    {
        import vibe.core.concurrency : async;

        auto cn = pool.lockConnection();
        scope (exit)
            cn.close();
        auto prepared = cn.prepare(
                "SELECT id, username, passwordHash, privilege FROM users WHERE username = ?");
        prepared.setArg(0, username);
        auto result = prepared.query();
        /* checkHash should be called using vibe.core.concurrency.async to
           avoid blocking, but https://github.com/vibe-d/vibe.d/issues/1521 is
           blocking this */
        if (!result.empty)
        {
            auto authInfo = toAuthInfo(result.front);
            if (async(() => passwordHasher.checkHash(password, authInfo.passwordHash)).getResult)
            {
                return authInfo.nullable;
            }
        }
        return Nullable!AuthInfo.init;
    }

    void addUser(AuthInfo authInfo)
    {
        auto cn = pool.lockConnection();
        scope (exit)
            cn.close;
        auto prepared = cn.prepare(
                "INSERT INTO users (username, passwordHash, privilege) VALUES(?, ?, ?)");
        prepared.setArgs(authInfo.username, authInfo.passwordHash, authInfo.privilege.to!uint);
        prepared.exec();
    }

    InputRange!AuthInfo getAllUsers()
    {
        import std.algorithm : map;
        import std.range : inputRangeObject;

        auto cn = pool.lockConnection();
        scope (exit)
            cn.close;
        auto prepared = cn.prepare("SELECT id, username, passwordHash, privilege FROM users");
        return prepared.querySet.map!(r => toAuthInfo(r)).inputRangeObject;
    }

    void removeUser(string id)
    {
        auto cn = pool.lockConnection();
        scope (exit)
            cn.close;
        auto prepared = cn.prepare("DELETE FROM users WHERE id = ?");
        prepared.setArg(0, id.to!uint);
        prepared.exec();
    }

private:

    AuthInfo toAuthInfo(in Row r)
    {
        import std.conv : to;

        AuthInfo authInfo;
        authInfo.id = r[0].get!uint.to!string;
        authInfo.username = r[1].get!string;
        authInfo.passwordHash = r[2].get!string;
        authInfo.privilege = r[3].get!uint.to!Privilege;
        return authInfo;
    }
}

struct AuthInfo
{
    import vibe.data.serialization : name;

    @name("_id") string id;
    string username;
    string passwordHash;
    Privilege privilege;

    mixin(generateAuthMethods);

private:
    static string generateAuthMethods() pure @safe
    {
        import std.conv : to;
        import std.format : format;
        import std.traits : EnumMembers;

        string ret;
        foreach (member; EnumMembers!Privilege)
        {
            ret ~= q{
                bool is%s() const pure @safe nothrow
                {
                    return privilege == Privilege.%s;
                }
            }.format(member.to!string, member.to!string);
        }
        return ret;
    }
}
