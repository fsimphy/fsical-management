module test.fsicalmanagement.data.authentication_info_test;

import fsicalmanagement.data.authentication_info;
import fsicalmanagement.model.user : Privilege;
import unit_threaded.attrs : getValue, Values;
import unit_threaded.should : shouldEqual;

// TODO: Automatically generate these tests for all enum members of `Privilege`

@("AuthenticationInfo.isNone success")
unittest
{
    // given
    AuthenticationInfo authInfo;
    authInfo.privilege = Privilege.None;

    // when
    immutable isAuthenticatedAsNone = authInfo.isNone;

    // then
    isAuthenticatedAsNone.shouldEqual(true);
}

@("AuthenticationInfo.isNone failure")
@Values(Privilege.User, Privilege.Admin)
unittest
{
    // given
    AuthenticationInfo authInfo;
    authInfo.privilege = getValue!Privilege;

    // when
    immutable isAuthenticatedAsNone = authInfo.isNone;

    // then
    isAuthenticatedAsNone.shouldEqual(false);
}

@("AuthenticationInfo.isUser success")
unittest
{
    // given
    AuthenticationInfo authInfo;
    authInfo.privilege = Privilege.User;

    // when
    immutable isAuthenticatedAsUser = authInfo.isUser;

    // then
    isAuthenticatedAsUser.shouldEqual(true);
}

@("AuthenticationInfo.isUser failure")
@Values(Privilege.None, Privilege.Admin)
unittest
{
    // given
    AuthenticationInfo authInfo;
    authInfo.privilege = getValue!Privilege;

    // when
    immutable isAuthenticatedAsUser = authInfo.isUser;

    // then
    isAuthenticatedAsUser.shouldEqual(false);
}

@("AuthenticationInfo.isAdmin success")
unittest
{
    // given
    AuthenticationInfo authInfo;
    authInfo.privilege = Privilege.Admin;

    // when
    immutable isAuthenticatedAsAdmin = authInfo.isAdmin;

    // then
    isAuthenticatedAsAdmin.shouldEqual(true);
}

@("AuthenticationInfo.isNone failure")
@Values(Privilege.User, Privilege.None)
unittest
{
    // given
    AuthenticationInfo authInfo;
    authInfo.privilege = getValue!Privilege;

    // when
    immutable isAuthenticatedAsAdmin = authInfo.isAdmin;

    // then
    isAuthenticatedAsAdmin.shouldEqual(false);
}
