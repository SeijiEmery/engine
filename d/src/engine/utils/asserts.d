module engine.utils.asserts;
import std.format: format;
import core.exception: AssertError;

void assertEq (T,U)(T a, U b, lazy string msg = null, string file = __FILE__, size_t line = __LINE__) 
    if (__traits(compiles, a == b)) 
{
    if (a != b) {
        throw new AssertError(msg ?
            format("%s != %s: %s", a, b, msg) :
            format("%s != %s", a, b),
            file, line);
    }
}
