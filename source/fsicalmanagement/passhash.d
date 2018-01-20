module fsicalmanagement.passhash;

interface PasswordHasher
{
    string generateHash(in string password) const @safe;
    bool checkHash(in string password, in string hash) const @safe;
}

class StubPasswordHasher : PasswordHasher
{
    string generateHash(in string password) const @safe pure nothrow
    {
        return password;
    }

    bool checkHash(in string password, in string hash) const @safe pure nothrow
    {
        return password == hash;
    }
}

class SHA256PasswordHasher : PasswordHasher
{
    import dauth : dupPassword, isSameHash, makeHash, parseHash;
    import std.digest.sha : SHA256;

    string generateHash(in string password) const @safe
    {
        return (() @trusted => password.dupPassword.makeHash!SHA256.toCryptString)();
    }

    bool checkHash(in string password, in string hash) const @safe
    {
        return (() @trusted => isSameHash(password.dupPassword, parseHash(hash)))();
    }
}
