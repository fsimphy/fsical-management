module test.calendarwebapp.testauthenticator;

import calendarwebapp.authenticator;

import poodinis;

import unit_threaded.mock;
import unit_threaded.should;

import vibe.data.bson : Bson, BsonObjectID;

interface Collection
{
    Bson findOne(string[string] query) @safe;
}

class CollectionInjector : ValueInjector!Collection
{
private:
    Collection[string] collections;

public:
    void add(string key, Collection collection)
    {
        collections[key] = collection;
    }

    override Collection get(string key) @safe
    {
        return collections[key];
    }
}

@("MongoDBAuthenticator.checkUser")
@system unittest
{
    auto collection = mock!Collection;
    auto container = new shared DependencyContainer;
    container.register!(ValueInjector!Collection, CollectionInjector);
    container.resolve!CollectionInjector.add("users", collection);
    container.register!(Authenticator, MongoDBAuthenticator!(Collection))(
            RegistrationOption.doNotAddConcreteTypeRegistration);

    auto userBson = Bson(["_id" : Bson(BsonObjectID.fromString("5988ef4ae6c19089a1a53b79")),
            "username" : Bson("foo"), "passwordHash"
            : Bson("$2a$10$9LBqOZV99ARiE4Nx.2b7GeYfqk2.0A32PWGu2cRGyW2hRJ0xeDfnO"), "role" : Bson(1)]);

    collection.returnValue!"findOne"(Bson(null), userBson, userBson);

    auto authenticator = container.resolve!(Authenticator);
    authenticator.checkUser("", "").isNull.shouldBeTrue;
    authenticator.checkUser("foo", "bar").isNull.shouldBeFalse;
    authenticator.checkUser("foo", "baz").isNull.shouldBeTrue;
}

@("AuthInfo.isUser success")
@safe unittest
{
    AuthInfo auth;
    auth.role = Role.User;
    auth.isUser.shouldBeTrue;
}

@("AuthInfo.isUser failure")
@safe unittest
{
    AuthInfo auth;
    auth.role = Role.Admin;
    auth.isUser.shouldBeFalse;
}

@("AuthInfo.isAdmin success")
@safe unittest
{
    AuthInfo auth;
    auth.role = Role.Admin;
    auth.isAdmin.shouldBeTrue;
}

@("AuthInfo.isAdmin failure")
@safe unittest
{
    AuthInfo auth;
    auth.role = Role.User;
    auth.isAdmin.shouldBeFalse;
}
