module test.fsicalmanagement.facade.authentication_facade_test;

import fsicalmanagement.business.authentication_service;
import fsicalmanagement.data.authentication_info : AuthenticationInfo;
import fsicalmanagement.facade.authentication_facade : AuthenticationFacade;
import fsicalmanagement.model.user : Privilege;

import std.typecons : Nullable, nullable;

import unit_threaded.mock : mock;
import unit_threaded.should : shouldEqual, shouldThrow;

@("AuthenticationFacade.authenticate sucessfull")
unittest
{
    // given
    immutable username = "someUsername";
    immutable password = "somePassword";
    immutable authInfo = AuthenticationInfo("42", username, Privilege.User).nullable;
    auto authenticationServiceMock = mock!AuthenticationService;
    authenticationServiceMock.returnValue!"authenticate"(authInfo);
    auto underTest = new AuthenticationFacade(authenticationServiceMock);

    // when
    immutable resultingAuthInfo = underTest.authenticate(username, password);

    // then
    resultingAuthInfo.shouldEqual(authInfo);
}

@("AuthenticationFacade.authenticate failure")
unittest
{
    // given
    immutable username = "someUsername";
    immutable password = "somePassword";
    auto authenticationServiceMock = mock!AuthenticationService;
    authenticationServiceMock.returnValue!"authenticate"(Nullable!AuthenticationInfo.init);
    auto underTest = new AuthenticationFacade(authenticationServiceMock);

    // when
    immutable authenticationCall = { underTest.authenticate(username, password); };

    // then
    authenticationCall().shouldThrow!Exception;
}
