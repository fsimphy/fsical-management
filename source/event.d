module event;

import poodinis;

import std.algorithm : map;
import std.datetime.date : Date;
import std.range.interfaces : InputRange, inputRangeObject;
import std.typecons : Nullable;

import vibe.data.bson : Bson, BsonObjectID, deserializeBson, serializeToBson;
import vibe.data.serialization : serializationName = name;
import vibe.db.mongo.client : MongoClient;

interface EventStore
{
    Event getEvent(BsonObjectID id) @safe;
    InputRange!Event getAllEvents() @safe;
    void addEvent(Event) @safe;
    InputRange!Event getEventsBeginningBetween(Date begin, Date end) @safe;
    void removeEvent(BsonObjectID id) @safe;
}

class MongoDBEventStore : EventStore
{
public:
    Event getEvent(BsonObjectID id) @safe
    {
        return mongoClient.getCollection(databaseName ~ "." ~ entriesCollectionName)
            .findOne(["_id" : id]).deserializeBson!Event;
    }

    InputRange!Event getAllEvents() @safe
    {
        return mongoClient.getCollection(databaseName ~ "." ~ entriesCollectionName)
            .find().map!(deserializeBson!Event).inputRangeObject;
    }

    void addEvent(Event event) @safe
    {
        if (!event.id.valid)
            event.id = BsonObjectID.generate;

        mongoClient.getCollection(databaseName ~ "." ~ entriesCollectionName)
            .insert(event.serializeToBson);
    }

    InputRange!Event getEventsBeginningBetween(Date begin, Date end) @safe
    {
        return mongoClient.getCollection(databaseName ~ "." ~ entriesCollectionName)
            .find(["$and" : [["date" : ["$gte" : begin.serializeToBson]], ["date"
                    : ["$lte" : end.serializeToBson]]]]).map!(deserializeBson!Event)
            .inputRangeObject;
    }

    void removeEvent(BsonObjectID id) @safe
    {
        mongoClient.getCollection(databaseName ~ "." ~ entriesCollectionName).remove(["_id" : id]);
    }

private:
    @Autowire MongoClient mongoClient;

    @Value("Database name")
    string databaseName;

    @Value("Entries collection name")
    string entriesCollectionName;
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
    @serializationName("desc") string[] description;
    @serializationName("etype") EventType type;
    bool shout;
}
