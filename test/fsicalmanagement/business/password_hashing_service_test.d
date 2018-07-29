module test.fsicalmanagement.business.password_hashing_service_test;

import unit_threaded.attrs : getValue, Values;
import unit_threaded.should : shouldBeTrue;

@("StubPasswordHashingService")
@Values("", "test", "longComplicatedPassword")
@safe unittest
{
    import fsicalmanagement.business.password_hashing_service : StubPasswordHashingService;

    // given
    immutable underTest = new StubPasswordHashingService;
    immutable testPassword = getValue!string;

    // when
    immutable isPasswordCorrect = underTest.checkHash(testPassword,
            underTest.generateHash(testPassword));

    // then
    isPasswordCorrect.shouldBeTrue;
}

@("SHA256PasswordHashingService")
@Values("", "test", "longComplicatedPassword")
@safe unittest
{
    import fsicalmanagement.business.password_hashing_service : SHA256PasswordHashingService;

    // given
    immutable underTest = new SHA256PasswordHashingService;
    immutable testPassword = getValue!string;

    // when
    immutable isPasswordCorrect = underTest.checkHash(testPassword,
            underTest.generateHash(testPassword));

    // then
    isPasswordCorrect.shouldBeTrue;
}
