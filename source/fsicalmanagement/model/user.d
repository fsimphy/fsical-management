module fsicalmanagement.model.user;

/**
 * Represents a user.
 */
struct User
{
    import vibe.data.serialization : name;
    
    ///
    @name("_id") string id;
    ///
    string username;
    ///
    string passwordHash;
    ///
    Privilege privilege;

    ///
    this(const string username, const string passwordHash, const Privilege privilege) @safe @nogc pure nothrow
    {
        this.username = username;
        this.passwordHash = passwordHash;
        this.privilege = privilege;
    }

    ///
    this(const string id, const string username, const string passwordHash, const Privilege privilege) @safe @nogc pure nothrow
    {
        this.id = id;
        this.username = username;
        this.passwordHash = passwordHash;
        this.privilege = privilege;
    }
}

/**
 * Represents the privilege of a user.
 */
enum Privilege
{
    None,
    User,
    Admin
}
