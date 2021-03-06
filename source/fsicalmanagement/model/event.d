module fsicalmanagement.model.event;

/**
 * Represents the type of an event.
 */
enum EventType
{
    Holiday,
    Birthday,
    FSI_Event,
    General_University_Event,
    Any
}

/**
 * Represents an event.
 */
struct Event
{
    import std.datetime.date : Date;
    import std.typecons : Nullable;
    import vibe.data.serialization : serializationName = name;

    ///
    @serializationName("_id") string id;
    ///
    @serializationName("date") Date begin;
    ///
    @serializationName("end_date") Nullable!Date end;
    ///
    string name;
    ///
    @serializationName("desc") string description;
    ///
    @serializationName("etype") EventType type;
    ///
    bool shout;
}
