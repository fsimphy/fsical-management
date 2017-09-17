module test.calendarwebapp.testauthenticator;

import calendarwebapp.authenticator;

import poodinis;

import unit_threaded.mock;
import unit_threaded.should;

import vibe.data.bson : Bson;

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

@("Test MongoDBAuthenticator")
@system unittest
{
    auto collection = mock!Collection;
    auto container = new shared DependencyContainer;
    container.register!(ValueInjector!Collection, CollectionInjector);
    container.resolve!CollectionInjector.add("users", collection);
    container.register!(Authenticator, MongoDBAuthenticator!(Collection))(
            RegistrationOption.doNotAddConcreteTypeRegistration);

    collection.returnValue!"findOne"(Bson(true), Bson(null));
    collection.expect!"findOne"(["username" : "", "password" : ""]);
    collection.expect!"findOne"(["username" : "foo", "password" : "bar"]);

    auto authenticator = container.resolve!(Authenticator);
    authenticator.checkUser("", "").shouldBeTrue;
    authenticator.checkUser("foo", "bar").shouldBeFalse;

    collection.verify;
}
