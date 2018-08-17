module test.fsicalmanagement.business.authentication_service_test;

import fsicalmanagement.business.authentication_service : AuthenticationService;
import fsicalmanagement.business.password_hashing_service : StubPasswordHashingService;
import fsicalmanagement.data.authentication_info : AuthenticationInfo;
import fsicalmanagement.dataaccess.user_repository : UserRepository;
import fsicalmanagement.model.user : Privilege, User;
import std.typecons : Nullable, nullable;
import unit_threaded.mock : mock;
import unit_threaded.should : shouldEqual, shouldBeFalse, shouldBeTrue;

@("AuthenticationService.authenticate with existing user and correct password")
unittest
{
    // given
    immutable username = "someUser";
    immutable passwordHash = "somePassword";
    auto password = passwordHash.dup;
    immutable userId = "42";
    immutable privilege = Privilege.User;

    auto userRepositoryMock = mock!UserRepository;
    auto user = User(userId, username, passwordHash, privilege).nullable;
    userRepositoryMock.returnValue!"findByUsername"(user);

    auto underTest = new AuthenticationService(userRepositoryMock, new StubPasswordHashingService());

    // when
    immutable authInfo = underTest.authenticate(username, password);

    // then
    authInfo.isNull.shouldBeFalse;
    authInfo.get.shouldEqual(AuthenticationInfo(userId, username, privilege));
}

@("AuthenticationService.authenticate with non existing user")
unittest
{
    // given
    immutable username = "someUser";
    auto password = "somePassword".dup;

    auto userRepositoryMock = mock!UserRepository;
    userRepositoryMock.returnValue!"findByUsername"(Nullable!User.init);

    auto underTest = new AuthenticationService(userRepositoryMock, new StubPasswordHashingService());

    // when
    immutable authInfo = underTest.authenticate(username, password);

    // then
    authInfo.isNull.shouldBeTrue;
}

@("AuthenticationService.authenticate with existing user and wrong password")
unittest
{
    // given
    immutable username = "someUser";
    immutable correctPasswordHash = "somePassword";
    auto wrongPassword = "wrongPassword".dup;
    immutable privilege = Privilege.User;

    auto userRepositoryMock = mock!UserRepository;
    auto user = User(username, correctPasswordHash, privilege).nullable;
    userRepositoryMock.returnValue!"findByUsername"(user);

    auto underTest = new AuthenticationService(userRepositoryMock, new StubPasswordHashingService());

    // when
    immutable authInfo = underTest.authenticate(username, wrongPassword);

    // then
    authInfo.isNull.shouldBeTrue;
}
