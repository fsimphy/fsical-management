module calendarwebapp.authenticator;

import poodinis;

import vibe.db.mongo.collection : MongoCollection;

interface Authenticator
{
    bool checkUser(string username, string password) @safe;
}

class MongoDBAuthenticator(Collection = MongoCollection) : Authenticator
{
private:
    @Value("users")
    Collection users;

public:
    bool checkUser(string username, string password) @safe
    {
        import botan.passhash.bcrypt : checkBcrypt;
        import vibe.data.bson : Bson;

        auto result = users.findOne(["username" : username]);
        /* checkBcrypt should be called using vibe.core.concurrency.async to
           avoid blocking, but https://github.com/vibe-d/vibe.d/issues/1521 is
           blocking this */
        return (result != Bson(null)) && (() @trusted => checkBcrypt(password,
                result["password"].get!string))();
    }
}

class MySQLAuthenticator : Authenticator
{
private:
    import mysql;

    @Autowire MySQLPool pool;

public:
    bool checkUser(string username, string password) @trusted
    {
        import botan.passhash.bcrypt : checkBcrypt;

        auto cn = pool.lockConnection();
        scope (exit)
            cn.close();
        auto prepared = cn.prepare("SELECT password FROM users WHERE username = ?");
        prepared.setArg(0, username);
        auto result = prepared.query();

        /* checkBcrypt should be called using vibe.core.concurrency.async to
           avoid blocking, but https://github.com/vibe-d/vibe.d/issues/1521 is
           blocking this */
        return !result.empty && (() @trusted => checkBcrypt(password, result.front[0].get!string))();
    }
}

struct AuthInfo
{
    string userName;
}
