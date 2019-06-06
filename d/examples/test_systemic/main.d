import std.stdio: writefln;
import std.algorithm;
import std.typecons;
import std.string: strip;
import std.traits: hasUDA;
import std.format: format;
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
struct PartialSystemParam { string type; string variable; SystemicQualifier qualifier; }
alias PartialSystemicParams = PartialSystemParam[];
//alias PartialSystemicParams = Tuple!(string, string, SystemicQualifier)[];

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
                params ~= PartialSystemParam(type, variable, qualifier);
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

SystemicResourceType getResourceType (string type)() {
    mixin(`alias T = `~type~`;`~q{
        static if (hasUDA!(T, component)) return SystemicResourceType.Component;
        static if (hasUDA!(T, singleton)) return SystemicResourceType.Singleton;
        assert(false, format("invalid type '%s'", T.stringof));     
    });
}
SystemicParams lookupSystemicParams (PartialSystemicParams params)() {
    SystemicParams result;
    static if (params.length == 0) return [];
    else return tuple(params[0].type, params[0].variable, params[0].qualifier, getResourceType!(params[0].type))
        ~ lookupSystemicParams!(params[1..$]);
    //foreach (param; params) {
    //    auto resourceType = getResourceType!(param.type);
    //    //result ~= tuple(param[0], param[1], param[2], getResourceType!(param[0]));
    //}
    //return result;
}

string registerSystemic (string input)() {
    enum args = parseSystemic(input);
    enum params = lookupSystemicParams!(args[0]);
    return createSystemic!(params, args[1]);
}
string generateSystemic (string input)() {
    return "shared static this () {\n\t"~registerSystemic!input~"\n}";
}

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

//mixin createSystemic!([
//        tuple("Rotator", "r", SystemicQualifier.In, SystemicResourceType.Component),
//        tuple("DeltaTime", "dt", SystemicQualifier.In, SystemicResourceType.Singleton),
//        tuple("RotationAngle", "rot", SystemicQualifier.InOut, SystemicResourceType.Component),
//    ], q{rot.angle += r.speed * dt;});

//mixin(generateSystemic!(q{
//    in Rotator r, in DeltaTime dt, inout RotationAngle rot 
//        => rot.angle += r.speed * dt
//}));

string decs (string stuff)() { return ""; }
mixin(decs!q{
    resource DeltaTime = float
    component Rotator { float speed = 1.0; } requires(RotationAngle)
    component RotationAngle = float

    update RotationAngle angle, Rotator r, DeltaTime dt {
        angle += r.speed * dt;
    }

    component Position = vec2  defaults { vec2(0.0, 0.0) }
    component Scale    = vec2  defaults { vec2(1.0, 1.0) }
    component Depth    = float defaults { 0.0 }

    component LocalTransform = mat4 
        requires(Position, Scale, Depth, RotationAngle)
        defaults { mat4.identity }
    
    component WorldTransform = mat4
        requires(LocalTransform)
        defaults { mat4.identity }

    update LocalTransform matrix, Position pos, RotationAngle rot, Scale scale {
        matrix = mat4(
            // ...
        );
    }
    update LocalTransform localTransform, WorldTransform worldTransform {
        worldTransform = localTransform;
    }

    resource Renderer = IRenderer
    component ShapeRenderer { vec4 color } requires Shape

    update Renderer renderer, WorldTransform transform, Shape shape, ShapeRenderer shapeRenderer {
        renderer.drawShape(transform, shape, shapeRenderer.color);
    }
});

void main () {
    writefln("%s", generateSystemic!(q{
        in Rotator r, in DeltaTime dt, inout RotationAngle rot 
        => rot.angle += r.speed * dt
    }));


    writefln("%s", parseSystemic(q{
        in Rotator r, in DeltaTime dt, inout RotationAngle rot 
            => rot.angle += r.speed * dt
    }));

    visitSystems!((string name, SystemicFunction fcn) {
        writefln("  %s", name);
    });
    writefln("testing...");
    //run_tests!([
    //    tuple("Rotator", "r", SystemicQualifier.In, SystemicResourceType.Component),
    //    tuple("DeltaTime", "dt", SystemicQualifier.In, SystemicResourceType.Singleton),
    //    tuple("RotationAngle", "rot", SystemicQualifier.InOut, SystemicResourceType.Component),
    //]);

    auto ecs = new EntitySysD;
    auto entity = ecs.entities.create();
    entity.register!Rotator(1.0);
    entity.register!RotationAngle(0.0);
    SystemsGlobalResourceManager resources;
    resources.create!DeltaTime(1.0 / 33.4);
    writefln("%s", registerSystemic!q{
        in Rotator r, in DeltaTime dt, inout RotationAngle rot 
            => rot.angle += r.speed * dt
    });
    mixin(registerSystemic!(q{
        in Rotator r, in DeltaTime dt, inout RotationAngle rot 
            => rot.angle += r.speed * dt
    }));
    writefln("%s, %s", entity.component!RotationAngle.angle, resources.get!DeltaTime);
    runSystems(ecs.entities, resources);
    writefln("%s, %s", entity.component!RotationAngle.angle, resources.get!DeltaTime);
}
