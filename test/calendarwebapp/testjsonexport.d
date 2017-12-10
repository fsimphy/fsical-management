module test.calendarwebapp.testjsonexport;

import calendarwebapp.event;
import calendarwebapp.jsonexport;

import poodinis;

import std.algorithm;
import std.datetime.date : Date;
import std.exception : enforce;
import std.range.interfaces : InputRange, inputRangeObject;

import unit_threaded;

@("calendarwebapp.JSONExporter")
@system unittest
{
    auto container = new shared DependencyContainer();
    container.register!(EventStore, StubEventStore);
    container.register!(JSONExporter);
}
