module authenticator;

import poodinis;

import vibe.data.bson : Bson;
import vibe.db.mongo.client : MongoClient;

interface Authenticator
{
    bool checkUser(string username, string password) @safe;
}

class MongoDBAuthenticator : Authenticator
{
private:
    @Autowire MongoClient mongoClient;

    @Value("Database name")
    string databaseName;

    @Value("Users collection name")
    string usersCollectionName;

public:
    bool checkUser(string username, string password) @safe
    {
        auto users = mongoClient.getCollection(databaseName ~ "." ~ usersCollectionName);
        auto result = users.findOne(["username" : username, "password" : password]);
        return result != Bson(null);
    }
}

struct AuthInfo
{
    string userName;
}
