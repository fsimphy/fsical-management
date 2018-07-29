module fsicalmanagement.resources.event_resource;

import vibe.web.auth;
import vibe.web.web;

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
    this(EventFacade eventFacade)
    {
        this.eventFacade = eventFacade;
    }

    @auth(Role.user | Role.admin)
    void index()
    {
        auto events = eventFacade.getAllEvents;
        immutable authInfo = this.authInfo.value;
        render!("showevents.dt", events, authInfo);
    }

    @auth(Role.user | Role.admin)
    void getCreateevent(ValidationErrorData _error = ValidationErrorData.init)
    {
        immutable authInfo = this.authInfo.value;
        render!("createevent.dt", _error, authInfo);
    }

    @auth(Role.user | Role.admin)
    @errorDisplay!getCreateevent void postCreateevent(Date begin,
            Nullable!Date end, string description, string name, EventType type, bool shout)
    {
        eventFacade.createEvent(begin, end, description, name, type, shout);
        redirect("/");
    }

    @auth(Role.user | Role.admin)
    void postRemoveevent(string id)
    {
        eventFacade.removeEventById(id);
        redirect("/");
    }
}
