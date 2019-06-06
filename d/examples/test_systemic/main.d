import std.stdio: writefln;
import entitysysd;

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

mixin generate_systemic!(
    systemic_typelist!(
        systemic_typedecl!("Rotator", "r", SystemicParam.In),
        systemic_typedecl!("DeltaTime", "dt", SystemicParam.In),
        systemic_typedecl!("RotationAngle", "angle", SystemicParam.Out),
    ), "
        angle += r.speed * dt;
    "
);

enum SystemicParam { In, Out, InOut }
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
    else static if (Args.length == 1) return Args[0].var;
    else return eparams!(Args[0..1]) ~ ", " ~ eparams!(Args[1..$]);
}
string tparams (Args...)() {
    static if (Args.length == 0) return "";
    else static if (Args.length == 1) return Args[0].type;
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


mixin template generate_systemic (alias T, alias B) {
    shared static this () {
        class Sys : System {
            override void run (EntityManager entities, EventManager events, Duration dt) {
                //mixin("foreach (entity" ~ eparams!(T.args) ~ "; entities.entitiesWith!(" ~ tparams!(T.args) ~ ")) { " ~ B ~ " }");
            }
        }
        register_system!Sys(tparams!(T.args));
    }
}
shared static System[string] registered_systems;
void register_system (System)(string id) {
    writefln("registering '%s'", id);
    //register_system[id] = new System();
}

void main () {
    foreach (name, sys; registered_systems) {
        writefln("have system '%s': %p", name, cast(void*)sys);
    }
    alias stuff = systemic_typelist!(
        systemic_typedecl!("Rotator", "r", SystemicParam.In),
        systemic_typedecl!("DeltaTime", "dt", SystemicParam.In),
        systemic_typedecl!("RotationAngle", "angle", SystemicParam.InOut),
    );
    enum result = eparams!(stuff.args);
    enum tres = tsignature!(stuff.args);
    writefln("%s :: %s", result, tres);
}
