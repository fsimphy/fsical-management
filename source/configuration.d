module configuration;

import poodinis : ValueInjector;

class StringInjector : ValueInjector!string
{
private:
    string[string] config;

public:
    this() const @safe pure nothrow
    {
        // dfmt off
        config = ["Database name" :           "CalendarWebapp",
                  "Users collection name":    "users",
                  "Entries collection name" : "entries"];
        // dfmt on
    }

    string get(string key) const @safe pure nothrow
    {
        return config[key];
    }
}
