module test.fsicalmanagement.facade.user_facade_test;

import fsicalmanagement.business.password_hashing_service : StubPasswordHashingService;
import fsicalmanagement.dataaccess.user_repository : UserRepository;
import fsicalmanagement.facade.user_facade : UserFacade;
import fsicalmanagement.model.user : User, Privilege;
import std.range.interfaces : inputRangeObject;
import unit_threaded.attrs : getValue, Values;
import unit_threaded.mock : mock;
import unit_threaded.should : shouldBeSameSetAs, shouldEqual, shouldThrow;

@("UserFacade.getAllUsers")
unittest
{
        // given
        auto userRepositoryMock = mock!UserRepository;
        auto user1 = User("5a9c2cbd52e14fca100e76cd", "someName", "someHash", Privilege.Admin);
        auto user2 = User("5a9c39a11b7add86399c1d36", "someOtherName",
                        "someOtherHash", Privilege.User);

        userRepositoryMock.returnValue!"findAll"([user1, user2].inputRangeObject);
        auto underTest = new UserFacade(userRepositoryMock, new StubPasswordHashingService);

        // when
        auto allUsers = underTest.getAllUsers();

        // then
        allUsers.shouldBeSameSetAs([user1, user2]);
}

@("UserFacade.createUser")
unittest
{
        // given
        auto userRepositoryMock = mock!UserRepository;
        immutable generatedUserId = "5a9c2cbd52e14fca100e76cd";
        immutable userId = "";
        immutable username = "someName";
        immutable password = "somePassword";
        immutable privilege = Privilege.User;

        auto callingUser = User(userId, username, password, privilege);
        auto resultingUser = User(generatedUserId, username, password, privilege);

        userRepositoryMock.returnValue!"save"(resultingUser);
        auto underTest = new UserFacade(userRepositoryMock, new StubPasswordHashingService);

        // when
        immutable user = underTest.createUser(username, password, privilege);

        // then
        user.shouldEqual(resultingUser);
        userRepositoryMock.expectCalled!"save"(callingUser);
}

@("UserFacade.removeUserById")
@Values("5a9c2cbd52e14fca100e76cd", "5a9c39a11b7add86399c1d36", "5a9c3a1f1b7add86399c1d37")
unittest
{
        import std.array : replace;

        // given
        auto userRepositoryMock = mock!UserRepository;
        immutable userId = getValue!string;

        auto underTest = new UserFacade(userRepositoryMock, new StubPasswordHashingService);

        // when
        underTest.removeUserById(userId);

        // then
        userRepositoryMock.expectCalled!"deleteById"(userId);
}
