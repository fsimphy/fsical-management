module calendarwebapp.event;

import poodinis;

import std.algorithm : map;
import std.datetime : Date;
import std.range.interfaces : InputRange, inputRangeObject;
import std.typecons : Nullable;

import vibe.data.bson : Bson, BsonObjectID, deserializeBson, serializeToBson;
import vibe.data.serialization : serializationName = name;
import vibe.db.mongo.collection : MongoCollection;

interface EventStore
{
    Event getEvent(BsonObjectID id) @safe;
    InputRange!Event getAllEvents() @safe;
    void addEvent(Event) @safe;
    InputRange!Event getEventsBeginningBetween(Date begin, Date end) @safe;
    void removeEvent(BsonObjectID id) @safe;
}

class MongoDBEventStore(Collection = MongoCollection) : EventStore
{
public:
    Event getEvent(BsonObjectID id) @safe
    {
        return events.findOne(["_id" : id]).deserializeBson!Event;
    }

    InputRange!Event getAllEvents() @safe
    {
        return events.find().map!(deserializeBson!Event).inputRangeObject;
    }

    void addEvent(Event event) @safe
    {
        if (!event.id.valid)
            event.id = BsonObjectID.generate;

        events.insert(event.serializeToBson);
    }

    InputRange!Event getEventsBeginningBetween(Date begin, Date end) @safe
    {
        return events.find(["$and" : [["date" : ["$gte" : begin.serializeToBson]], ["date"
                    : ["$lte" : end.serializeToBson]]]]).map!(deserializeBson!Event)
            .inputRangeObject;
    }

    void removeEvent(BsonObjectID id) @safe
    {
        events.remove(["_id" : id]);
    }

private:
    @Value("events")
    Collection events;
}

enum EventType
{
    Holiday,
    Birthday,
    FSI_Event,
    General_University_Event,
    Any
}

struct Event
{
    @serializationName("_id") BsonObjectID id;
    @serializationName("date") Date begin;
    @serializationName("end_date") Nullable!Date end;
    string name;
    @serializationName("desc") string description;
    @serializationName("etype") EventType type;
    bool shout;
}
