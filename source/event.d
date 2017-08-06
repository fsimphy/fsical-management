module event;

import std.datetime.date;
import std.typecons : Nullable;

import vibe.core.file: existsFile, readFileUTF8, writeFileUTF8;
import vibe.core.path : Path;
import vibe.data.json : deserializeJson, parseJsonString, serializeToPrettyJson;
import vibe.data.serialization : serializationName = name;

enum EventType
{
    Holiday,
    Birthday,
    FSI_Event,
    General_University_Event,
    Any
}

struct Entry
{
    @serializationName("date") Date begin;
    @serializationName("end_date") Nullable!Date end;
    Event event;
}

struct Event
{
    @serializationName("eid") string id;
    string name;
    @serializationName("desc") string[] description;
    @serializationName("etype") EventType type;
    bool shout;
}

Entry[] getEntriesFromFile(in Path fileName)
{
    Entry[] entries;
    if (fileName.existsFile)
    {
        deserializeJson(entries, fileName.readFileUTF8.parseJsonString);
    }
    return entries;
}

void writeEntriesToFile(in Entry[] entries, in Path fileName)
{
    fileName.writeFileUTF8(entries.serializeToPrettyJson);
}
