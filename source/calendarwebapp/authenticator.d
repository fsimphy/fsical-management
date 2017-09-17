module calendarwebapp.authenticator;

import poodinis;

import vibe.data.bson : Bson;
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
        auto result = users.findOne(["username" : username, "password" : password]);
        return result != Bson(null);
    }
}

struct AuthInfo
{
    string userName;
}
