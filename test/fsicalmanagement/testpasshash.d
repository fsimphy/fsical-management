module test.fsicalmanagement.testpasshash;

import unit_threaded : getValue, Values;
import unit_threaded.should : shouldBeTrue;

@("StubPasswordHasher")
@Values("", "test", "langesKompliziertesPasswort")
@safe unittest
{
    import fsicalmanagement.passhash : StubPasswordHasher;

    immutable hasher = new StubPasswordHasher;
    immutable testPassword = getValue!string;
    hasher.checkHash(testPassword, hasher.generateHash(testPassword)).shouldBeTrue;
}

@("SHA256PasswordHasher")
@Values("", "test", "langesKompliziertesPasswort")
@safe unittest
{
    import fsicalmanagement.passhash : SHA256PasswordHasher;

    immutable hasher = new SHA256PasswordHasher;
    immutable testPassword = getValue!string;
    hasher.checkHash(testPassword, hasher.generateHash(testPassword)).shouldBeTrue;
}
