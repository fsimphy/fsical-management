module fsicalmanagement.data.authentication_info;

import fsicalmanagement.model.user : Privilege;

struct AuthenticationInfo
{
    string id;
    string username;
    Privilege privilege;

    mixin AuthMehtods;
}

private:
mixin template AuthMehtods()
{
private:
    import std.conv : to;
    import std.format : format;
    import std.traits : EnumMembers;

public:
    static foreach (member; EnumMembers!Privilege)
    {
        mixin(q{
            bool is%1$s() const pure @safe nothrow
            {
                return privilege == Privilege.%1$s;
            }
        }.format(member.to!string));
    }
}
