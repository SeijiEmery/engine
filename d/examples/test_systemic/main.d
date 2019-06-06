import std.stdio: writefln;
import std.algorithm;
import std.typecons;
import std.string: strip;
import systemic;
import pegged.grammar;

mixin(grammar(`
Systemic:
    SystemDefn < TypeDecls "=>"
    TypeDecls  < TypeDecl ("," TypeDecl)*
    TypeDecl   < Qualifier Type Variable
    Qualifier  < "inout" / "in" / "out"
    Type       < identifier
    Variable   < identifier
`));

SystemicResourceType systemicTypeOfType (T)() {
    static if (hasUDA!(T, component)) return SystemicResourceType.Component;
    else static if (hasUDA!(T, singleton)) return SystemicResourceType.Singleton;
    else enforce(false, format("type %s does not have component or singleton annotations!", T.stringof));
}

alias PartialSystemicParams = Tuple!(string, string, SystemicQualifier)[];

auto parseSystemic (string input) {
    void parseDecl (ParseTree p, ref PartialSystemicParams params) {
        switch (p.name) {
            case "Systemic.TypeDecls": foreach (child; p.children) parseDecl(child, params); break;
            case "Systemic.TypeDecl": {
                SystemicQualifier qualifier = SystemicQualifier.In;
                string type, variable;
                foreach (item; p.children) {
                    switch (item.name) {
                        case "Systemic.Qualifier": switch (item.matches[0]) {
                            case "inout": qualifier = SystemicQualifier.InOut; break;
                            case "in": qualifier = SystemicQualifier.In; break;
                            case "out": qualifier = SystemicQualifier.Out; break;
                            default: writefln("Invalid qualifier '%s': %s!", item.matches[0], item.matches);
                        } break;
                        case "Systemic.Type": type = item.matches[0]; break;
                        case "Systemic.Variable": variable = item.matches[0]; break;
                        default: writefln("invalid parse node in %s: '%s': %s", p.name, item.name, item);
                    }
                }
                params ~= tuple(type, variable, qualifier);
            } break;
            default: writefln("invalid parse node '%s': %s!", p.name, p);
        }
    }
    PartialSystemicParams parse (ParseTree p) {
        switch(p.name) {
            case "Systemic": return parse(p.children[0]);
            case "Systemic.SystemDefn": {
                foreach (defn; p.children) {
                    PartialSystemicParams params;
                    parseDecl(defn, params);
                    return params;
                } 
            } break;
            default: {
                writefln("invalid parse node '%s': %s!", p.name, p);
            }
        }
        assert(0);
    }
    //enforce(input.hasBalancedParentheses('{', '}'), format("unbalanced '{', '}': `%s`", input));
    auto results = input.findSplit("=>");
    auto typedecl = results[0] ~ results[1];
    auto tbody = results[2].strip;
    auto ast = Systemic(typedecl);
    return tuple(parse(ast), tbody);
}


public @component struct Rotator { float speed; }
public @singleton struct DeltaTime { float dt; alias dt this; }
public @component struct RotationAngle { float angle; alias angle this; }

void run_tests (SystemicParams stuff)() {
    //enum tsig = systemic_typesig(stuff);
    //enum tbody = systemic_body_impl(stuff, q{rot.angle += r.speed * dt;});
    //writefln("%s", tsig);
    //writefln("%s", tbody);
    auto systemFunction = mixin(makeSystemicFunction!(stuff, q{rot.angle += r.speed * dt;}));

    auto ecs = new EntitySysD;
    auto entity = ecs.entities.create();
    entity.register!Rotator(1.0);
    entity.register!RotationAngle(0.0);
    SystemsGlobalResourceManager resources;
    resources.create!DeltaTime(1.0 / 33.4);

    writefln("%s, %s", entity.component!RotationAngle.angle, resources.get!DeltaTime);
    systemFunction(ecs.entities, resources);
    writefln("%s, %s", entity.component!RotationAngle.angle, resources.get!DeltaTime);
}

mixin createSystemic!([
        tuple("Rotator", "r", SystemicQualifier.In, SystemicResourceType.Component),
        tuple("DeltaTime", "dt", SystemicQualifier.In, SystemicResourceType.Singleton),
        tuple("RotationAngle", "rot", SystemicQualifier.InOut, SystemicResourceType.Component),
    ], q{rot.angle += r.speed * dt;});


void main () {
    writefln("%s", parseSystemic(q{
        in Rotator r, in DeltaTime dt, inout RotationAngle rot 
            => rot.angle += r.speed * dt
    }));

    visitSystems!((string name, SystemicFunction fcn) {
        writefln("  %s", name);
    });
    writefln("testing...");
    run_tests!([
        tuple("Rotator", "r", SystemicQualifier.In, SystemicResourceType.Component),
        tuple("DeltaTime", "dt", SystemicQualifier.In, SystemicResourceType.Singleton),
        tuple("RotationAngle", "rot", SystemicQualifier.InOut, SystemicResourceType.Component),
    ]);
}
