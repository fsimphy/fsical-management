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
    auto testPassword = getValue!string.dup;

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

    /* we need two seperate variables, because dauth will zero them when the
       corresponding `Password`s go out of scope */
    auto hashGeneratorPassword = getValue!string.dup;
    auto hashCheckerPassword = getValue!string.dup;

    // when
    immutable isPasswordCorrect = underTest.checkHash(hashCheckerPassword,
            underTest.generateHash(hashGeneratorPassword));

    // then
    isPasswordCorrect.shouldBeTrue;
}
