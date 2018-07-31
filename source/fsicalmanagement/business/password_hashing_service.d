module fsicalmanagement.business.password_hashing_service;

/**
 * Provides functionality to hash passwords and validate passwords against
 * hashes.
 */
interface PasswordHashingService
{
    /**
     * Generates a hash from a $(D_PARAM password).
     * Params:
     * password = The $(D_PARAM password) to hash.
     *
     * Returns: The generated hash.
     */
    string generateHash(const string password) const @safe;

    /**
     * Validates $(D_PARAM password) against a given $(D_PARAM hash).
     * Params:
     * password = The password to validate.
     * hash = The hash to validate against.
     *
     * Returns: Whether or not the validation was successful.
     */
    bool checkHash(const string password, const string hash) const @safe;
}

/**
 * A stub implementation of `PasswordHashingService` which does not actually do
 * any hashing.
 */
class StubPasswordHashingService : PasswordHashingService
{
    /**
     * Simply returns the given $(D_PARAM password).
     *
     * Params:
     * password = The $(D_PARAM password) to return.
     *
     * Returns: $(D_PARAM password).
     */
    string generateHash(const string password) const @safe pure nothrow
    {
        return password;
    }

    /**
     * Validates that $(D_PARAM password) is equal to $(D_PARAM hash).
     * Params:
     * password = The password to validate.
     * hash = The hash to validate against.
     *
     * Returns: Whether or not $(D_PARAM password) and $(D_PARAM hash) are
     *          equal.
     */
    bool checkHash(const string password, const string hash) const @safe pure nothrow
    {
        return password == hash;
    }
}

/**
 * A $(LINK2 https://github.com/Abscissa/DAuth, dauth) based implementation of
 * `PasswordHashingService` using SHA256 as hashing algorithm. Hashes are
 * provided in a $(LINK2 https://en.wikipedia.org/wiki/Crypt_%28C%29, crypt(3))
 * compatible form.
 */
class SHA256PasswordHashingService : PasswordHashingService
{
    import dauth : dupPassword, isSameHash, makeHash, parseHash;
    import std.digest.sha : SHA256;

    /**
     * Generates a salted SHA256 hash of a $(D_PARAM password).
     * Params:
     * password = The $(D_PARAM password) to hash.
     *
     * Returns: A salted SHA256 hash of $(D_PARAM password).
     */
    string generateHash(const string password) const @safe
    {
        return (() @trusted => password.dupPassword.makeHash!SHA256.toCryptString)();
    }

    /**
     * Validates $(D_PARAM password) against a salted SHA256 $(D_PARAM hash).
     * Params:
     * password = The password to validate.
     * hash = The hash to validate against.
     *
     * Returns: Whether or not the validation was successful.
     */
    bool checkHash(const string password, const string hash) const @safe
    {
        return (() @trusted => isSameHash(password.dupPassword, parseHash(hash)))();
    }
}
