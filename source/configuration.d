module configuration;

import poodinis : ValueInjector;

class StringInjector : ValueInjector!string
{
private:
    string[string] config;

public:
    this()
    {
        // dfmt off
        config = ["Database name" :           "CalendarWebapp",
                  "Users collection name":    "users",
                  "Entries collection name" : "entries"];
        // dfmt on
    }

    string get(string key)
    {
        return config[key];
    }
}
