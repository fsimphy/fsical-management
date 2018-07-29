module fsicalmanagement.facade.event_facade;

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
    this(EventRepository eventRepository)
    {
        this.eventRepository = eventRepository;
    }

    InputRange!Event getAllEvents() @safe
    {
        return eventRepository.findAll;
    }

    Event createEvent(const Date begin, const Nullable!Date end,
            const string description, const string name, const EventType type, const bool shout) @safe
    {
        import core.time : days;
        import std.array : replace, split;
        import std.exception : enforce;

        if (!end.isNull)
            enforce(end - begin >= 1.days, "Multiday events need to last at least one day.");
        immutable event = eventRepository.save(Event("", begin, end, name,
                description.replace("\r", ""), type, shout));

        logInfo("Stored event %s in the database", event);
        return event;

    }

    void removeEventById(const string id) @safe
    {
        eventRepository.deleteById(id);
        logInfo("Deleted event with id %s from the database", id);
    }
}
