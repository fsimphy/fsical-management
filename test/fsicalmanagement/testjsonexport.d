module test.fsicalmanagement.testjsonexport;

import fsicalmanagement.configuration: Arguments, StubAppArgumentsInjector;
import fsicalmanagement.event;
import fsicalmanagement.jsonexport;

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
    container.register!(ValueInjector!Arguments, StubAppArgumentsInjector);
    auto exporter = container.resolve!JSONExporter;
    exporter.write.each!(dayData => dayData.events.empty.shouldBeTrue);
}

@("JSONExporter.write with 1 event")
@system unittest
{
    auto container = new shared DependencyContainer();
    container.register!(EventStore, StubEventStore);
    container.register!JSONExporter;
    container.register!(ValueInjector!Arguments, StubAppArgumentsInjector);
    auto exporter = container.resolve!JSONExporter;
    auto eventStore = container.resolve!EventStore;
    immutable event = Event("599090de97355141140fc698", Date(2018, 1, 14));
    eventStore.addEvent(event);
    exporter.write.each!(dayData => (dayData.year == 2018
            && dayData.month == Month.jan && dayData.day == 14) ? dayData.events.shouldEqual([event])
            : dayData.events.empty.shouldBeTrue);
}

@("JSONExporter.write with 2 events at the same date")
@system unittest
{
    auto container = new shared DependencyContainer();
    container.register!(EventStore, StubEventStore);
    container.register!JSONExporter;
    container.register!(ValueInjector!Arguments, StubAppArgumentsInjector);
    auto exporter = container.resolve!JSONExporter;
    auto eventStore = container.resolve!EventStore;
    immutable event1 = Event("599090de97355141140fc698", Date(2018, 1, 14));
    immutable event2 = Event("59cb9ad8fc0ba5751c0df02b", Date(2018, 1, 14));
    eventStore.addEvent(event1);
    eventStore.addEvent(event2);
    exporter.write(Date(2018, 1, 14)).each!(dayData => (dayData.year == 2018
            && dayData.month == Month.jan && dayData.day == 14) ? dayData.events.shouldEqual([event1,
            event2]) : dayData.events.empty.shouldBeTrue);
}

@("JSONExporter.write with 2 events at different dates")
@system unittest
{
    auto container = new shared DependencyContainer();
    container.register!(EventStore, StubEventStore);
    container.register!JSONExporter;
    container.register!(ValueInjector!Arguments, StubAppArgumentsInjector);
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
            dayData.events.shouldEqual([event1]);
        }
        else if (date == Date(2018, 1, 15))
        {
            dayData.events.shouldEqual([event2]);
        }
        else
        {
            dayData.events.empty.shouldBeTrue;
        }
    });
}

@("JSONExporter.write check date inbetween begin and end")
@system unittest
{
    auto container = new shared DependencyContainer();
    container.register!(EventStore, StubEventStore);
    container.register!JSONExporter;
    container.register!(ValueInjector!Arguments, StubAppArgumentsInjector);
    auto exporter = container.resolve!JSONExporter;
    DayData(2018, Month.jan, "Januar", 14, DayType.Holiday, [], "So", []).shouldBeIn(
            exporter.write(Date(2018, 1, 14)));
}

@("JSONExporter.write check date at begin")
@system unittest
{
    auto container = new shared DependencyContainer();
    container.register!(EventStore, StubEventStore);
    container.register!JSONExporter;
    container.register!(ValueInjector!Arguments, StubAppArgumentsInjector);
    auto exporter = container.resolve!JSONExporter;
    DayData(2018, Month.jan, "Januar", 1, DayType.Workday, [], "Mo", []).shouldBeIn(
            exporter.write(Date(2018, 1, 14)));
}

@("JSONExporter.write check date just after begin")
@system unittest
{
    auto container = new shared DependencyContainer();
    container.register!(EventStore, StubEventStore);
    container.register!JSONExporter;
    container.register!(ValueInjector!Arguments, StubAppArgumentsInjector);
    auto exporter = container.resolve!JSONExporter;
    DayData(2018, Month.jan, "Januar", 2, DayType.Workday, [], "Di", []).shouldBeIn(
            exporter.write(Date(2018, 1, 14)));
}

@("JSONExporter.write check date before begin")
@system unittest
{
    auto container = new shared DependencyContainer();
    container.register!(EventStore, StubEventStore);
    container.register!JSONExporter;
    container.register!(ValueInjector!Arguments, StubAppArgumentsInjector);
    auto exporter = container.resolve!JSONExporter;
    DayData(2017, Month.dec, "Dezember", 1, DayType.Holiday, [], "So", []).shouldNotBeIn(
            exporter.write(Date(2018, 1, 14)));
}

@("JSONExporter.write check date at end")
@system unittest
{
    auto container = new shared DependencyContainer();
    container.register!(EventStore, StubEventStore);
    container.register!JSONExporter;
    container.register!(ValueInjector!Arguments, StubAppArgumentsInjector);
    auto exporter = container.resolve!JSONExporter;
    DayData(2018, Month.mar, "März", 31, DayType.Weekend, [], "Sa", []).shouldBeIn(
            exporter.write(Date(2018, 1, 14)));
}

@("JSONExporter.write check date just before end")
@system unittest
{
    auto container = new shared DependencyContainer();
    container.register!(EventStore, StubEventStore);
    container.register!JSONExporter;
    container.register!(ValueInjector!Arguments, StubAppArgumentsInjector);
    auto exporter = container.resolve!JSONExporter;
    DayData(2018, Month.mar, "März", 30, DayType.Workday, [], "Fr", []).shouldBeIn(
            exporter.write(Date(2018, 1, 14)));
}

@("JSONExporter.write check date after end")
@system unittest
{
    auto container = new shared DependencyContainer();
    container.register!(EventStore, StubEventStore);
    container.register!JSONExporter;
    container.register!(ValueInjector!Arguments, StubAppArgumentsInjector);
    auto exporter = container.resolve!JSONExporter;
    DayData(2018, Month.apr, "April", 1, DayType.Holiday, [], "So", []).shouldNotBeIn(
            exporter.write(Date(2018, 1, 14)));
}

@("DayDataManager with begin > end")
@system unittest
{
    DayDataManager(Date(2018, 1, 14), Date(2018, 1, 13)).shouldThrow!AssertError;
}

@("DayDataManager with begin = end")
@system unittest
{
    DayDataManager(Date(2018, 1, 14), Date(2018, 1, 14)).shouldThrow!AssertError;
}

@("DayDataManager.getDayData with date < begin and 0 events")
@system unittest
{
    auto dayDataManager = DayDataManager(Date(2018, 1, 14), Date(2018, 1, 16));
    dayDataManager.getDayData(Date(2018, 1, 13)).shouldThrow;
}

@("DayDataManager.getDayData with date > end and 0 events")
@system unittest
{
    auto dayDataManager = DayDataManager(Date(2018, 1, 14), Date(2018, 1, 16));
    dayDataManager.getDayData(Date(2018, 1, 17)).shouldThrow;
}

@("DayDataManager.getDayData with date = end and 0 events")
@system unittest
{
    auto dayDataManager = DayDataManager(Date(2018, 1, 14), Date(2018, 1, 16));
    dayDataManager.getDayData(Date(2018, 1, 16)).shouldThrow;
}

@("DayDataManager.getDayData with date = begin and 0 events")
@system unittest
{
    auto dayDataManager = DayDataManager(Date(2018, 1, 14), Date(2018, 1, 16));
    dayDataManager.getDayData(Date(2018, 1, 14)).shouldEqual(DayData(2018,
            Month.jan, "Januar", 14, DayType.Holiday, [], "So", []));
}

@("DayDataManager.getDayData with begin < date < end and 0 events")
@system unittest
{
    auto dayDataManager = DayDataManager(Date(2018, 1, 14), Date(2018, 1, 16));
    dayDataManager.getDayData(Date(2018, 1, 15)).shouldEqual(DayData(2018,
            Month.jan, "Januar", 15, DayType.Workday, [], "Mo", []));
}

@("DayDataManager.getDayData with date < begin and 1 event")
@system unittest
{
    auto dayDataManager = DayDataManager(Date(2018, 1, 14), Date(2018, 1, 16));
    immutable event = Event("599090de97355141140fc698", Date(2018, 1, 14));
    dayDataManager.addEvent(event);
    dayDataManager.getDayData(Date(2018, 1, 13)).shouldThrow;
}

@("DayDataManager.getDayData with date > end and 1 event")
@system unittest
{
    auto dayDataManager = DayDataManager(Date(2018, 1, 14), Date(2018, 1, 16));
    immutable event = Event("599090de97355141140fc698", Date(2018, 1, 14));
    dayDataManager.addEvent(event);
    dayDataManager.getDayData(Date(2018, 1, 17)).shouldThrow;
}

@("DayDataManager.getDayData with date = end and 1 event")
@system unittest
{
    auto dayDataManager = DayDataManager(Date(2018, 1, 14), Date(2018, 1, 16));
    immutable event = Event("599090de97355141140fc698", Date(2018, 1, 14));
    dayDataManager.addEvent(event);
    dayDataManager.getDayData(Date(2018, 1, 16)).shouldThrow;
}

@("DayDataManager.getDayData with date = begin and 1 event")
@system unittest
{
    auto dayDataManager = DayDataManager(Date(2018, 1, 14), Date(2018, 1, 15));
    immutable event = Event("599090de97355141140fc698", Date(2018, 1, 14));
    dayDataManager.addEvent(event);
    dayDataManager.getDayData(Date(2018, 1, 14)).shouldEqual(DayData(2018,
            Month.jan, "Januar", 14, DayType.Holiday, [event], "So", []));
}

@("DayDataManager.getDayData with begin < date < end and 1 event")
@system unittest
{
    auto dayDataManager = DayDataManager(Date(2018, 1, 14), Date(2018, 1, 16));
    immutable event = Event("599090de97355141140fc698", Date(2018, 1, 15));
    dayDataManager.addEvent(event);
    dayDataManager.getDayData(Date(2018, 1, 15)).shouldEqual(DayData(2018,
            Month.jan, "Januar", 15, DayType.Workday, [event], "Mo", []));
}
