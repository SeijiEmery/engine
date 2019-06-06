module systemic.systemic;
public import systemic.resources;
import std.algorithm;
import std.typecons;
import std.array: join;
import std.format: format;
public import entitysysd;

// new attributes
enum singleton;

public enum SystemicParam { In, Out, InOut }
public enum SystemicResourceType { Component, Singleton }
public alias SystemicParamTuple = Tuple!(string, string, SystemicParam, SystemicResourceType);
public alias SystemicParams = SystemicParamTuple[];

public alias SystemicFunction = void delegate (ref EntityManager, ref SystemsGlobalResourceManager);

public SystemicFunction systemicFunction (SystemicParams params, string bodyImpl)() {
    return delegate (ref EntityManager entities, ref SystemsGlobalResourceManager resources) {
        mixin(makeBodyImpl(params, bodyImpl));
    };
}
public void registerSystemFunction (SystemicParams params, SystemicFunction fcn) {
    g_registeredSystems[typeSignature(params)] = fcn;
}
public mixin template createSystemic (SystemicParams params, string bodyImpl) {
    shared static this () {
        registerSystemFunction(params, systemicFunction!(params, bodyImpl));
    }
}
private shared static SystemicFunction[string] g_registeredSystems;

public void visitSystems (alias visitor)() {
    foreach (name, system; g_registeredSystems) {
        static if (__traits(compiles, visitor(name, system)))
            visitor(name, system);
        else 
            visitor(system);
    }
}
public void runSystems (ref EntityManager entities, ref SystemsGlobalResourceManager resources) {
    visitSystems!((ref SystemicFunction fcn) {
        fcn(entities, resources);
    });
}

private string typeSignature (SystemicParams params) {
    auto a = params.filter!((SystemicParamTuple a) => a[2] != SystemicParam.Out).map!"a[0]".join(", ");
    auto b = params.filter!((SystemicParamTuple a) => a[2] != SystemicParam.In).map!"a[0]".join(", ");
    return a != "" ? b != "" ? a ~ " -> " ~ b : a : " -> " ~ b;
}
//string makeBodyImpl (SystemicParams params, string body) {
private string makeBodyImpl (SystemicParams params, string bodyImpl) {
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
