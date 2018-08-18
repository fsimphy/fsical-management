module fsicalmanagement.data.authentication_info;

import fsicalmanagement.model.user : Privilege;

/**
 * Represents the authentication information of an authenticated user.
 */
struct AuthenticationInfo
{
    ///
    string id;
    ///
    string username;
    ///
    Privilege privilege;

    mixin AuthMethods;
}

private:

mixin template AuthMethods()
{
    import std.conv : convertTo = to; // This import is renamed in order to avoid a conflict with unit-threaded
    import std.format : format;
    import std.traits : EnumMembers;

    static foreach (member; EnumMembers!Privilege)
    {
        mixin(q{
            bool is%1$s() const @safe @nogc pure nothrow
            {
                return privilege == Privilege.%1$s;
            }
        }.format(member.convertTo!string));
    }
}
