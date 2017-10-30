module calendarwebapp.event;

import poodinis;

import std.algorithm : map;
import std.conv : to;
import std.datetime : Date;
import std.range.interfaces : InputRange, inputRangeObject;
import std.typecons : Nullable;

import vibe.data.bson : Bson, BsonObjectID, deserializeBson, serializeToBson;
import vibe.data.serialization : serializationName = name;
import vibe.db.mongo.collection : MongoCollection;

interface EventStore
{
    Event getEvent(string id);
    InputRange!Event getAllEvents();
    void addEvent(Event);
    /* InputRange!Event getEventsBeginningBetween(Date begin, Date end) @safe; */
    void removeEvent(string id);
}

class MongoDBEventStore(Collection = MongoCollection) : EventStore
{
public:
    Event getEvent(string id) @safe
    {
        return events.findOne(["_id" : id]).deserializeBson!Event;
    }

    InputRange!Event getAllEvents() @safe
    {
        return events.find().map!(deserializeBson!Event).inputRangeObject;
    }

    void addEvent(Event event) @safe
    {
        import std.conv : ConvException;

        try
        {
            if (!BsonObjectID.fromString(event.id).valid)
                throw new ConvException("invalid BsonObjectID.");
        }
        catch (ConvException)
        {
            event.id = BsonObjectID.generate.to!string;
        }

        events.insert(event.serializeToBson);
    }

    InputRange!Event getEventsBeginningBetween(Date begin, Date end) @safe
    {
        return events.find(["$and" : [["date" : ["$gte" : begin.serializeToBson]],
                ["date" : ["$lte" : end.serializeToBson]]]]).map!(deserializeBson!Event)
            .inputRangeObject;
    }

    void removeEvent(string id) @safe
    {
        events.remove(["_id" : id]);
    }

private:
    @Value("events")
    Collection events;
}

class MySQLEventStore : EventStore
{
private:
    import mysql;

public:
    Event getEvent(string id)
    {
        auto cn = pool.lockConnection();
        scope (exit)
            cn.close;
        auto prepared = cn.prepare(
                "SELECT id begin end name description type shout FROM events WHERE id = ?");
        prepared.setArg(0, id.to!uint);
        return toEvent(prepared.query.front);
    }

    InputRange!Event getAllEvents()
    {
        auto cn = pool.lockConnection();
        scope (exit)
            cn.close;
        auto prepared = cn.prepare(
                "SELECT id, begin, end, name, description, type, shout FROM events");
        return prepared.querySet.map!(r => toEvent(r)).inputRangeObject;
    }

    void addEvent(Event event)
    {
        auto cn = pool.lockConnection();
        scope (exit)
            cn.close;
        auto prepared = cn.prepare(
                "INSERT INTO events (begin, end, name, description, type, shout) VALUES(?, ?, ?, ?, ?, ?)");
        prepared.setArgs(event.begin, event.end, event.name, event.description,
                event.type.to!uint, event.shout);
        prepared.exec();
    }

    /*     InputRange!Event getEventsBeginningBetween(Date begin, Date end) @safe
    {
        return events.find(["$and" : [["date" : ["$gte" : begin.serializeToBson]],
                ["date" : ["$lte" : end.serializeToBson]]]]).map!(deserializeBson!Event)
            .inputRangeObject;
    } */

    void removeEvent(string id)
    {
        auto cn = pool.lockConnection();
        scope (exit)
            cn.close;
        auto prepared = cn.prepare("DELETE FROM events WHERE id = ?");
        prepared.setArg(0, id.to!uint);
        prepared.exec();
    }

private:
    @Autowire MySQLPool pool;

    Event toEvent(Row r)
    {
        import std.conv : to;

        Event event;
        event.id = r[0].get!uint.to!string;
        event.begin = r[1].get!Date;
        if (r[2].hasValue)
            event.end = r[2].get!Date;
        event.name = r[3].get!string;
        event.description = r[4].get!string;
        event.type = r[5].get!uint.to!EventType;
        event.shout = r[6].get!byte.to!bool;
        return event;
    }
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
    @serializationName("_id") string id;
    @serializationName("date") Date begin;
    @serializationName("end_date") Nullable!Date end;
    string name;
    @serializationName("desc") string description;
    @serializationName("etype") EventType type;
    bool shout;
}
