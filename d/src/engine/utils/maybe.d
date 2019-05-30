module engine.utils.maybe;

struct Maybe (T) {
    import std.variant;
    private alias MaybeVariant = Algebraic!T;
    private MaybeVariant value;
    alias value this;

    this (T value) { this.value = value; }

    bool isSome () { return this.value.hasValue; }
    bool isNone () { return !this.value.hasValue; }
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
    auto ref setDefault (T defaultValue) {
        if (isNone) { value = defaultValue; }
        return this;
    }
    T withDefault (T defaultValue) {
        if (isSome) return *value.peek!T;
        return defaultValue;
    }
}