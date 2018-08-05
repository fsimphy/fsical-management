module fsicalmanagement.utility.serialization;

import std.typecons : Nullable;
import vibe.data.bson : Bson;

/**
 * Nothrow wrapper around `vibe.data.bson.desrializeBson`. Logs `Exception`s
 * thrown by `vibe.data.bson.desrializeBson` as errors.
 * Params:
 * src = The BSON to deserialize.
 *
 * Returns: `Nullable!T` containing the deserialized BSON or `null`, when
 *          `vibe.data.bson.desrializeBson` throws.
 */
Nullable!T deserializeBsonNothrow(T)(Bson src) @safe nothrow
{
    import std.traits : fullyQualifiedName;
    import std.typecons : nullable;
    import vibe.core.log : logError;
    import vibe.data.bson : deserializeBson;

    Nullable!T ret;
    try
    {
        ret = src.deserializeBson!T.nullable;
    }
    catch (Exception e)
    {
        (() @trusted{
            logError("Error while deserializing BSON %s to %s:\n%s", src,
                fullyQualifiedName!T, e);
        })();
    }
    return ret;
}
