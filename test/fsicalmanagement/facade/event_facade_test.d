module test.fsicalmanagement.facade.event_facade_test;

import fsicalmanagement.dataaccess.event_repository : EventRepository;
import fsicalmanagement.facade.event_facade : EventFacade;
import fsicalmanagement.model.event : Event, EventType;
import std.datetime.date : Date;
import std.range.interfaces : inputRangeObject;
import std.typecons : Nullable, nullable;
import unit_threaded.attrs : getValue, Values;
import unit_threaded.mock : mock;
import unit_threaded.should : shouldBeSameSetAs, shouldEqual, shouldThrow;

@("AuthenticationFacade.getAllEvents")
unittest
{
        // given
        auto eventRepositoryMock = mock!EventRepository;
        auto event1 = Event("5a9c2cbd52e14fca100e76cd", Date(2018, 7, 20), Nullable!Date.init,
                        "Some event", "Some description",
                        EventType.General_University_Event, false);
        auto event2 = Event("5a9c39a11b7add86399c1d36", Date(2018, 7, 16), Date(2018, 7, 17).nullable,
                        "Some other event", "Some other description", EventType.FSI_Event, false);

        eventRepositoryMock.returnValue!"findAll"([event1, event2].inputRangeObject);
        auto underTest = new EventFacade(eventRepositoryMock);

        // when
        auto allEvents = underTest.getAllEvents();

        // then
        allEvents.shouldBeSameSetAs([event1, event2]);
}

@("AuthenticationFacade.createEvent single day")
unittest
{
        import std.array : replace;

        // given
        auto eventRepositoryMock = mock!EventRepository;
        immutable generatedEventId = "5a9c2cbd52e14fca100e76cd";
        immutable eventId = "";
        immutable eventBegin = Date(2018, 7, 20);
        immutable eventEnd = Nullable!Date.init;
        immutable eventName = "Some event";
        immutable eventDescription = "Some\r\nmultiline\r\ndescription";
        immutable eventType = EventType.General_University_Event;
        immutable shout = false;

        auto callingEvent = Event(eventId, eventBegin, eventEnd, eventName,
                        eventDescription.replace("\r", ""), eventType, shout);
        auto resultingEvent = Event(generatedEventId, eventBegin, eventEnd,
                        eventName, eventDescription.replace("\r", ""), eventType, shout);

        eventRepositoryMock.returnValue!"save"(resultingEvent);
        auto underTest = new EventFacade(eventRepositoryMock);

        // when
        immutable event = underTest.createEvent(eventBegin, eventEnd,
                        eventDescription, eventName, eventType, shout);

        // then
        event.shouldEqual(resultingEvent);
        eventRepositoryMock.expectCalled!"save"(callingEvent);
}

@("AuthenticationFacade.createEvent multi day success")
@Values(Date(2018, 7, 21), Date(2018, 7, 22), Date(2018, 9, 10), Date(2019, 2, 13))
unittest
{
        import std.array : replace;

        // given
        auto eventRepositoryMock = mock!EventRepository;
        immutable generatedEventId = "5a9c2cbd52e14fca100e76cd";
        immutable eventId = "";
        immutable eventBegin = Date(2018, 7, 20);
        immutable eventEnd = getValue!Date.nullable;
        immutable eventName = "Some event";
        immutable eventDescription = "Some\r\nmultiline\r\ndescription";
        immutable eventType = EventType.General_University_Event;
        immutable shout = false;

        auto callingEvent = Event(eventId, eventBegin, eventEnd, eventName,
                        eventDescription.replace("\r", ""), eventType, shout);
        auto resultingEvent = Event(generatedEventId, eventBegin, eventEnd,
                        eventName, eventDescription.replace("\r", ""), eventType, shout);

        eventRepositoryMock.returnValue!"save"(resultingEvent);
        auto underTest = new EventFacade(eventRepositoryMock);

        // when
        immutable event = underTest.createEvent(eventBegin, eventEnd,
                        eventDescription, eventName, eventType, shout);

        // then
        event.shouldEqual(resultingEvent);
        eventRepositoryMock.expectCalled!"save"(callingEvent);
}

@("AuthenticationFacade.createEvent multi day failure")
@Values(Date(2018, 7, 20), Date(2018, 7, 19), Date(2018, 4, 10), Date(2017, 12, 24))
unittest
{
        import std.array : replace;

        // given
        auto eventRepositoryMock = mock!EventRepository;
        immutable eventBegin = Date(2018, 7, 20);
        immutable eventEnd = getValue!Date.nullable;
        immutable eventName = "Some event";
        immutable eventDescription = "Some\r\nmultiline\r\ndescription";
        immutable eventType = EventType.General_University_Event;
        immutable shout = false;

        auto underTest = new EventFacade(eventRepositoryMock);

        // when
        immutable createEventCall = {
                underTest.createEvent(eventBegin, eventEnd, eventDescription,
                                eventName, eventType, shout);
        };

        // then
        createEventCall().shouldThrow!Exception;
}

@("AuthenticationFacade.removeEventById")
@Values("5a9c2cbd52e14fca100e76cd", "5a9c39a11b7add86399c1d36", "5a9c3a1f1b7add86399c1d37")
unittest
{
        import std.array : replace;

        // given
        auto eventRepositoryMock = mock!EventRepository;
        immutable eventId = getValue!string;

        auto underTest = new EventFacade(eventRepositoryMock);

        // when
        underTest.removeEventById(eventId);

        // then
        eventRepositoryMock.expectCalled!"deleteById"(eventId);
}
