module engine.systemic;

enum component;
enum systemic;
enum systemic_ordering;
enum singular;
struct requires (Args...) { alias Stuff = Args; }

//enum requires;

//mixin template component (){}
//mixin template systemic (){}
//mixin template systemic_ordering () {}
//mixin template singular (){}
//mixin template requires () {}
//mixin template requires (Dependencies...) { alias Deps = Dependencies; }

mixin template implementSystemic (alias module_) {
    shared static this () {
        import std.stdio;
        import std.traits: hasUDA, getSymbolsByUDA, isFunction, Parameters, ReturnType;
        writefln("Hello, world!");
        //pragma(msg, module_);
        //pragma(msg, __traits(allMembers, module_));
        //pragma(msg, getSymbolsByUDA!(module_, component));
        pragma(msg, "components:");
        foreach (component; getSymbolsByUDA!(module_, component)) {
            pragma(msg, component);
            //writefln("has component: %s", component.stringOf);
        }
        pragma(msg, "systemics:");
        foreach (systemFcn; getSymbolsByUDA!(module_, systemic)) {
            pragma(msg, typeof(systemFcn));
            pragma(msg, is(systemFcn == function));
            pragma(msg, Parameters!systemFcn);
            pragma(msg, ReturnType!systemFcn);

            foreach (param; Parameters!systemFcn) {
                //static assert( hasUDA!(param, component) || hasUDA!(param, systemic) );
                pragma(msg, param);
                pragma(msg, __traits(isConst, param));
                pragma(msg, __traits(isOut, param));
                pragma(msg, __traits(isRef, param));
                pragma(msg, __traits(getAttributes, param));
            }

            //static assert(is(systemFcn == function) || is(systemFcn == delegate));
            //static assert(isFunction!systemFcn);
            if (isFunction!systemFcn) {

            } else {
                pragma(msg, "not a system function!");
                pragma(msg, &systemFcn);
            }
        }
        pragma(msg, "singulars:");
        foreach (sv; getSymbolsByUDA!(module_, singular)) {
            //writefln("has singular: %s", sv);
            pragma(msg, sv);
        }




        //foreach (item; __traits(allMembers, module_)) {
        //    writefln("%s: %s, %s, %s", item,
        //        getUDAs!(item, component).length,
        //        getUDAs!(item, singular).length,
        //        getUDAs!(item, systemic).length);

        //    pragma(msg, __traits(getAttributes, item));

        //    //foreach (attrib; __traits(getAttributes, item)) {
        //    //    pragma(msg, attrib);
        //    //}
        //    //if (hasUDA!(item, component)) {
        //    //    writefln("Has component %s", item);
        //    //}
        //    //if (hasUDA!(item, singular)) {
        //    //    writefln("Has singular %s", item);
        //    //}
        //    //if (hasUDA!(item, systemic)) {
        //    //    writefln("Has system function %s", item);
        //    //}
        //}
    }
}
