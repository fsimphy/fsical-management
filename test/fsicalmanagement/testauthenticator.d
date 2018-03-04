module test.fsicalmanagement.testauthenticator;

import fsicalmanagement.authenticator : AuthInfo, Privilege;

import poodinis : ValueInjector;

import unit_threaded.mock : mock;
import unit_threaded.should : shouldBeFalse, shouldBeTrue;

import vibe.data.bson : Bson;

interface Collection
{
    Bson[] find() @safe;
    Bson findOne(string[string] query) @safe;
    void insert(Bson document) @safe;
    void remove(string[string] selector) @safe;
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
    import fsicalmanagement.authenticator : Authenticator, MongoDBAuthenticator;
    import fsicalmanagement.passhash : PasswordHasher, StubPasswordHasher;
    import poodinis : DependencyContainer, RegistrationOption;

    auto collection = mock!Collection;
    auto container = new shared DependencyContainer;
    container.register!(ValueInjector!Collection, CollectionInjector);
    container.resolve!CollectionInjector.add("users", collection);
    container.register!(Authenticator, MongoDBAuthenticator!(Collection))(
            RegistrationOption.doNotAddConcreteTypeRegistration);
    container.register!(PasswordHasher, StubPasswordHasher);

    auto userBson = Bson(["_id" : Bson("5988ef4ae6c19089a1a53b79"), "username"
            : Bson("foo"), "passwordHash" : Bson("bar"), "privilege" : Bson(1)]);

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
    auth.privilege = Privilege.User;
    auth.isUser.shouldBeTrue;
}

@("AuthInfo.isUser failure")
@safe unittest
{
    AuthInfo auth;
    auth.privilege = Privilege.None;
    auth.isUser.shouldBeFalse;
}

@("AuthInfo.isAdmin success")
@safe unittest
{
    AuthInfo auth;
    auth.privilege = Privilege.Admin;
    auth.isAdmin.shouldBeTrue;
}

@("AuthInfo.isAdmin failure")
@safe unittest
{
    AuthInfo auth;
    auth.privilege = Privilege.None;
    auth.isAdmin.shouldBeFalse;
}

@("AuthInfo.isNone success")
@safe unittest
{
    AuthInfo auth;
    auth.privilege = Privilege.None;
    auth.isNone.shouldBeTrue;
}

@("AuthInfo.isNone failure")
@safe unittest
{
    AuthInfo auth;
    auth.privilege = Privilege.User;
    auth.isNone.shouldBeFalse;
}
