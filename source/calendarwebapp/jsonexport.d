module calendarwebapp.jsonexport;

import calendarwebapp.event : Event, EventStore;

import core.time;
import std.datetime.date;
import std.datetime.interval;
import std.datetime.systime;

import poodinis : Autowire;

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
        if (Interval(begin, end).contains(event.begin))
        {
            if (event.end.isNull)
            {
                event.end = event.begin;
            }
            events[event.begin] ~= event;
        }
    }
}

class JSONExporter
{
private:
    @Autowire EventStore eventStore;

public:
    auto write() @system
    {
        import std.format : format;

        immutable today = cast(Date) Clock.currTime;
        immutable todayName = "%s, %s. %s. %s".format(today.dayOfWeek.toGerString,
                today.day, today.month.toGerString, today.year);
        auto startDate = Date(today.year, today.month, 1);
        auto endDate = startDate;
        endDate.add!"months"(3);
        return endDate;
    }

}

private:

string toGerString(Month m)
{
    final switch (m) with (Month)
    {
    case jan:
        return "Januar";
        break;
    case feb:
        return "Februar";
        break;
    case mar:
        return "März";
        break;
    case apr:
        return "April";
        break;
    case may:
        return "Mai";
        break;
    case jun:
        return "Juni";
        break;
    case jul:
        return "Juli";
        break;
    case aug:
        return "August";
        break;
    case sep:
        return "September";
        break;
    case oct:
        return "Oktober";
        break;
    case nov:
        return "November";
        break;
    case dec:
        return "Dezember";
        break;
    }
}

string toGerString(DayOfWeek d)
{
    final switch (d) with (DayOfWeek)
    {
    case mon:
        return "Montag";
        break;
    case tue:
        return "Dienstag";
        break;
    case wed:
        return "Mittwoch";
        break;
    case thu:
        return "Donnerstag";
        break;
    case fri:
        return "Freitag";
        break;
    case sat:
        return "Samstag";
        break;
    case sun:
        return "Sonntag";
        break;
    }
}
