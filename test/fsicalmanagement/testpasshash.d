module test.fsicalmanagement.testpasshash;

import fsicalmanagement.passhash;

import unit_threaded;

@("StubPasswordHasher")
@Values("", "test", "langesKompliziertesPasswort")
@safe unittest
{
    immutable hasher = new StubPasswordHasher;
    immutable testPassword = getValue!string;
    hasher.checkHash(testPassword, hasher.generateHash(testPassword)).shouldBeTrue;
}

@("SHA256PasswordHasher")
@Values("", "test", "langesKompliziertesPasswort")
@safe unittest
{
    immutable hasher = new SHA256PasswordHasher;
    immutable testPassword = getValue!string;
    hasher.checkHash(testPassword, hasher.generateHash(testPassword)).shouldBeTrue;
}