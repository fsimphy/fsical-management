module fsicalmanagement.jsonexport;

import fsicalmanagement.event : Event, EventStore;
import fsicalmanagement.configuration : Arguments;

import core.time;

import std.algorithm.iteration : each;

import std.datetime.date;
import std.datetime.interval;
import std.datetime.systime;

import std.format : format;
import poodinis : Autowire, Value;

import vibe.data.serialization : serializationName = name;

struct DayDataManager
{
private:
    Date begin, end;
    Event[][Date] events;

public:
    this(in Date begin, in Date end)
    in
    {
        assert(begin < end,
                "DayDataManager: begin (%s) needs to be earlier than end (%s)".format(begin, end));
    }
    do
    {
        this.begin = begin;
        this.end = end;
        Interval!Date(this.begin, this.end).fwdRange(date => date + 1.dur!"days")
            .each!(date => events[date] = []);
    }

    void addEvent(Event event)
    {
        if (Interval!Date(begin, end).contains(event.begin))
        {
            events[event.begin] ~= event;
        }
    }

    auto getDayData(Date date)
    {
        import std.exception : enforce;

        enforce(Interval!Date(begin, end).contains(date));
        return DayData(date.year, date.month, date.month.toGerString, date.day,
                date.dayOfWeek.dayType, events[date], date.dayOfWeek.toShortGerString, []);
    }
}

class JSONExporter
{
private:
    @Autowire EventStore eventStore;
    @Value() Arguments arguments;

public:
    auto write(in Date today = cast(Date) Clock.currTime) @system
    {
        import std.algorithm : each, map;
        import std.range : array;
        import std.format : format;

        immutable todayName = dateFormatString.format(today.dayOfWeek.toGerString,
                today.day, today.month.toGerString, today.year);
        immutable todays = Today(today.year, today.month, today.day, today.dayOfWeek, todayName);
        auto startDate = Date(today.year, today.month, 1);
        auto endDate = startDate;
        endDate.add!"months"(3);
        auto dayDataManager = new DayDataManager(startDate, endDate);
        foreach (event; eventStore.getEventsBeginningBetween(startDate, endDate))
        {
            dayDataManager.addEvent(event);
        }
        return Interval!Date(startDate, endDate).fwdRange(date => date + 1.dur!"days")
            .map!(day => dayDataManager.getDayData(day)).array;
    }

    void exportJSON() @system
    {
        import vibe.core.file : writeFile;
        import vibe.core.path : Path;
        import vibe.data.json : serializeToPrettyJson;
        import std.datetime.systime : Clock;
        import std.datetime.date : Date;

        struct OutputFormat
        {
        private:
            alias TrackedDays = typeof(write());
        public:
            Today today;
            @serializationName("tracked_days") TrackedDays trackedDays;
        }

        immutable today = cast(Date) Clock.currTime;
        auto output = OutputFormat(Today(today.year, today.month, today.day,
                today.dayOfWeek, dateFormatString.format(today.dayOfWeek.toGerString,
                today.day, today.month.toGerString, today.year)), this.write());
        Path(arguments.output).writeFile(cast(ubyte[]) output.serializeToPrettyJson);
    }
}

struct DayData
{
    short year;
    Month month;
    string monthName;
    ubyte day;
    @serializationName("daytype") DayType dayType;
    Event[] events;
    @serializationName("wday") string weekDayName;
    Line[] lines;
}

enum DayType
{
    Workday,
    Holiday,
    Weekend
}

private:

enum dateFormatString = "%s, %s. %s, %s";

string toGerString(Month m)
{
    final switch (m) with (Month)
    {
    case jan:
        return "Januar";
    case feb:
        return "Februar";
    case mar:
        return "März";
    case apr:
        return "April";
    case may:
        return "Mai";
    case jun:
        return "Juni";
    case jul:
        return "Juli";
    case aug:
        return "August";
    case sep:
        return "September";
    case oct:
        return "Oktober";
    case nov:
        return "November";
    case dec:
        return "Dezember";
    }
}

string toGerString(DayOfWeek d)
{
    final switch (d) with (DayOfWeek)
    {
    case mon:
        return "Montag";
    case tue:
        return "Dienstag";
    case wed:
        return "Mittwoch";
    case thu:
        return "Donnerstag";
    case fri:
        return "Freitag";
    case sat:
        return "Samstag";
    case sun:
        return "Sonntag";
    }
}

string toShortGerString(DayOfWeek d)
{
    final switch (d) with (DayOfWeek)
    {
    case mon:
        return "Mo";
    case tue:
        return "Di";
    case wed:
        return "Mi";
    case thu:
        return "Do";
    case fri:
        return "Fr";
    case sat:
        return "Sa";
    case sun:
        return "So";
    }
}

DayType dayType(DayOfWeek dayOfWeek)
{
    switch (dayOfWeek) with (DayOfWeek)
    {
    case sat:
        return DayType.Weekend;
    case sun:
        return DayType.Holiday;
    default:
        return DayType.Workday;
    }
}

struct Line
{
}

struct Today
{
    short year;
    Month month;
    ubyte day;
    @serializationName("weekday") DayOfWeek weekDay;
    string name;
}
