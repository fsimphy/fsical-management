module test.calendarwebapp.testevent;

import calendarwebapp.event;

import poodinis;

import unit_threaded.mock;
import unit_threaded.should;

import vibe.data.bson : Bson, BsonObjectID, serializeToBson;

interface Collection
{
    Bson findOne(BsonObjectID[string] query) @safe;
    Bson[] find() @safe;
    Bson[] find(Bson[string][string][][string] query) @safe;
    void insert(Bson document) @safe;
    void remove(BsonObjectID[string] selector) @safe;
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

@("Test failing getEventMongoDBEventStore.getEvent")
@system unittest
{
    auto collection = mock!Collection;
    auto container = new shared DependencyContainer;
    container.register!(ValueInjector!Collection, CollectionInjector);
    container.resolve!CollectionInjector.add("events", collection);
    container.register!(EventStore, MongoDBEventStore!(Collection))(
            RegistrationOption.doNotAddConcreteTypeRegistration);

    collection.returnValue!"findOne"(Bson(null));

    auto id = BsonObjectID.fromString("599090de97355141140fc698");
    collection.expect!"findOne"(["_id" : id]);

    auto eventStore = container.resolve!(EventStore);
    eventStore.getEvent(id).shouldThrowWithMessage!Exception("Expected object instead of null_");
    collection.verify;
}

@("Test successful MongoDBEventStore.getEvent")
@system unittest
{
    auto collection = mock!Collection;
    auto container = new shared DependencyContainer;
    container.register!(ValueInjector!Collection, CollectionInjector);
    container.resolve!CollectionInjector.add("events", collection);
    container.register!(EventStore, MongoDBEventStore!(Collection))(
            RegistrationOption.doNotAddConcreteTypeRegistration);

    auto id = BsonObjectID.fromString("599090de97355141140fc698");
    Event event;
    event.id = id;

    collection.returnValue!"findOne"(event.serializeToBson);

    collection.expect!"findOne"(["_id" : id]);

    auto eventStore = container.resolve!(EventStore);
    eventStore.getEvent(id).shouldEqual(event);
    collection.verify;
}

@("Test MongoDBEventStore.addEvent")
@system unittest
{
    auto collection = mock!Collection;
    auto container = new shared DependencyContainer;
    container.register!(ValueInjector!Collection, CollectionInjector);
    container.resolve!CollectionInjector.add("events", collection);
    container.register!(EventStore, MongoDBEventStore!(Collection))(
            RegistrationOption.doNotAddConcreteTypeRegistration);

    auto id = BsonObjectID.fromString("599090de97355141140fc698");
    Event event;
    event.id = id;
    auto serializedEvent = event.serializeToBson;

    collection.returnValue!"findOne"(Bson(null), event.serializeToBson);

    collection.expect!"findOne"(["_id" : id]);
    collection.expect!"insert"(serializedEvent);
    collection.expect!"findOne"(["_id" : id]);

    auto eventStore = container.resolve!(EventStore);

    eventStore.getEvent(id).shouldThrowWithMessage!Exception("Expected object instead of null_");
    eventStore.addEvent(event);
    eventStore.getEvent(id).shouldEqual(event);

    collection.verify;
}
