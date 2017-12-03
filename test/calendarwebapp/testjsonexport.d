module test.calendarwebapp.testjsonexport;

import calendarwebapp.jsonexport;

import unit_threaded;
import std.datetime.date : Date;

@("calendarwebapp.JSONExporter")
@system unittest
{
    auto exporter = new JSONExporter;
    exporter.write.shouldEqual(Date(2018, 2, 1));
}
