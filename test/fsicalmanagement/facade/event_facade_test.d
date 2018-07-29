module test.fsicalmanagement.facade.event_facade_test;

import fsicalmanagement.dataaccess.event_repository : EventRepository;
import fsicalmanagement.facade.event_facade : EventFacade;
import fsicalmanagement.model.event : Event, EventType;
import std.range.interfaces : inputRangeObject;
import std.typecons : Nullable, nullable;
import std.datetime.date : Date;

import unit_threaded.mock : mock;
import unit_threaded.should : shouldBeSameSetAs;

@("AuthenticationFacade.getAllEvents")
unittest
{
    // given
    auto eventRepositoryMock = mock!EventRepository;
    auto event1 = Event("5a9c2cbd52e14fca100e76cd", Date(2018, 7, 20), Nullable!Date.init,
            "Some event", "Some description", EventType.General_University_Event, false);
    auto event2 = Event("5a9c39a11b7add86399c1d36", Date(2018, 7, 16), Date(2018, 7, 17).nullable,
            "Some other event", "Some other description", EventType.FSI_Event, false);

    eventRepositoryMock.returnValue!"findAll"([event1, event2].inputRangeObject);
    auto underTest = new EventFacade(eventRepositoryMock);

    // when
    auto allEvents = underTest.getAllEvents();

    // then
    allEvents.shouldBeSameSetAs([event1, event2]);
}
