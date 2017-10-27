module calendarwebapp.passhash;

import poodinis;

interface PasswordHasher
{
    string generateHash(in string password) @safe;
    bool checkHash(in string password, in string hash) const @safe;
}

class BcryptPasswordHasher : PasswordHasher
{
    import botan.passhash.bcrypt : checkBcrypt, generateBcrypt;
    import botan.rng.rng : RandomNumberGenerator;

    string generateHash(in string password) @safe
    {
        return (() @trusted => generateBcrypt(password, rng, cost))();
    }

    bool checkHash(in string password, in string hash) const @safe
    {
        return (()@trusted => checkBcrypt(password, hash))();
    }

private:
    @Autowire RandomNumberGenerator rng;
    enum cost = 10;
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
