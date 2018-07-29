module fsicalmanagement.model.user;

struct User
{
    import vibe.data.serialization : name;

    @name("_id") string id;
    string username;
    string passwordHash;
    Privilege privilege;

    this(string username, string passwordHash, Privilege privilege) @safe @nogc pure nothrow
    {
        this.username = username;
        this.passwordHash = passwordHash;
        this.privilege = privilege;
    }
}

enum Privilege
{
    None,
    User,
    Admin
}
