module fsicalmanagement.dataaccess.event_repository;

import fsicalmanagement.model.event : Event;
import poodinis : Value;
import std.algorithm : map;
import std.conv : to;
import std.range.interfaces : InputRange, inputRangeObject;
import std.typecons : Nullable, nullable;

interface EventRepository
{
    Event save(Event) @safe;
    InputRange!Event findAll() @safe;
    Nullable!Event findById(const string id) @safe;
    void deleteById(const string id) @safe;
}

class MongoDBEventRepository : EventRepository
{
    import vibe.data.bson : deserializeBson;
    import vibe.db.mongo.collection : MongoCollection;

private:
    @Value("events")
    MongoCollection events;

public:
    Event save(Event event) @safe
    {
        import std.conv : ConvException;
        import vibe.data.bson : BsonObjectID, serializeToBson;

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

        return event;
    }

    InputRange!Event findAll() @safe
    {
        return events.find().map!(deserializeBson!Event).inputRangeObject;
    }

    Nullable!Event findById(const string id) @safe
    {
        import vibe.data.bson : Bson;

        immutable result = events.findOne(["_id" : id]);

        if (result != Bson(null))
        {
            auto event = result.deserializeBson!Event;
            return event.nullable;
        }
        return Nullable!Event.init;
    }

    void deleteById(const string id) @safe
    {
        events.remove(["_id" : id]);
    }
}

class MySQLEventRepository : EventRepository
{
private:
    import mysql : MySQLPool, prepare, Row;

    MySQLPool pool;
    @Value("mysql.table.events") string eventsTableName;

public:
    this(MySQLPool pool)
    {
        this.pool = pool;
    }

    Event save(Event event) @trusted
    {
        auto cn = pool.lockConnection();
        scope (exit)
            cn.close;
        auto prepared = cn.prepare("INSERT INTO " ~ eventsTableName
                ~ " (begin, end, name, description, type, shout)" ~ " VALUES(?, ?, ?, ?, ?, ?)");
        prepared.setArgs(event.begin, event.end, event.name, event.description,
                event.type.to!uint, event.shout);
        prepared.exec();

        return event;
    }

    InputRange!Event findAll() @trusted
    {
        auto cn = pool.lockConnection();
        scope (exit)
            cn.close;
        auto prepared = cn.prepare(
                "SELECT id, begin, end, name, description, type, shout FROM " ~ eventsTableName ~ "");
        return prepared.querySet.map!(r => toEvent(r)).inputRangeObject;
    }

    Nullable!Event findById(const string id) @trusted
    {
        auto cn = pool.lockConnection();
        scope (exit)
            cn.close;
        auto prepared = cn.prepare(
                "SELECT id begin end name description type shout FROM "
                ~ eventsTableName ~ " WHERE id = ?");
        prepared.setArg(0, id.to!uint);
        auto result = prepared.query;

        if (!result.empty)
        {
            auto event = toEvent(result.front);
            return event.nullable;
        }
        return Nullable!Event.init;
    }

    void deleteById(const string id) @trusted
    {
        auto cn = pool.lockConnection();
        scope (exit)
            cn.close;
        auto prepared = cn.prepare("DELETE FROM " ~ eventsTableName ~ " WHERE id = ?");
        prepared.setArg(0, id.to!uint);
        prepared.exec();
    }

private:
    Event toEvent(const Row r) @trusted
    {
        import fsicalmanagement.model.event : EventType;
        import std.datetime.date : Date;

        Event event;
        event.id = r[0].get!uint
            .to!string;
        event.begin = r[1].get!Date;
        if (r[2].hasValue)
            event.end = r[2].get!Date;
        event.name = r[3].get!string;
        event.description = r[4].get!string;
        event.type = r[5].get!uint
            .to!EventType;
        event.shout = r[6].get!byte
            .to!bool;
        return event;
    }
}
