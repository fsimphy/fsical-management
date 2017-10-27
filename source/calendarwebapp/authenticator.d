module calendarwebapp.authenticator;

import poodinis;

import std.range : InputRange;
import std.typecons : nullable, Nullable;

import vibe.data.bson;
import vibe.db.mongo.collection : MongoCollection;

interface Authenticator
{
    Nullable!AuthInfo checkUser(string username, string password) @safe;
    void addUser(AuthInfo authInfo) @safe;
    InputRange!AuthInfo getAllUsers() @safe;
    void removeUser(BsonObjectID id) @safe;
}

class MongoDBAuthenticator(Collection = MongoCollection) : Authenticator
{
private:
    @Value("users")
    Collection users;

public:
    Nullable!AuthInfo checkUser(string username, string password) @safe
    {
        import botan.passhash.bcrypt : checkBcrypt;

        auto result = users.findOne(["username" : username]);
        /* checkBcrypt should be called using vibe.core.concurrency.async to
           avoid blocking, but https://github.com/vibe-d/vibe.d/issues/1521 is
           blocking this */
        if (result != Bson(null))
        {
            auto authInfo = result.deserializeBson!AuthInfo;
            if ((()@trusted => checkBcrypt(password, authInfo.passwordHash))())
            {
                return authInfo.nullable;
            }
        }
        return Nullable!AuthInfo.init;
    }

    void addUser(AuthInfo authInfo) @safe
    {
        if (!authInfo.id.valid)
            authInfo.id = BsonObjectID.generate;

        users.insert(authInfo.serializeToBson);
    }

    InputRange!AuthInfo getAllUsers() @safe
    {
        import std.algorithm : map;
        import std.range : inputRangeObject;

        return users.find().map!(deserializeBson!AuthInfo).inputRangeObject;
    }

    void removeUser(BsonObjectID id) @safe
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

struct AuthInfo
{
    import vibe.data.serialization : name;

    @name("_id") BsonObjectID id;
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
