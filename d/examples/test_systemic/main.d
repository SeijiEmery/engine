import std.stdio: writefln;
import entitysysd;
import std.algorithm;
import std.typecons;
import std.array: join;
import std.format: format;

//mixin generate_systemic!(
//    q{  Rotator r, DeltaTime dt -> RotationAngle angle },
//    q{  angle += r.speed * dt   });

//mixin generate_systemic!(q{
//    Rotator r, DeltaTime dt -> RotationAngle angle {
//        angle += r.speed * dt;
//    }
//});
enum singleton;

@component struct Rotator { float speed; }
@singleton struct DeltaTime { float dt; alias dt this; }
@component struct RotationAngle { float angle; alias angle this; }

public enum SystemicParam { In, Out, InOut }
public enum SystemicResourceType { Component, Singleton }

alias SystemicParamTuple = Tuple!(string, string, SystemicParam, SystemicResourceType);
alias SystemicParams = SystemicParamTuple[];

string systemic_typesig (SystemicParams params) {
    auto a = params.filter!((SystemicParamTuple a) => a[2] != SystemicParam.Out).map!"a[0]".join(", ");
    auto b = params.filter!((SystemicParamTuple a) => a[2] != SystemicParam.In).map!"a[0]".join(", ");
    return a != "" ? b != "" ? a ~ " -> " ~ b : a : " -> " ~ b;
}
//string systemic_body_impl (SystemicParams params, string body) {
string systemic_body_impl (SystemicParams params, string bodyImpl) {
    auto resources = params.filter!((SystemicParamTuple a) => a[3] == SystemicResourceType.Singleton);
    auto components = params.filter!((SystemicParamTuple a) => a[3] == SystemicResourceType.Component);
    auto fetchResources = resources.map!(
        (SystemicParamTuple a) => a[2] == SystemicParam.In ?
            "auto "~a[1]~" = resources.get!"~a[0]~";\n" :
            "auto "~a[1]~" = resources.getMut!"~a[0]~";\n")
        .join("");

    auto componentVars  = components.map!((SystemicParamTuple a) => ", "~a[1]).join();
    auto componentTypes = components.map!((SystemicParamTuple a) => a[0]).join(", ");
    return fetchResources~"foreach (entity"~componentVars~"; entities.entitiesWith!("~componentTypes~")) {"~bodyImpl~"}";
}

// NOT THREADSAFE!! 
// (yet)
struct SystemsGlobalResourceManager {
    private void*[TypeInfo] _resources;

    void create (T, Args...)(Args args) {
        import std.experimental.allocator;
        TypeInfo key = typeid(T);
        if (key !in _resources) {
            _resources[key] = cast(void*)theAllocator.make!T(args);
        }
    }
    const(T) get (T)() if (is(T == struct)) {
        enforce(typeid(T) in _resources, format("resource %s was not created!", T.stringof));
        return *(cast(const(T)*)_resources[typeid(T)]);
    }
    T* getMut (T)() if (is(T == struct)) {
        enforce(typeid(T) in _resources, format("resource %s was not created!", T.stringof));
        return cast(T*)_resources[typeid(T)];
    }
}
alias SystemicFunction = void delegate (ref EntityManager, ref SystemsGlobalResourceManager);

SystemicFunction systemic (SystemicParams params, string bodyImpl)() {
    return delegate (ref EntityManager entities, ref SystemsGlobalResourceManager resources) {
        mixin(systemic_body_impl(params, bodyImpl));
    };
}

mixin template generate_systemic (SystemicParams params, string bodyImpl) {
    shared static this () {
        void systemic_impl (ref EntityManager entities, ref SystemsGlobalResourceManager resources) {
            mixin(systemic_body_impl(params, bodyImpl));
        }
        g_system_builders ~= delegate () {
            register_system!systemic_impl(systemic_typesig(params));
        };
    }
}
void register_system (alias systemic_function)(string id) {
    g_registered_systems[id] = &systemic_function;
}
void registerSystems () {
    foreach (builder; g_system_builders) {
        builder();
    }
}
alias SystemBuilder = void delegate ();
shared static SystemicFunction[string] g_registered_systems;
shared static SystemBuilder[] g_system_builders;

void run_tests (SystemicParams stuff)() {
    enum tsig = systemic_typesig(stuff);
    enum tbody = systemic_body_impl(stuff, q{rot.angle += r.speed * dt;});
    writefln("%s", tsig);
    writefln("%s", tbody);
    auto systemFunction = systemic!(stuff, q{rot.angle += r.speed * dt;});

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

mixin generate_systemic!([
        tuple("Rotator", "r", SystemicParam.In, SystemicResourceType.Component),
        tuple("DeltaTime", "dt", SystemicParam.In, SystemicResourceType.Singleton),
        tuple("RotationAngle", "rot", SystemicParam.InOut, SystemicResourceType.Component),
    ], q{rot.angle += r.speed * dt;});


void main () {
    registerSystems();
    writefln("have %s system(s):", g_registered_systems.length);
    foreach (name, sys; g_registered_systems) {
        writefln("  %s", name);
    }
    writefln("testing...");
    run_tests!([
        tuple("Rotator", "r", SystemicParam.In, SystemicResourceType.Component),
        tuple("DeltaTime", "dt", SystemicParam.In, SystemicResourceType.Singleton),
        tuple("RotationAngle", "rot", SystemicParam.InOut, SystemicResourceType.Component),
    ]);
}
