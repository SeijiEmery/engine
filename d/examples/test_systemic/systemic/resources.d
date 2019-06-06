module systemic.resources;
import std.exception: enforce;
import std.format: format;

// NOT THREADSAFE!! 
// (yet)
public struct SystemsGlobalResourceManager {
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
