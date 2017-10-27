module calendarwebapp.authenticator;

import poodinis;

import std.typecons : nullable, Nullable;

import vibe.data.bson : Bson, BsonObjectID, deserializeBson;
import vibe.db.mongo.collection : MongoCollection;

interface Authenticator
{
    Nullable!AuthInfo checkUser(string username, string password) @safe;
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
        return Nullable!AuthInfo();
    }
}

enum Role
{
    User,
    Admin
}

struct AuthInfo
{
    import vibe.data.serialization : name;

    @name("_id") BsonObjectID id;
    string username;
    string passwordHash;
    Role role;

    mixin(generateAuthMethods);

private:
    static string generateAuthMethods() pure @safe
    {
        import std.conv : to;
        import std.format : format;
        import std.traits : EnumMembers;

        string ret;
        foreach (member; EnumMembers!Role)
        {
            ret ~= q{
                bool is%s() const pure @safe nothrow
                {
                    return role == Role.%s;
                }
            }.format(member.to!string, member.to!string);
        }
        return ret;
    }

}
