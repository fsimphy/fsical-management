module test.calendarwebapp.testpasshash;

import calendarwebapp.passhash;

import poodinis;

import unit_threaded;

@("BcryptPasswordHasher")
@Values("", "test", "langesKompliziertesPasswort")
@system unittest
{
    import botan.rng.rng : RandomNumberGenerator;
    import botan.rng.auto_rng : AutoSeededRNG;
    auto container = new shared DependencyContainer;
    container.register!(RandomNumberGenerator, AutoSeededRNG);
    container.register!(PasswordHasher, BcryptPasswordHasher);

    auto hasher = container.resolve!PasswordHasher;
    immutable testPassword = getValue!string;
    hasher.checkHash(testPassword, hasher.generateHash(testPassword)).shouldBeTrue;
}

@("StubPasswordHasher")
@Values("", "test", "langesKompliziertesPasswort")
@safe unittest
{
    immutable hasher = new StubPasswordHasher;
    immutable testPassword = getValue!string;
    hasher.checkHash(testPassword, hasher.generateHash(testPassword)).shouldBeTrue;
}
