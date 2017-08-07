module event;

import poodinis;

import std.algorithm : map;
import std.datetime.date : Date;
import std.range.interfaces : InputRange, inputRangeObject;
import std.typecons : Nullable;

import vibe.core.file : existsFile, readFileUTF8, writeFileUTF8;
import vibe.core.path : Path;
import vibe.data.bson : Bson, BsonObjectID, deserializeBson, serializeToBson;
import vibe.data.serialization : serializationName = name;
import vibe.db.mongo.client : MongoClient;
import vibe.db.mongo.collection : MongoCollection;

interface EventStore
{
    Event getEvent(BsonObjectID id);
    InputRange!Event getAllEvents();
    void addEvent(Event);
    InputRange!Event getEventsBeginningBetween(Date begin, Date end);
    void removeEvent(BsonObjectID id);
}

class MongoDBEventStore : EventStore
{
public:
    Event getEvent(BsonObjectID id)
    {
        return mongoClient.getCollection(databaseName ~ "." ~ entriesCollectionName)
            .findOne(["_id" : id]).deserializeBson!Event;
    }

    InputRange!Event getAllEvents()
    {
        return mongoClient.getCollection(databaseName ~ "." ~ entriesCollectionName)
            .find().map!(deserializeBson!Event).inputRangeObject;
    }

    void addEvent(Event event)
    {
        if (!event.id.valid)
            event.id = BsonObjectID.generate;

        mongoClient.getCollection(databaseName ~ "." ~ entriesCollectionName)
            .insert(event.serializeToBson);
    }

    InputRange!Event getEventsBeginningBetween(Date begin, Date end)
    {
        return mongoClient.getCollection(databaseName ~ "." ~ entriesCollectionName)
            .find(["$and" : [["date" : ["$gte" : begin.serializeToBson]], ["date"
                    : ["$lte" : end.serializeToBson]]]]).map!(deserializeBson!Event)
            .inputRangeObject;
    }

    void removeEvent(BsonObjectID id)
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
