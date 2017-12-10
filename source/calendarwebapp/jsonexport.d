module calendarwebapp.jsonexport;

import calendarwebapp.event : Event, EventStore;

import core.time;
import std.datetime.date;
import std.datetime.interval;
import std.datetime.systime;

import poodinis : Autowire;

import vibe.data.serialization : name;

struct DayJSONManager
{
private:
    Date begin, end;
    Event[][Date] events;

public:
    this(in Date begin, in Date end)
    {
        this.begin = begin;
        this.end = end;
    }

    void addEvent(Event event)
    {
        if (Interval!Date(begin, end).contains(event.begin))
        {
            if (event.end.isNull)
            {
                event.end = event.begin;
            }
            events[event.begin] ~= event;
        }
    }

    auto getDayData(Date date)
    {
        import std.exception : enforce;

        enforce(Interval!Date(begin, end).contains(date));
        return DayData(date.year, date.month, date.month.toGerString, date.day,
                date.dayOfWeek.dayType, events[date], date.dayOfWeek.toGerString, []);
    }
}

class JSONExporter
{
private:
    @Autowire EventStore eventStore;

public:
    auto write() @system
    {
        import std.algorithm : each, map;
        import std.range : array;
        import std.format : format;

        immutable today = cast(Date) Clock.currTime;
        immutable todayName = "%s, %s. %s. %s".format(today.dayOfWeek.toGerString,
                today.day, today.month.toGerString, today.year);
        immutable todays = Todays(today.year, today.month, today.day, today.dayOfWeek, todayName);
        auto startDate = Date(today.year, today.month, 1);
        auto endDate = startDate;
        endDate.add!"months"(3);
        auto dayJSONManager = new DayJSONManager(startDate, endDate);
        foreach (event; eventStore.getEventsBeginningBetween(startDate, endDate))
        {
            dayJSONManager.addEvent(event);
        }
        return Interval!Date(startDate, endDate).fwdRange(date => date + 1.dur!"days")
            .map!(day => dayJSONManager.getDayData(day)).array;
    }
}

private:

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

enum DayType
{
    Workday,
    Holiday,
    Weekend
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

struct DayData
{
    short year;
    Month month;
    string monthName;
    ubyte day;
    @name("daytype") DayType dayType;
    Event[] eventList;
    @name("wday") string weekDayName;
    Line[] lines;
}

struct Line
{
}

struct Todays
{
    short year;
    Month month;
    ubyte day;
    DayOfWeek weekDay;
    string todayName;
}

struct OutputFormat
{
    Todays today;
    @name("tracked_days") DayData trackedDays;
}
