import std.stdio: writefln;
import entitysysd;
import std.algorithm;
import std.typecons;
import std.array: join;

//mixin generate_systemic!(
//    q{  Rotator r, DeltaTime dt -> RotationAngle angle },
//    q{  angle += r.speed * dt   });

//mixin generate_systemic!(q{
//    Rotator r, DeltaTime dt -> RotationAngle angle {
//        angle += r.speed * dt;
//    }
//});

@component struct Rotator { float speed; }
@component struct DeltaTime { float dt; }
@component struct RotationAngle { float angle; }

public enum SystemicParam { In, Out, InOut }
string systemic_typesig (Tuple!(string, string, SystemicParam)[] args) {
    auto a = args.filter!((Tuple!(string, string, SystemicParam) a) => a[2] != SystemicParam.Out).map!"a[0]".join(", ");
    auto b = args.filter!((Tuple!(string, string, SystemicParam) a) => a[2] != SystemicParam.In).map!"a[0]".join(", ");
    return a != "" ? b != "" ? a ~ " -> " ~ b : a : " -> " ~ b;
}
void run_tests (Tuple!(string, string, SystemicParam)[] stuff)() {
    enum tsig = systemic_typesig(stuff);
    writefln("%s", tsig);
}

mixin generate_systemic!(
    systemic_typelist!(
        systemic_typedecl!("Rotator", "r", SystemicParam.In),
        systemic_typedecl!("DeltaTime", "dt", SystemicParam.In),
        systemic_typedecl!("RotationAngle", "angle", SystemicParam.Out),
    ), "
        angle.angle += r.speed * dt.dt;
    "
);

struct systemic_typedecl (string tname, string vname, SystemicParam inp) {
    alias type  = tname;
    alias var   = vname;
    alias input = inp;
}
struct systemic_typelist (Args...) {
    alias args = Args;
}
string eparams (Args...)() {
    static if (Args.length == 0) return "";
    else static if (Args.length == 1) {
        return Args[0].var;
        //static if (Args[0].input == SystemicParam.In) return "const "~Args[0].var~"";
        //else return Args[0].var;
        //else return "ref "~Args[0].var;
    }
    else return eparams!(Args[0..1]) ~ ", " ~ eparams!(Args[1..$]);
}
string tparams (Args...)() {
    static if (Args.length == 0) return "";
    else static if (Args.length == 1) {
        return Args[0].type;
        //static if (Args[0].input == SystemicParam.In) return "const(" ~ Args[0].type ~ ")";
        //else return Args[0].type;
        //else return "ref "~Args[0].type;
    }
    else return tparams!(Args[0..1]) ~ ", " ~ tparams!(Args[1..$]);
}
string tparams_in (Args...)() {
    static if (Args.length == 0) return "";
    else static if (Args[0].input == SystemicParam.Out) return tparams_in!(Args[1..$]);
    else static if (Args.length == 1) return Args[0].type;
    else {
        auto a = Args[0].type;
        auto b = tparams_in!(Args[1 .. $]);
        return b != "" ? a ~ ", " ~ b : a;
    }
}
string tparams_out (Args...)() {
    static if (Args.length == 0) return "";
    else static if (Args[0].input == SystemicParam.In) return tparams_out!(Args[1..$]);
    else static if (Args.length == 1) return Args[0].type;
    else {
        auto a = Args[0].type;
        auto b = tparams_out!(Args[1 .. $]);
        return b != "" ? a ~ ", " ~ b : a;
    }
}
string tsignature (Args...)() {
    auto left = tparams_in!Args;
    auto right = tparams_out!Args;
    return left != "" ?
        (right != "" ? left ~ " -> " ~ right : left)
        //(right != "" ? right : "")
        : right;
}
string systemic_body (alias T, alias B)() {
    return "foreach (entity, " ~ eparams!(T.args) ~ "; entities.entitiesWith!(" ~ tparams!(T.args) ~ ")) { " ~ B ~ " }";
}
struct SystemsGlobalResourceManager {}
alias SystemFunction = void delegate (ref EntityManager, ref SystemsGlobalResourceManager);
shared static SystemFunction[string] g_registered_systems;

alias SystemBuilder = void delegate ();
shared static SystemBuilder[] g_system_builders;

mixin template generate_systemic (alias T, alias B) {
    shared static this () {
        void systemic_impl (ref EntityManager entities, ref SystemsGlobalResourceManager resources) {
            mixin(systemic_body!(T, B));
        }
        g_system_builders ~= delegate () {
            register_system!systemic_impl(tsignature!(T.args));
        };
    }
}
void register_system (alias systemic_function)(string id) {
    g_registered_systems[id] = &systemic_function;
}
void main () {
    //foreach (name, sys; g_registered_systems) {
    //    writefln("have system '%s': %p", name, cast(void*)sys);
    //}
    //alias stuff = systemic_typelist!(
    //    systemic_typedecl!("Rotator", "r", SystemicParam.In),
    //    systemic_typedecl!("DeltaTime", "dt", SystemicParam.In),
    //    systemic_typedecl!("RotationAngle", "angle", SystemicParam.InOut),
    //);
    //enum result = eparams!(stuff.args);
    //enum tres = tsignature!(stuff.args);
    //writefln("%s :: %s", result, tres);

    run_tests!([
        tuple("Rotator", "r", SystemicParam.In),
        tuple("DeltaTime", "dt", SystemicParam.In),
        tuple("RotationAngle", "angle", SystemicParam.InOut),
    ]);
}
