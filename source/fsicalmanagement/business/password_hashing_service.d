module fsicalmanagement.business.password_hashing_service;

interface PasswordHashingService
{
    string generateHash(const string password) const @safe;
    bool checkHash(const string password, const string hash) const @safe;
}

class StubPasswordHashingService : PasswordHashingService
{
    string generateHash(const string password) const @safe pure nothrow
    {
        return password;
    }

    bool checkHash(const string password, const string hash) const @safe pure nothrow
    {
        return password == hash;
    }
}

class SHA256PasswordHashingService : PasswordHashingService
{
    import dauth : dupPassword, isSameHash, makeHash, parseHash;
    import std.digest.sha : SHA256;

    string generateHash(const string password) const @safe
    {
        return (() @trusted => password.dupPassword.makeHash!SHA256.toCryptString)();
    }

    bool checkHash(const string password, const string hash) const @safe
    {
        return (() @trusted => isSameHash(password.dupPassword, parseHash(hash)))();
    }
}
