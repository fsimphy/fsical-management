module test.fsicalmanagement.business.password_hashing_service_test;

import unit_threaded : getValue, Values;
import unit_threaded.should : shouldBeTrue;

@("StubPasswordHashingService")
@Values("", "test", "longComplicatedPassword")
@safe unittest
{
    import fsicalmanagement.business.password_hashing_service : StubPasswordHashingService;

    immutable underTest = new StubPasswordHashingService;
    immutable testPassword = getValue!string;
    underTest.checkHash(testPassword, underTest.generateHash(testPassword)).shouldBeTrue;
}

@("SHA256PasswordHashingService")
@Values("", "test", "longComplicatedPassword")
@safe unittest
{
    import fsicalmanagement.business.password_hashing_service : SHA256PasswordHashingService;

    immutable underTest = new SHA256PasswordHashingService;
    immutable testPassword = getValue!string;
    underTest.checkHash(testPassword, underTest.generateHash(testPassword)).shouldBeTrue;
}
