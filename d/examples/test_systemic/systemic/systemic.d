module systemic.systemic;
public import systemic.resources;
import std.algorithm;
import std.typecons;
import std.array: join;
import std.format: format;
public import entitysysd;
import std.stdio: writefln;

// new attributes
enum singleton;

public enum SystemicQualifier { In, Out, InOut }
public enum SystemicResourceType { Component, Singleton }
public alias SystemicParamTuple = Tuple!(string, string, SystemicQualifier, SystemicResourceType);
public alias SystemicParams = SystemicParamTuple[];

public alias SystemicFunction = void delegate (ref EntityManager, ref SystemsGlobalResourceManager);

public string makeSystemicFunction (SystemicParams params, string bodyImpl)() {
    auto impl = makeSystemicFunctionBodyImpl(params, bodyImpl);
    return "delegate (ref EntityManager entities, ref SystemsGlobalResourceManager resources) {\n\t\t\t"~impl~"\n\t\t}";
}
public void registerSystemFunction (string id, SystemicFunction fcn) {
    g_registeredSystems[id] = fcn;
}
public string createSystemic (SystemicParams params, string bodyImpl)() {
    auto fcn = makeSystemicFunction!(params, bodyImpl);
    auto id  = typeSignature(params);
    return "shared static this () {\n\tregisterSystemFunction(\n\t\t\""~id~"\",\n\t\t"~fcn~"\n\t);\n}";
}
private shared static SystemicFunction[string] g_registeredSystems;

public void visitSystems (alias visitor)() {
    writefln("Running visit on %s system(s)", g_registeredSystems.length);
    foreach (name, system; g_registeredSystems) {
        writefln("visiting %s: %s", name, system);
        static if (__traits(compiles, visitor(name, system)))
            visitor(name, system);
        else 
            visitor(system);
    }
}
public void runSystems (ref EntityManager entities, ref SystemsGlobalResourceManager resources) {
    visitSystems!((SystemicFunction fcn) {
        fcn(entities, resources);
    });
}

private string typeSignature (SystemicParams params) {
    auto a = params.filter!((SystemicParamTuple a) => a[2] != SystemicQualifier.Out).map!"a[0]".join(", ");
    auto b = params.filter!((SystemicParamTuple a) => a[2] != SystemicQualifier.In).map!"a[0]".join(", ");
    return a != "" ? b != "" ? a ~ " -> " ~ b : a : " -> " ~ b;
}
public string makeSystemicFunctionBodyImpl (SystemicParams params, string bodyImpl) {
    auto resources = params.filter!((SystemicParamTuple a) => a[3] == SystemicResourceType.Singleton);
    auto components = params.filter!((SystemicParamTuple a) => a[3] == SystemicResourceType.Component);
    auto fetchResources = resources.map!(
        (SystemicParamTuple a) => a[2] == SystemicQualifier.In ?
            "auto "~a[1]~" = resources.get!"~a[0]~";\n\t\t\t" :
            "auto "~a[1]~" = resources.getMut!"~a[0]~";\n\t\t\t")
        .join("");

    auto componentVars  = components.map!((SystemicParamTuple a) => ", "~a[1]).join();
    auto componentTypes = components.map!((SystemicParamTuple a) => a[0]).join(", ");
    return fetchResources~"foreach (entity"~componentVars~"; entities.entitiesWith!("~componentTypes~")) {\n\t\t\t\t"~bodyImpl~";\n\t\t\t}";
}
