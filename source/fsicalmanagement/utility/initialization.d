module fsicalmanagement.utility.initialization;

/**
 * Initializes $(D_PARAM var) with the lazy $(D_PARAM init) value. Works
 * basically the same as `std.concurrency.initOnce`, but does not ensure thread
 * safety. If thread safety is needed, use `std.concurrency.initOnce` instead.
 * Params:
 * init = The expression to use for initializing $(D_PARAM var).
 *
 * Returns: The initialized $(D_PARAM var).
 */
auto ref initOnce(alias var)(lazy typeof(var) init)
{
    static bool flag;
    if (!flag)
    {
        var = init;
        flag = true;
    }
    return var;
}
