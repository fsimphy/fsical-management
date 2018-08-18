module fsicalmanagement.resources.event_resource;

import vibe.web.auth;
import vibe.web.web;

/**
 * Resource containing endpoints for displaying, creating and deleting events.
 */
@requiresAuth class EventResource
{
    import fsicalmanagement.data.validation_error_data : ValidationErrorData;
    import fsicalmanagement.facade.event_facade : EventFacade;
    import fsicalmanagement.model.event : Event, EventType;
    import fsicalmanagement.resources.mixins.authentication : Authentication;
    import std.datetime : Date;
    import std.typecons : Nullable;

private:
    EventFacade eventFacade;

    mixin Authentication;

public:
    ///
    this(EventFacade eventFacade) @safe @nogc pure nothrow
    {
        this.eventFacade = eventFacade;
    }

    /**
     * Displays a list of all events.
     * _error = An error message, set automatically by vibe.d when this
     *          endpoint is used as an error page.
     */
    @auth(Role.user | Role.admin)
    void index(string _error = null)
    {
        auto events = eventFacade.getAllEvents;
        immutable authInfo = this.authInfo.value;
        render!("showevents.dt", _error, events, authInfo);
    }

    /**
     * Displays the event creation page.
     * Params:
     * _error = Information about which fields failed validation.
     *          Automatically provided by vibe.d, when this endpoint is used
     *          as an error page.
     */
    @auth(Role.user | Role.admin)
    void getCreateevent(ValidationErrorData _error = ValidationErrorData.init)
    {
        immutable authInfo = this.authInfo.value;
        render!("createevent.dt", _error, authInfo);
    }

    /**
     * Creates an event. Redirects to `getCreateevent` on failure.
     * Params:
     * begin = The date when the event begins or when it takes place if it is
     *         a single day event.
     * end = The date when the event ends or `null`, which makes the event a
     *       single day event.
     * description = The description of the event.
     * name = The name of the event.
     * type = The type of the event.
     * shout = A flag specifying if the event should be announced.
     */
    @auth(Role.user | Role.admin)
    @errorDisplay!getCreateevent void postCreateevent(Date begin,
            Nullable!Date end, string description, string name, EventType type, bool shout)
    {
        eventFacade.createEvent(begin, end, description, name, type, shout);
        redirect("/");
    }

    /**
     * Removes an event. Redirects to `index` on failure.
     * Params:
     * id = The id of the event to remove.
     */
    @auth(Role.user | Role.admin)
    @errorDisplay!index void postRemoveevent(string id)
    {
        eventFacade.removeEventById(id);
        redirect("/");
    }
}
