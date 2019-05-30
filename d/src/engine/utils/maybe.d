module engine.utils.maybe;

struct Maybe (T) {
    // use d's brilliant std.variant.Algebraic impl by andrei alexandrescu
    import std.variant: Algebraic;
    private Algebraic!T value;

    // implicit default ctor => Nothing
    // value ctor (T value)  => Just(value)
    static if (!(is(T == void))) {
        this (T value) { this.value = value; }
    }

    // check iff Some (Just) or None (Nothing)
    bool isSome () { return this.value.hasValue; }
    bool isNone () { return !this.value.hasValue; }

    // equivalent to haskell's fmap, rust's Option.map:
    // Just(x).map(f) => Just(f(x))
    // Nothing.map(f) => Nothing
    // note: map returns void iff f returns void
    auto map (F)(F f) {
        import std.traits: ReturnType;
        alias R = ReturnType!F;
        static if (is(R == void)) {
            if (isSome) { T x = *value.peek!T; f(x); }
        } else {
            if (isSome) { T x = *value.peek!T; return Maybe!R(f(x)); }
            return Maybe!R();
        }
    }

    // Non-safely get value directly (throws an exception if is None)
    static if (!(is(T == void))) {
        T unwrap () { return value.get!T; }
    }

    // Safely get value OR an optional default value
    static if (!(is(T == void))) {
        T withDefault (T defaultValue) {
            if (isSome) return *value.peek!T;
            return defaultValue;
        }
    }

    // none() equality is transitive across type boundaries
    // all other cases requires type and value equality
    bool opEquals (U)(Maybe!U other) {
        if (this.isNone && other.isNone) return true;
        static if (is(T == U)) {
            return this.isSome && other.isSome && this.unwrap == other.unwrap;
        } else {
            return false;
        }
    }
}
auto maybe (T)(T value) { return Maybe!T(value); }
auto maybe (T)() { return Maybe!T(); }
auto just (T)(T value) { return Maybe!T(value); }
auto nothing (T = void)() { return Maybe!T(); }


unittest {
    import std.format: format;
    import std.exception: assertThrown;
    import std.variant: VariantException;
    import std.conv: to;

    // Just(10), T == int
    assert(is(typeof(just(10)) == Maybe!int));
    assert(!just(10).isNone);
    assert(just(10).isSome);
    assert(is(typeof(just(10).unwrap()) == int));
    assert(just(10).unwrap == 10);

    // Nothing (but with T == int)
    assert(is(typeof(nothing!int()) == Maybe!int));
    assert(nothing!int().isNone);
    assert(!nothing!int().isSome);
    assert(is(typeof(nothing!int().unwrap()) == int));

    // calling unwrap() on a nothing value raises an exception
    assertThrown!VariantException(nothing!int().unwrap);

    // special case: this is a Maybe!void
    assert(is(typeof(nothing()) == Maybe!void));
    assert(nothing().isNone);
    assert(!nothing().isSome);

    // unwrap() is undefined on Maybe!void!
    assert(!__traits(compiles, nothing().unwrap));
    assert(__traits(compiles, just(10).unwrap));
    assert(__traits(compiles, nothing!int().unwrap));

    // test .map()
    auto x = 0, y = 0;
    //assert(is(typeof(just(10).map((v) { x = v; })) == void));
    //assert(is(typeof(just(10).map((v) => v)) == int));
    //assert(is(typeof(just(10).map((v) => v.to!string)) == string));

    // test running void functions with side effects
    assert(x == 0 && y == 0);
    just(10).map((int v) { x = v; });
    nothing!int().map((int v) { y = v; });
    assert(x == 10 && y == 0);

    // test running normal functions
    assert(just(10).map((int v) => v).withDefault(0) == 10);
    assert(just(10).map((int v) => v.to!string).withDefault("") == "10");
    assert(nothing!int.map((int v) => v).withDefault(0) == 0);
    assert(nothing!int.map((int v) => v.to!string).withDefault("") == "");

    // test equality
    assert(just(10) == just(10));
    assert(just(10) != just(12));
    assert(just(10) != nothing!int());
    assert(nothing!int() == nothing!int());
    assert(nothing!int() == nothing!string());
    assert(nothing!int() == nothing());
    assert(just(10) != just("10"));
}

