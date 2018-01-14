module test.calendarwebapp.testjsonexport;

import calendarwebapp.event;
import calendarwebapp.jsonexport;

import poodinis;

import core.exception : AssertError;

import std.algorithm.iteration : each;
import std.datetime.date : Date, Month;
import std.exception : enforce;
import std.range.interfaces : InputRange, inputRangeObject;
import std.range.primitives : empty;

import unit_threaded;

@("JSONExporter.empty")
@system unittest
{
    auto container = new shared DependencyContainer();
    container.register!(EventStore, StubEventStore);
    container.register!JSONExporter;
    auto exporter = container.resolve!JSONExporter;
    exporter.write.each!(dayData => dayData.eventList.empty.shouldBeTrue);
}

@("JSONExporter.1 event")
@system unittest
{
    auto container = new shared DependencyContainer();
    container.register!(EventStore, StubEventStore);
    container.register!JSONExporter;
    auto exporter = container.resolve!JSONExporter;
    auto eventStore = container.resolve!EventStore;
    immutable event = Event("599090de97355141140fc698", Date(2018, 1, 14));
    eventStore.addEvent(event);
    exporter.write.each!(dayData => (dayData.year == 2018
            && dayData.month == Month.jan && dayData.day == 14) ? dayData.eventList.shouldEqual([event])
            : dayData.eventList.empty.shouldBeTrue);
}

@("DayJSONManager with begin > end")
@system unittest
{
    DayJSONManager(Date(2018, 1, 14), Date(2018, 1, 13)).shouldThrow!AssertError;
}

@("DayJSONManager with begin = end")
@system unittest
{
    DayJSONManager(Date(2018, 1, 14), Date(2018, 1, 14)).shouldThrow!AssertError;
}

@("DayJSONManager.getDayData with date < begin and 0 events")
@system unittest
{
    auto dayJSONManager = DayJSONManager(Date(2018, 1, 14), Date(2018, 1, 16));
    dayJSONManager.getDayData(Date(2018, 1, 13)).shouldThrow;
}

@("DayJSONManager.getDayData with date > end and 0 events")
@system unittest
{
    auto dayJSONManager = DayJSONManager(Date(2018, 1, 14), Date(2018, 1, 16));
    dayJSONManager.getDayData(Date(2018, 1, 17)).shouldThrow;
}

@("DayJSONManager.getDayData with date = end and 0 events")
@system unittest
{
    auto dayJSONManager = DayJSONManager(Date(2018, 1, 14), Date(2018, 1, 16));
    dayJSONManager.getDayData(Date(2018, 1, 16)).shouldThrow;
}

@("DayJSONManager.getDayData with date = begin and 0 events")
@system unittest
{
    auto dayJSONManager = DayJSONManager(Date(2018, 1, 14), Date(2018, 1, 16));
    dayJSONManager.getDayData(Date(2018, 1, 14)).shouldEqual(DayData(2018,
            Month.jan, "Januar", 14, DayType.Holiday, [], "Sonntag", []));
}

@("DayJSONManager.getDayData with begin < date < end and 0 events")
@system unittest
{
    auto dayJSONManager = DayJSONManager(Date(2018, 1, 14), Date(2018, 1, 16));
    dayJSONManager.getDayData(Date(2018, 1, 15)).shouldEqual(DayData(2018,
            Month.jan, "Januar", 15, DayType.Workday, [], "Montag", []));
}

@("DayJSONManager.getDayData with date < begin and 1 event")
@system unittest
{
    auto dayJSONManager = DayJSONManager(Date(2018, 1, 14), Date(2018, 1, 16));
    immutable event = Event("599090de97355141140fc698", Date(2018, 1, 14));
    dayJSONManager.addEvent(event);
    dayJSONManager.getDayData(Date(2018, 1, 13)).shouldThrow;
}

@("DayJSONManager.getDayData with date > end and 1 event")
@system unittest
{
    auto dayJSONManager = DayJSONManager(Date(2018, 1, 14), Date(2018, 1, 16));
    immutable event = Event("599090de97355141140fc698", Date(2018, 1, 14));
    dayJSONManager.addEvent(event);
    dayJSONManager.getDayData(Date(2018, 1, 17)).shouldThrow;
}

@("DayJSONManager.getDayData with date = end and 1 event")
@system unittest
{
    auto dayJSONManager = DayJSONManager(Date(2018, 1, 14), Date(2018, 1, 16));
    immutable event = Event("599090de97355141140fc698", Date(2018, 1, 14));
    dayJSONManager.addEvent(event);
    dayJSONManager.getDayData(Date(2018, 1, 16)).shouldThrow;
}

@("DayJSONManager.getDayData with date = begin and 1 event")
@system unittest
{
    auto dayJSONManager = DayJSONManager(Date(2018, 1, 14), Date(2018, 1, 15));
    immutable event = Event("599090de97355141140fc698", Date(2018, 1, 14));
    dayJSONManager.addEvent(event);
    dayJSONManager.getDayData(Date(2018, 1, 14)).shouldEqual(DayData(2018,
            Month.jan, "Januar", 14, DayType.Holiday, [event], "Sonntag", []));
}

@("DayJSONManager.getDayData with begin < date < end and 1 event")
@system unittest
{
    auto dayJSONManager = DayJSONManager(Date(2018, 1, 14), Date(2018, 1, 16));
    immutable event = Event("599090de97355141140fc698", Date(2018, 1, 15));
    dayJSONManager.addEvent(event);
    dayJSONManager.getDayData(Date(2018, 1, 15)).shouldEqual(DayData(2018,
            Month.jan, "Januar", 15, DayType.Workday, [event], "Montag", []));
}
