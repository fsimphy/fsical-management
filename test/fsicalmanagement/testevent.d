module test.fsicalmanagement.testevent;

import fsicalmanagement.event;

import poodinis : DependencyContainer, RegistrationOption, ValueInjector;

import std.array: array;

import unit_threaded.mock : mock;
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
    import std.algorithm : map;
    import std.array : array;

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

@("StubEventStore.getEvent no event")
@safe unittest
{
    auto store = new StubEventStore;

    store.getEvent("").shouldThrow;
    store.getEvent("599090de97355141140fc698").shouldThrow;
}

@("StubEventStore.getEvent 1 event")
@safe unittest
{
    auto store = new StubEventStore;
    store.addEvent(Event("599090de97355141140fc698"));

    store.getEvent("599090de97355141140fc698").shouldEqual(Event("599090de97355141140fc698"));
    store.getEvent("59cb9ad8fc0ba5751c0df02b").shouldThrow;
    store.getEvent("").shouldThrow;
}

@("StubEventStore.getEvent 2 events")
@safe unittest
{
    auto store = new StubEventStore;
    store.addEvent(Event("599090de97355141140fc698"));
    store.addEvent(Event("59cb9ad8fc0ba5751c0df02b"));

    store.getEvent("599090de97355141140fc698").shouldEqual(Event("599090de97355141140fc698"));
    store.getEvent("59cb9ad8fc0ba5751c0df02b").shouldEqual(Event("59cb9ad8fc0ba5751c0df02b"));
    store.getEvent("").shouldThrow;
}

@("StubEventStore.getAllEvents no event")
@system unittest
{
    auto store = new StubEventStore;

    store.getAllEvents.empty.shouldBeTrue;
}

@("StubEventStore.getAllEvents 1 event")
@system unittest
{
    auto store = new StubEventStore;
    store.addEvent(Event("599090de97355141140fc698"));

    store.getAllEvents.array.shouldEqual([Event("599090de97355141140fc698")]);
}

@("StubEventStore.getAllEvents 2 events")
@system unittest
{
    auto store = new StubEventStore;
    store.addEvent(Event("599090de97355141140fc698"));
    store.addEvent(Event("59cb9ad8fc0ba5751c0df02b"));

    store.getAllEvents.array.shouldEqual([Event("599090de97355141140fc698"),
            Event("59cb9ad8fc0ba5751c0df02b")]);
}

@("StubEventStore.getEventsBeginningBetween no event")
@system unittest
{
    import std.datetime.date : Date;

    auto store = new StubEventStore;
    store.getEventsBeginningBetween(Date(2017, 12, 10), Date(2018, 1, 1)).empty.shouldBeTrue;
}

@("StubEventStore.getEventsBeginningBetween 1 event on begin")
@system unittest
{
    import std.datetime.date : Date;

    auto store = new StubEventStore;
    auto event = Event("599090de97355141140fc698", Date(2017, 12, 10));
    store.addEvent(event);

    store.getEventsBeginningBetween(Date(2017, 12, 10), Date(2018, 1, 1)).front.shouldEqual(event);
}

@("StubEventStore.getEventsBeginningBetween 1 event on end excluded")
@system unittest
{
    import std.datetime.date : Date;

    auto store = new StubEventStore;
    auto event = Event("599090de97355141140fc698", Date(2018, 1, 1));
    store.addEvent(event);

    store.getEventsBeginningBetween(Date(2017, 12, 10), Date(2018, 1, 1)).empty.shouldBeTrue;
}

@("StubEventStore.getEventsBeginningBetween 1 event on end included")
@system unittest
{
    import std.datetime.date : Date;

    auto store = new StubEventStore;
    auto event = Event("599090de97355141140fc698", Date(2017, 12, 31));
    store.addEvent(event);

    store.getEventsBeginningBetween(Date(2017, 12, 10), Date(2018, 1, 1)).front.shouldEqual(event);
}

@("StubEventStore.getEventsBeginningBetween 1 event somwhere inbetween")
@system unittest
{
    import std.datetime.date : Date;

    auto store = new StubEventStore;
    auto event = Event("599090de97355141140fc698", Date(2017, 12, 17));
    store.addEvent(event);

    store.getEventsBeginningBetween(Date(2017, 12, 10), Date(2018, 1, 1)).front.shouldEqual(event);
}

@("StubEventStore.getEventsBeginningBetween 1 event somwhere before")
@system unittest
{
    import std.datetime.date : Date;

    auto store = new StubEventStore;
    auto event = Event("599090de97355141140fc698", Date(2016, 12, 17));
    store.addEvent(event);

    store.getEventsBeginningBetween(Date(2017, 12, 10), Date(2018, 1, 1)).empty.shouldBeTrue;
}

@("StubEventStore.getEventsBeginningBetween 1 event somwhere after")
@system unittest
{
    import std.datetime.date : Date;

    auto store = new StubEventStore;
    auto event = Event("599090de97355141140fc698", Date(2018, 12, 17));
    store.addEvent(event);

    store.getEventsBeginningBetween(Date(2017, 12, 10), Date(2018, 1, 1)).empty.shouldBeTrue;
}

@("StubEventStore.getEventsBeginningBetween 1 event somewhere before, 1 event somewhere after")
@system unittest
{
    import std.datetime.date : Date;

    auto store = new StubEventStore;
    auto event1 = Event("599090de97355141140fc698", Date(2016, 12, 17));
    auto event2 = Event("59cb9ad8fc0ba5751c0df02b", Date(2018, 12, 17));
    store.addEvent(event1);
    store.addEvent(event2);

    store.getEventsBeginningBetween(Date(2017, 12, 10), Date(2018, 1, 1)).empty.shouldBeTrue;
}

@("StubEventStore.getEventsBeginningBetween 2 events before")
@system unittest
{
    import std.datetime.date : Date;

    auto store = new StubEventStore;
    auto event1 = Event("599090de97355141140fc698", Date(2016, 12, 17));
    auto event2 = Event("59cb9ad8fc0ba5751c0df02b", Date(2016, 12, 16));
    store.addEvent(event1);
    store.addEvent(event2);

    store.getEventsBeginningBetween(Date(2017, 12, 10), Date(2018, 1, 1)).empty.shouldBeTrue;
}

@("StubEventStore.getEventsBeginningBetween 2 events after")
@system unittest
{
    import std.datetime.date : Date;

    auto store = new StubEventStore;
    auto event1 = Event("599090de97355141140fc698", Date(2018, 12, 17));
    auto event2 = Event("59cb9ad8fc0ba5751c0df02b", Date(2018, 12, 16));
    store.addEvent(event1);
    store.addEvent(event2);

    store.getEventsBeginningBetween(Date(2017, 12, 10), Date(2018, 1, 1)).empty.shouldBeTrue;
}

@("StubEventStore.getEventsBeginningBetween 1 event on begin, 1 event somwhere outside")
@system unittest
{
    import std.datetime.date : Date;

    auto store = new StubEventStore;
    auto event1 = Event("599090de97355141140fc698", Date(2017, 12, 10));
    auto event2 = Event("59cb9ad8fc0ba5751c0df02b", Date(2018, 12, 16));
    store.addEvent(event1);
    store.addEvent(event2);

    store.getEventsBeginningBetween(Date(2017, 12, 10), Date(2018, 1, 1))
        .array.shouldEqual([event1]);
}

@("StubEventStore.getEventsBeginningBetween 1 event on end excluded, 1 event somwhere outside")
@system unittest
{
    import std.datetime.date : Date;

    auto store = new StubEventStore;
    auto event1 = Event("599090de97355141140fc698", Date(2018, 1, 1));
    auto event2 = Event("59cb9ad8fc0ba5751c0df02b", Date(2018, 12, 16));
    store.addEvent(event1);
    store.addEvent(event2);

    store.getEventsBeginningBetween(Date(2017, 12, 10), Date(2018, 1, 1)).empty.shouldBeTrue;
}

@("StubEventStore.getEventsBeginningBetween 1 event on end included, 1 event somwhere outside")
@system unittest
{
    import std.datetime.date : Date;

    auto store = new StubEventStore;
    auto event1 = Event("599090de97355141140fc698", Date(2017, 12, 31));
    auto event2 = Event("59cb9ad8fc0ba5751c0df02b", Date(2018, 12, 16));
    store.addEvent(event1);
    store.addEvent(event2);

    store.getEventsBeginningBetween(Date(2017, 12, 10), Date(2018, 1, 1))
        .array.shouldEqual([event1]);
}

@("StubEventStore.getEventsBeginningBetween 1 event somewhere inside, 1 event somwhere outside")
@system unittest
{
    import std.datetime.date : Date;

    auto store = new StubEventStore;
    auto event1 = Event("599090de97355141140fc698", Date(2017, 12, 17));
    auto event2 = Event("59cb9ad8fc0ba5751c0df02b", Date(2018, 12, 16));
    store.addEvent(event1);
    store.addEvent(event2);

    store.getEventsBeginningBetween(Date(2017, 12, 10), Date(2018, 1, 1))
        .array.shouldEqual([event1]);
}

@("StubEventStore.getEventsBeginningBetween 1 event somewhere inside, 1 event on begin")
@system unittest
{
    import std.datetime.date : Date;
    import std.exception : assumeUnique;

    auto store = new StubEventStore;
    immutable event1 = Event("599090de97355141140fc698", Date(2017, 12, 17));
    immutable event2 = Event("59cb9ad8fc0ba5751c0df02b", Date(2017, 12, 10));
    store.addEvent(event1);
    store.addEvent(event2);

    immutable events = assumeUnique(store.getEventsBeginningBetween(Date(2017,
            12, 10), Date(2018, 1, 1)).array);

    event1.shouldBeIn(events);
    event2.shouldBeIn(events);
    events.length.shouldEqual(2);
}

@("StubEventStore.getEventsBeginningBetween 1 event somewhere inside, 1 event on end excluded")
@system unittest
{
    import std.datetime.date : Date;
    import std.exception : assumeUnique;

    auto store = new StubEventStore;
    immutable event1 = Event("599090de97355141140fc698", Date(2017, 12, 17));
    immutable event2 = Event("59cb9ad8fc0ba5751c0df02b", Date(2018, 1, 1));
    store.addEvent(event1);
    store.addEvent(event2);

    immutable events = assumeUnique(store.getEventsBeginningBetween(Date(2017,
            12, 10), Date(2018, 1, 1)).array);

    event1.shouldBeIn(events);
    event2.shouldNotBeIn(events);
    events.length.shouldEqual(1);
}

@("StubEventStore.getEventsBeginningBetween 1 event somewhere inside, 1 event on end included")
@system unittest
{
    import std.datetime.date : Date;
    import std.exception : assumeUnique;

    auto store = new StubEventStore;
    immutable event1 = Event("599090de97355141140fc698", Date(2017, 12, 17));
    immutable event2 = Event("59cb9ad8fc0ba5751c0df02b", Date(2017, 12, 31));
    store.addEvent(event1);
    store.addEvent(event2);

    immutable events = assumeUnique(store.getEventsBeginningBetween(Date(2017,
            12, 10), Date(2018, 1, 1)).array);

    event1.shouldBeIn(events);
    event2.shouldBeIn(events);
    events.length.shouldEqual(2);
}

@("StubEventStore.getEventsBeginningBetween 2 events somewhere inside")
@system unittest
{
    import std.datetime.date : Date;
    import std.exception : assumeUnique;

    auto store = new StubEventStore;
    immutable event1 = Event("599090de97355141140fc698", Date(2017, 12, 17));
    immutable event2 = Event("59cb9ad8fc0ba5751c0df02b", Date(2017, 12, 24));
    store.addEvent(event1);
    store.addEvent(event2);

    immutable events = assumeUnique(store.getEventsBeginningBetween(Date(2017,
            12, 10), Date(2018, 1, 1)).array);

    event1.shouldBeIn(events);
    event2.shouldBeIn(events);
    events.length.shouldEqual(2);
}

@("StubEventStore.removeEvent 1 event")
@safe unittest
{
    auto store = new StubEventStore;
    immutable event = Event("599090de97355141140fc698");
    store.addEvent(event);
    store.getEvent("599090de97355141140fc698").shouldEqual(event);
    store.removeEvent("");
    store.getEvent("599090de97355141140fc698").shouldEqual(event);
    store.removeEvent("599090de97355141140fc698");
    store.getEvent("599090de97355141140fc698").shouldThrow;
}

@("StubEventStore.removeEvent 2 events")
@safe unittest
{
    auto store = new StubEventStore;
    immutable event1 = Event("599090de97355141140fc698");
    immutable event2 = Event("59cb9ad8fc0ba5751c0df02b");
    store.addEvent(event1);
    store.addEvent(event2);

    store.getEvent("599090de97355141140fc698").shouldEqual(event1);
    store.getEvent("59cb9ad8fc0ba5751c0df02b").shouldEqual(event2);

    store.removeEvent("");

    store.getEvent("599090de97355141140fc698").shouldEqual(event1);
    store.getEvent("59cb9ad8fc0ba5751c0df02b").shouldEqual(event2);

    store.removeEvent("599090de97355141140fc698");

    store.getEvent("599090de97355141140fc698").shouldThrow;
    store.getEvent("59cb9ad8fc0ba5751c0df02b").shouldEqual(event2);

    store.removeEvent("59cb9ad8fc0ba5751c0df02b");

    store.getEvent("599090de97355141140fc698").shouldThrow;
    store.getEvent("59cb9ad8fc0ba5751c0df02b").shouldThrow;
}
