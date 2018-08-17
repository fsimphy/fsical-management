module test.fsicalmanagement.utility.initialization_test;

import fsicalmanagement.utility.initialization;
import unit_threaded.should : shouldEqual;

@("initOnce initializes ints")
unittest
{
    // given
    int toBeInitialized;

    // when
    immutable result = initOnce!toBeInitialized(42);

    // then
    result.shouldEqual(42);
}

@("initOnce initializes ints only once")
unittest
{
    // given
    int toBeInitialized;

    // when
    initOnce!toBeInitialized(42);
    immutable result = initOnce!toBeInitialized(666);

    // then
    result.shouldEqual(42);
}

@("initOnce initializes strings")
unittest
{
    // given
    string toBeInitialized;

    // when
    immutable result = initOnce!toBeInitialized("foo");

    // then
    result.shouldEqual("foo");
}

@("initOnce initializes strings only once")
unittest
{
    // given
    string toBeInitialized;

    // when
    initOnce!toBeInitialized("foo");
    immutable result = initOnce!toBeInitialized("bar");

    // then
    result.shouldEqual("foo");
}

@("initOnce initializes structs")
unittest
{
    // given
    struct S
    {
        int toBeInitialized;
    }

    S toBeInitialized;

    // when
    immutable result = initOnce!toBeInitialized(S(42));

    // then
    result.shouldEqual(S(42));
}

@("initOnce initializes structs only once")
unittest
{
    // given
    struct S
    {
        int toBeInitialized;
    }

    S toBeInitialized;

    // when
    initOnce!toBeInitialized(S(42));
    immutable result = initOnce!toBeInitialized(S(666));

    // then
    result.shouldEqual(S(42));
}

@("initOnce initializes classes")
unittest
{
    // given
    class C
    {
        this(int toBeInitialized)
        {
            this.toBeInitialized = toBeInitialized;
        }

        int toBeInitialized;
    }

    C toBeInitialized;

    // when
    auto instance = new C(42);
    auto result = initOnce!toBeInitialized(instance);

    // then
    result.shouldEqual(instance);
}

@("initOnce initializes classes only once")
unittest
{
    // given
    class C
    {
        this(int toBeInitialized)
        {
            this.toBeInitialized = toBeInitialized;
        }

        int toBeInitialized;
    }

    C toBeInitialized;

    // when
    auto instance = new C(42);
    initOnce!toBeInitialized(instance);
    auto result = initOnce!toBeInitialized(new C(666));

    // then
    result.shouldEqual(instance);
}
