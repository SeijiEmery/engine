import std.stdio: writefln;
//import entitysysd;

//mixin generate_systemic!(
//    q{  Rotator r, DeltaTime dt -> RotationAngle angle },
//    q{  angle += r.speed * dt   });

//mixin generate_systemic!(q{
//    Rotator r, DeltaTime dt -> RotationAngle angle {
//        angle += r.speed * dt;
//    }
//});

//mixin generate_systemic!(
//    systemic_typelist!(
//        systemic_typedecl!("Rotator", "r", SystemicParam.In),
//        systemic_typedecl!("DeltaTime", "dt", SystemicParam.In),
//        systemic_typedecl!("RotationAngle", "angle", SystemicParam.Out),
//    ), "
//        angle += r.speed * dt;
//    "
//);

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



//template eparams (Typedecls...)
//{
//    static if (Typedecls.length == 0)
//        enum eparams = "";
//    static if (Typedecls.length == 1)
//        enum eparams = Typedecls[0].var;
//    else static if (Typedecls.length == 2)
//        enum eparams = Typedecls[0].var ~ Typedecls[1].var;
//    else
//        alias eparams = eparams!(
//            systemic_typedecl!(
//                Typedecls[0].var ~ Typedecls[1].var, "", SystemicParam.In
//            ), Typedecls[2..$]);
//}

//mixin template generate_systemic (alias typedecl, alias body) {
//    shared static this () {
//        class Sys : System {
//            override void run (EntityManager entities, EventManager events, Duration dt) {
//                mixin("foreach (entity" ~ eparams!(typedecl) ~ "; entities.entitiesWith!(" ~ eparams!typedecl ~ ")) { " ~ body ~ " }");
//            }
//        }
//    }
//}
void main () {
    alias stuff = systemic_typelist!(
        systemic_typedecl!("Rotator", "r", SystemicParam.In),
        systemic_typedecl!("DeltaTime", "dt", SystemicParam.In),
        systemic_typedecl!("RotationAngle", "angle", SystemicParam.Out),
    );
    enum result = eparams!(stuff.args);
    enum tres = tparams!(stuff.args);
    writefln("%s :: %s", result, tres);
}
