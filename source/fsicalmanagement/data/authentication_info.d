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

    mixin(generateAuthMethods);

private:
    static string generateAuthMethods() @safe pure
    {
        import std.conv : to;
        import std.format : format;
        import std.traits : EnumMembers;

        string ret;
        foreach (member; EnumMembers!Privilege)
        {
            ret ~= q{
                bool is%s() const @safe pure nothrow
                {
                    return privilege == Privilege.%s;
                }
            }.format(member.to!string, member.to!string);
        }
        return ret;
    }
}
