module test.calendarwebapp.testjsonexport;

import calendarwebapp.event;
import calendarwebapp.jsonexport;

import core.exception : AssertError;

import poodinis;

import std.algorithm.iteration : each;
import std.conv : to;
import std.datetime.date : Date, Month;
import std.exception : enforce;
import std.range.interfaces : InputRange, inputRangeObject;
import std.range.primitives : empty;

import unit_threaded;

@("JSONExporter.write with 0 events")
@system unittest
{
    auto container = new shared DependencyContainer();
    container.register!(EventStore, StubEventStore);
    container.register!JSONExporter;
    auto exporter = container.resolve!JSONExporter;
    exporter.write.each!(dayData => dayData.eventList.empty.shouldBeTrue);
}

@("JSONExporter.write with 1 event")
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

@("JSONExporter.write with 2 events at the same date")
@system unittest
{
    auto container = new shared DependencyContainer();
    container.register!(EventStore, StubEventStore);
    container.register!JSONExporter;
    auto exporter = container.resolve!JSONExporter;
    auto eventStore = container.resolve!EventStore;
    immutable event1 = Event("599090de97355141140fc698", Date(2018, 1, 14));
    immutable event2 = Event("59cb9ad8fc0ba5751c0df02b", Date(2018, 1, 14));
    eventStore.addEvent(event1);
    eventStore.addEvent(event2);
    exporter.write(Date(2018, 1, 14)).each!(dayData => (dayData.year == 2018
            && dayData.month == Month.jan && dayData.day == 14) ? dayData.eventList.shouldEqual([event1,
            event2]) : dayData.eventList.empty.shouldBeTrue);
}

@("JSONExporter.write with 2 events at different dates")
@system unittest
{
    auto container = new shared DependencyContainer();
    container.register!(EventStore, StubEventStore);
    container.register!JSONExporter;
    auto exporter = container.resolve!JSONExporter;
    auto eventStore = container.resolve!EventStore;
    immutable event1 = Event("599090de97355141140fc698", Date(2018, 1, 14));
    immutable event2 = Event("59cb9ad8fc0ba5751c0df02b", Date(2018, 1, 15));
    eventStore.addEvent(event1);
    eventStore.addEvent(event2);
    exporter.write(Date(2018, 1, 14)).each!((dayData) {
        immutable date = Date(dayData.year, dayData.month.to!int, dayData.day);
        if (date == Date(2018, 1, 14))
        {
            dayData.eventList.shouldEqual([event1]);
        }
        else if (date == Date(2018, 1, 15))
        {
            dayData.eventList.shouldEqual([event2]);
        }
        else
        {
            dayData.eventList.empty.shouldBeTrue;
        }
    });
}

@("JSONExporter.write check date inbetween begin and end")
@system unittest
{
    auto container = new shared DependencyContainer();
    container.register!(EventStore, StubEventStore);
    container.register!JSONExporter;
    auto exporter = container.resolve!JSONExporter;
    DayData(2018, Month.jan, "Januar", 14, DayType.Holiday, [], "Sonntag", []).shouldBeIn(
            exporter.write(Date(2018, 1, 14)));
}

@("JSONExporter.write check date at begin")
@system unittest
{
    auto container = new shared DependencyContainer();
    container.register!(EventStore, StubEventStore);
    container.register!JSONExporter;
    auto exporter = container.resolve!JSONExporter;
    DayData(2018, Month.jan, "Januar", 1, DayType.Workday, [], "Montag", []).shouldBeIn(
            exporter.write(Date(2018, 1, 14)));
}

@("JSONExporter.write check date just after begin")
@system unittest
{
    auto container = new shared DependencyContainer();
    container.register!(EventStore, StubEventStore);
    container.register!JSONExporter;
    auto exporter = container.resolve!JSONExporter;
    DayData(2018, Month.jan, "Januar", 2, DayType.Workday, [], "Dienstag", []).shouldBeIn(
            exporter.write(Date(2018, 1, 14)));
}

@("JSONExporter.write check date before begin")
@system unittest
{
    auto container = new shared DependencyContainer();
    container.register!(EventStore, StubEventStore);
    container.register!JSONExporter;
    auto exporter = container.resolve!JSONExporter;
    DayData(2017, Month.dec, "Dezember", 1, DayType.Holiday, [], "Sonntag", []).shouldNotBeIn(
            exporter.write(Date(2018, 1, 14)));
}

@("JSONExporter.write check date at end")
@system unittest
{
    auto container = new shared DependencyContainer();
    container.register!(EventStore, StubEventStore);
    container.register!JSONExporter;
    auto exporter = container.resolve!JSONExporter;
    DayData(2018, Month.mar, "März", 31, DayType.Weekend, [], "Samstag", []).shouldBeIn(
            exporter.write(Date(2018, 1, 14)));
}

@("JSONExporter.write check date just before end")
@system unittest
{
    auto container = new shared DependencyContainer();
    container.register!(EventStore, StubEventStore);
    container.register!JSONExporter;
    auto exporter = container.resolve!JSONExporter;
    DayData(2018, Month.mar, "März", 30, DayType.Workday, [], "Freitag", []).shouldBeIn(
            exporter.write(Date(2018, 1, 14)));
}

@("JSONExporter.write check date after end")
@system unittest
{
    auto container = new shared DependencyContainer();
    container.register!(EventStore, StubEventStore);
    container.register!JSONExporter;
    auto exporter = container.resolve!JSONExporter;
    DayData(2018, Month.apr, "April", 1, DayType.Holiday, [], "Sonntag", []).shouldNotBeIn(
            exporter.write(Date(2018, 1, 14)));
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
