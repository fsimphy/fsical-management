module fsicalmanagement.dataaccess.event_repository;

import fsicalmanagement.model.event : Event;
import poodinis : Value;
import std.algorithm.iteration : filter, map;
import std.conv : to;
import std.range.interfaces : InputRange, inputRangeObject;
import std.typecons : Nullable, nullable;

/**
 * A repository which stores `Event`s.
 */
interface EventRepository
{
    /**
     * Saves an event to the repository.
     * Params:
     * event = The `Event` to save.
     * 
     * Returns: The saved `Event`.
     */
    Event save(Event event) @safe;

    /**
     * Gets all events from the repository.
     *
     * Returns: An `InputRange` containing all `Event`s from the repository.
     */
    InputRange!Event findAll() @safe;

    /**
     * Gets an event by its id from the repository.
     * Params:
     * id = The id of the event to get.
     *
     * Returns: `Nullable!Event` containing the `Event` corresponding to
     *          $(D_PARAM id) in the repository or `null`, if no such event
     *          exists.
     */
    Nullable!Event findById(const string id) @safe;

    /**
     * Removes an event from the repository.
     * Params:
     * id = The id of the event to remove.
     */
    void deleteById(const string id) @safe;
}

/**
 * A MongoDB based implementation of `EventRepository`.
 */
class MongoDBEventRepository : EventRepository
{
    import fsicalmanagement.utility.serialization : deserializeBsonNothrow;
    import vibe.db.mongo.collection : MongoCollection;

private:
    @Value("events")
    MongoCollection events;

public:

    /**
     * Saves an event to the configured MongoDB collection.
     * Params:
     * event = The `Event` to save.
     * 
     * Returns: The saved `Event`.
     */
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

    /**
     * Gets all events from the configured MongoDB collection.
     *
     * Returns: An `InputRange` containing all `Event`s from the configured
     *          MongoDB collection.
     */
    InputRange!Event findAll() @safe
    {
        return events.find().map!(deserializeBsonNothrow!Event)
            .filter!(nullableEvent => !nullableEvent.isNull)
            .map!(nullableEvent => nullableEvent.get)
            .inputRangeObject;
    }

    /**
     * Gets an event by its id from the configured MongoDB collection.
     * Params:
     * id = The id of the event to get.
     *
     * Returns: `Nullable!Event` containing the `Event` corresponding to
     *          $(D_PARAM id) in the configured MongoDB collection or `null`, if
     *          no such event exists.
     */
    Nullable!Event findById(const string id) @safe
    {
        import vibe.data.bson : Bson;

        immutable result = events.findOne(["_id" : id]);

        if (result != Bson(null))
        {
            return result.deserializeBsonNothrow!Event;
        }
        return Nullable!Event.init;
    }

    /**
     * Removes an event from the configured MongoDB collection.
     * Params:
     * id = The id of the event to remove.
     */
    void deleteById(const string id) @safe
    {
        events.remove(["_id" : id]);
    }
}

/**
 * A MySQL based implementation of `EventRepository`.
 */
class MySQLEventRepository : EventRepository
{
private:
    import fsicalmanagement.utility.initialization : initOnce;
    import mysql.commands : exec, query;
    import mysql.connection : prepare;
    import mysql.pool : MySQLPool;
    import mysql.prepared : Prepared;
    import mysql.result : Row;

    MySQLPool pool;

    @Value("mysql.table.events")
    string eventsTableName;

public:
    ///
    this(MySQLPool pool) @safe @nogc pure nothrow
    {
        this.pool = pool;
    }

    /**
     * Saves an event to the configured MySQL table.
     * Params:
     * event = The `Event` to save.
     * 
     * Returns: The saved `Event`.
     */
    Event save(Event event) @trusted
    {
        auto preparedStatement()
        {
            static Prepared prepared;
            return initOnce!prepared(({
                    auto cn = pool.lockConnection();
                    return cn.prepare("INSERT INTO " ~ eventsTableName
                    ~ " (begin, end, name, description, type, shout)" ~ " VALUES(?, ?, ?, ?, ?, ?)");
                })());
        }

        auto prepared = preparedStatement;
        prepared.setArgs(event.begin, event.end, event.name, event.description,
                event.type.to!uint, event.shout);
        auto cn = pool.lockConnection();
        cn.exec(prepared);

        return event;
    }

    /**
     * Gets all events from the configured MySQL table.
     *
     * Returns: An `InputRange` containing all `Event`s from the configured
     *          MySQL table.
     */
    InputRange!Event findAll() @trusted
    {
        import std.array : array;

        auto preparedStatement()
        {
            static Prepared prepared;
            return initOnce!prepared(({
                    auto cn = pool.lockConnection();
                    return cn.prepare(
                    "SELECT id, begin, end, name, description, type, shout FROM " ~ eventsTableName);
                })());
        }

        auto prepared = preparedStatement;
        auto cn = pool.lockConnection();
        return cn.query(prepared).array
            .map!(r => toEvent(r))
            .filter!(nullableEvent => !nullableEvent.isNull)
            .map!(nullableEvent => nullableEvent.get)
            .inputRangeObject;
    }

    /**
     * Gets an event by its id from the configured MySQL table.
     * Params:
     * id = The id of the event to get.
     *
     * Returns: `Nullable!Event` containing the `Event` corresponding to
     *          $(D_PARAM id) in the configured MySQL table. or `null`, if no
     *          such event exists.
     */
    Nullable!Event findById(const string id) @trusted
    {
        auto preparedStatement()
        {
            static Prepared prepared;
            return initOnce!prepared(({
                    auto cn = pool.lockConnection();
                    return cn.prepare(
                    "SELECT id begin end name description type shout FROM "
                    ~ eventsTableName ~ " WHERE id = ?");
                })());
        }

        auto prepared = preparedStatement;
        prepared.setArg(0, id.to!uint);
        auto cn = pool.lockConnection();
        auto result = cn.query(prepared);

        if (!result.empty)
        {
            return toEvent(result.front);
        }
        return Nullable!Event.init;
    }

    /**
     * Removes an event from the configured MySQL table.
     * Params:
     * id = The id of the event to remove.
     */
    void deleteById(const string id) @trusted
    {
        auto preparedStatement()
        {
            static Prepared prepared;
            return initOnce!prepared(({
                    auto cn = pool.lockConnection();
                    return cn.prepare("DELETE FROM " ~ eventsTableName ~ " WHERE id = ?");
                })());
        }

        auto prepared = preparedStatement;
        prepared.setArg(0, id.to!uint);
        auto cn = pool.lockConnection();
        cn.exec(prepared);
    }

private:
    Nullable!Event toEvent(const Row r) @trusted nothrow
    {
        import fsicalmanagement.model.event : EventType;
        import std.datetime.date : Date;
        import std.traits : fullyQualifiedName;
        import vibe.core.log : logError;

        try
        {
            Event event;
            event.id = r[0].get!uint
                .to!string;
            event.begin = r[1].get!Date;
            if (!(r[2].type == typeid(typeof(null))))
                event.end = r[2].get!Date;
            event.name = r[3].get!string;
            event.description = r[4].get!string;
            event.type = r[5].get!uint
                .to!EventType;
            event.shout = r[6].get!byte
                .to!bool;
            return event.nullable;
        }
        catch (Exception e)
        {
            logError("Error while converting Row %s to %s:\n%s", r, fullyQualifiedName!Event, e);
        }
        return Nullable!Event.init;
    }
}
