module test.fsicalmanagement.testevent;

import fsicalmanagement.event;

import poodinis;

import std.array;
import std.algorithm : map;

import unit_threaded.mock;
import unit_threaded.should;

import vibe.data.bson : Bson, serializeToBson;

interface Collection
{
    Bson findOne(string[string] query) @safe;
    Bson[] find() @safe;
    Bson[] find(Bson[string][string][][string] query) @safe;
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

@("MongoDBEventStore.getEvent failure")
@system unittest
{
    auto collection = mock!Collection;
    auto container = new shared DependencyContainer;
    container.register!(ValueInjector!Collection, CollectionInjector);
    container.resolve!CollectionInjector.add("events", collection);
    container.register!(EventStore, MongoDBEventStore!(Collection))(
            RegistrationOption.doNotAddConcreteTypeRegistration);

    collection.returnValue!"findOne"(Bson(null));

    auto id = "599090de97355141140fc698";
    collection.expect!"findOne"(["_id" : id]);

    auto eventStore = container.resolve!(EventStore);
    eventStore.getEvent(id).shouldThrowWithMessage!Exception("Expected object instead of null_");
    collection.verify;
}

@("MongoDBEventStore.getEvent success")
@system unittest
{
    auto collection = mock!Collection;
    auto container = new shared DependencyContainer;
    container.register!(ValueInjector!Collection, CollectionInjector);
    container.resolve!CollectionInjector.add("events", collection);
    container.register!(EventStore, MongoDBEventStore!(Collection))(
            RegistrationOption.doNotAddConcreteTypeRegistration);

    auto id = "599090de97355141140fc698";
    Event event;
    event.id = id;

    collection.returnValue!"findOne"(event.serializeToBson);

    collection.expect!"findOne"(["_id" : id]);

    auto eventStore = container.resolve!(EventStore);
    eventStore.getEvent(id).shouldEqual(event);
    collection.verify;
}

@("MongoDBEventStore.addEvent")
@system unittest
{
    auto collection = mock!Collection;
    auto container = new shared DependencyContainer;
    container.register!(ValueInjector!Collection, CollectionInjector);
    container.resolve!CollectionInjector.add("events", collection);
    container.register!(EventStore, MongoDBEventStore!(Collection))(
            RegistrationOption.doNotAddConcreteTypeRegistration);

    auto id = "599090de97355141140fc698";
    Event event;
    event.id = id;
    auto serializedEvent = event.serializeToBson;

    collection.returnValue!"findOne"(Bson(null), serializedEvent);

    collection.expect!"findOne"(["_id" : id]);
    collection.expect!"insert"(serializedEvent);
    collection.expect!"findOne"(["_id" : id]);

    auto eventStore = container.resolve!(EventStore);

    eventStore.getEvent(id).shouldThrowWithMessage!Exception("Expected object instead of null_");
    eventStore.addEvent(event);
    eventStore.getEvent(id).shouldEqual(event);

    collection.verify;
}

@("MongoDBEventStore.removeEvent")
@system unittest
{
    auto collection = mock!Collection;
    auto container = new shared DependencyContainer;
    container.register!(ValueInjector!Collection, CollectionInjector);
    container.resolve!CollectionInjector.add("events", collection);
    container.register!(EventStore, MongoDBEventStore!(Collection))(
            RegistrationOption.doNotAddConcreteTypeRegistration);

    auto id = "599090de97355141140fc698";
    Event event;
    event.id = id;

    collection.returnValue!"findOne"(event.serializeToBson, Bson(null));

    collection.expect!"findOne"(["_id" : id]);
    collection.expect!"remove"(["_id" : id]);
    collection.expect!"findOne"(["_id" : id]);

    auto eventStore = container.resolve!(EventStore);

    eventStore.getEvent(id).shouldEqual(event);
    eventStore.removeEvent(event.id);
    eventStore.getEvent(id).shouldThrowWithMessage!Exception("Expected object instead of null_");

    collection.verify;
}

@("MongoDBEventStore.getAllEvents")
@system unittest
{
    auto collection = mock!Collection;
    auto container = new shared DependencyContainer;
    container.register!(ValueInjector!Collection, CollectionInjector);
    container.resolve!CollectionInjector.add("events", collection);
    container.register!(EventStore, MongoDBEventStore!(Collection))(
            RegistrationOption.doNotAddConcreteTypeRegistration);

    immutable ids = [
        "599090de97355141140fc698", "599090de97355141140fc698", "59cb9ad8fc0ba5751c0df02b"
    ];
    auto events = ids.map!(id => Event(id)).array;

    collection.returnValue!"find"(events.map!serializeToBson.array);

    collection.expect!"find"();

    auto eventStore = container.resolve!(EventStore);

    eventStore.getAllEvents.array.shouldEqual(events);

    collection.verify;
}
