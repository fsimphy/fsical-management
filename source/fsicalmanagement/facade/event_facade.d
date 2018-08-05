module fsicalmanagement.facade.event_facade;

/**
 * Provides functionality to get, create and remove events.
 */
class EventFacade
{
    import fsicalmanagement.dataaccess.event_repository : EventRepository;
    import fsicalmanagement.model.event : Event, EventType;
    import std.datetime.date : Date;
    import std.range.interfaces : InputRange;
    import std.typecons : Nullable;
    import vibe.core.log : logInfo;

private:
    EventRepository eventRepository;

public:
    ///
    this(EventRepository eventRepository) @safe @nogc pure nothrow
    {
        this.eventRepository = eventRepository;
    }

    /**
     * Gets all events.
     *
     * Returns: An `InputRange` containing all `Event`s.
     */
    InputRange!Event getAllEvents() @safe
    {
        return eventRepository.findAll;
    }

    /**
     * Creates an event.
     * Params:
     * begin = The date when the event begins or when it takes place if it is
     *         a single day event.
     * end = The date when the event ends or `null`, which makes the event a
     *       single day event.
     * description = The description of the event.
     * name = The name of the event.
     * type = The type of the event.
     * shout = A flag specifying if the event should be announced.
     *
     * Returns: The created `Event`.
     *
     * Throws: `Exception` if $(D_PARAM end) is not after $(D_PARAM begin).
     */
    Event createEvent(const Date begin, const Nullable!Date end,
            const string description, const string name, const EventType type, const bool shout) @safe
    {
        import core.time : days;
        import std.array : replace;
        import std.exception : enforce;

        if (!end.isNull)
            enforce(end - begin >= 1.days, "Multiday events need to last at least one day.");
        immutable event = eventRepository.save(Event("", begin, end, name,
                description.replace("\r", ""), type, shout));

        logInfo("Stored event %s", event);
        return event;
    }

    /**
     * Removes an event.
     * Params:
     * id = The id of the event to remove.
     */
    void removeEventById(const string id) @safe
    {
        eventRepository.deleteById(id);
        logInfo("Deleted event with id %s", id);
    }
}
