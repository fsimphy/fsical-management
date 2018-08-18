module test.fsicalmanagement.utility.serialization_test;

import fsicalmanagement.utility.serialization;
import unit_threaded.should : shouldEqual;

import vibe.data.bson : Bson;

@("deserializeBsonNothrow int success")
unittest
{
    // given
    immutable bson = Bson(1);

    // when
    immutable result = bson.deserializeBsonNothrow!int;

    // then
    result.isNull.shouldEqual(false);
}

@("deserializeBsonNothrow int failure")
unittest
{
    // given
    immutable bson = Bson(false);

    // when
    immutable result = bson.deserializeBsonNothrow!string;

    // then
    result.isNull.shouldEqual(true);
}

@("deserializeBsonNothrow string success")
unittest
{
    // given
    immutable bson = Bson("test");

    // when
    immutable result = bson.deserializeBsonNothrow!string;

    // then
    result.isNull.shouldEqual(false);
}

@("deserializeBsonNothrow string failure")
unittest
{
    // given
    immutable bson = Bson(1);

    // when
    immutable result = bson.deserializeBsonNothrow!string;

    // then
    result.isNull.shouldEqual(true);
}

@("deserializeBsonNothrow struct success")
unittest
{
    // given
    static struct TestStruct
    {
        int id;
    }

    immutable bson = Bson(["id": Bson(0)]);

    // when
    immutable result = bson.deserializeBsonNothrow!TestStruct;

    // then
    result.isNull.shouldEqual(false);
}

@("deserializeBsonNothrow struct failure")
unittest
{
    // given
    static struct TestStruct
    {
        int id;
    }

    immutable bson = Bson(["foo": Bson("bar")]);

    // when
    immutable result = bson.deserializeBsonNothrow!TestStruct;

    // then
    result.isNull.shouldEqual(true);
}
