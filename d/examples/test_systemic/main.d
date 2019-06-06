import std.stdio: writefln;
import std.algorithm;
import std.typecons;
import systemic;

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
        tuple("Rotator", "r", SystemicParam.In, SystemicResourceType.Component),
        tuple("DeltaTime", "dt", SystemicParam.In, SystemicResourceType.Singleton),
        tuple("RotationAngle", "rot", SystemicParam.InOut, SystemicResourceType.Component),
    ], q{rot.angle += r.speed * dt;});


void main () {
    visitSystems!((string name, SystemicFunction fcn) {
        writefln("  %s", name);
    });
    writefln("testing...");
    run_tests!([
        tuple("Rotator", "r", SystemicParam.In, SystemicResourceType.Component),
        tuple("DeltaTime", "dt", SystemicParam.In, SystemicResourceType.Singleton),
        tuple("RotationAngle", "rot", SystemicParam.InOut, SystemicResourceType.Component),
    ]);
}
