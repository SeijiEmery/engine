module engine.ecs.transform;  // this is the module we're implementing
import engine.utils.math: vec2, vec3, vec4, mat4, PI_2, sin, cos, lerp, cmp;
import engine.utils.color: color;
import engine.utils.maybe: Maybe, just, nothing;
//import std.typecons: NewType;   // used to construct new types / wrappers around existing types
import engine.systemic;

// magic: register components + systems
mixin implementSystemic!(engine.ecs.transform);
struct AngleRadians { float angle; alias angle this; }

struct EntityRef {}


// 'singular' types: there will exist exactly one of these in the program.
// useful analogy:
//    singular types are like GLSL uniforms     (there exists one per glsl program invocation / ecs simulation step)
//    component types are like GLSL attributes  (there exists many per glsl program invocation / ecs simulation step)
// this wouldn't be defined in this file, but was included here for reference
//@singular alias DeltaTime = NewType!float;
//@singular alias AbsoluteTime = NewType!float;

@singular struct DeltaTime { float dt; alias dt this; }
@singular struct AbsoluteTime { float time; alias time this; }

// Our core component data types
//@component alias RotationAngle = NewType!AngleRadians;
//@component alias Position      = NewType!vec2;
//@component alias Scale         = NewType!vec2;
//@component alias Depth         = NewType!float;
//@component alias Color         = NewType!vec4;

@component struct RotationAngle { AngleRadians angle; alias angle this; }
@component struct Position { vec2 pos; alias pos this; }
@component struct Scale { vec2 scale; alias scale this; }
@component struct Depth { float depth; alias depth this; }
@component struct Color { vec4 color; alias color this; }

// Active components: attach these to make an entity rotate, oscillate back and forth, change colors, etc
// Components can have dependencies (see above)
@component {
    @(requires!RotationAngle) struct Rotator             { float speed = 1.0; }
    @(requires!Position)      struct TranslateOscillator { vec2 a, b; float speed = 1.0; }
    @(requires!Scale)         struct ScaleOscillator     { vec2 a, b; float speed = 1.0; }
    @(requires!Depth)         struct DepthOscillator     { float a, b; float speed = 1.0; }
    @(requires!Color)         struct ColorOscillator     { vec4 a, b; float speed = 1.0; }
}


// Systems: these are just functions!
// we can use reflection to iterate over everything tagged @systemic (note: the function names are irrelevant),
// and use the in / out / inout keywords along with the component types to determine what the execution order of these are
// we can use this to (effectively) construct an execution graph, and we can do this (mostly) at compile time!
// (I think / hope, anyways... not all of this has been implemented yet, but should be feasible...)

pure @systemic void rotate (in Rotator r, in DeltaTime dt, out RotationAngle angle) {
    angle += r.speed * dt;
}
pure @systemic void oscillatePosition (in TranslateOscillator osc, in AbsoluteTime t, out Position pos) {
    pos = lerp(osc.a, osc.b, sin(t * PI_2 * osc.speed));
}
pure @systemic void osclilateScale (in ScaleOscillator osc, in AbsoluteTime t, out Scale scale) {
    scale = lerp(osc.a, osc.b, sin(t * PI_2 * osc.speed));
}
pure @systemic void oscillateDepth (in DepthOscillator osc, in AbsoluteTime t, out Depth depth) {
    depth.depth = lerp(osc.a, osc.b, sin(t * PI_2 * osc.speed));
}
pure @systemic void color (in ColorOscillator osc, in AbsoluteTime t, out Color color) {
    color = lerp(osc.a, osc.b, sin(t * PI_2 * osc.speed));
}

// Local + world transforms
// All of the above (mostly...) creates the local transforms; local transforms are chained, using
// TransformHierarchy components, to produce entities that can be nested in transform hierarchies
// (ie. object A is parented to object B; moving object A will "move" object B)

@component @(requires!(Position, RotationAngle, Scale, Depth)) struct LocalTransform { mat4 transform; alias transform this; }
@component @(requires!(LocalTransform, TransformHierarchy))    struct WorldTransform { mat4 transform; alias transform this; }

// this is TBD / placeholder
@component struct TransformHierarchy { 
private:
    Maybe!EntityRef _parent;   
    size_t          _depth; 
    EntityRef[]     _children; 
public:
    pure const auto depth () { return _depth; }
    pure const auto parent () { return _parent; }
    pure const bool contains (ref const(TransformHierarchy) other) {
        if (depth() < other.depth()) {
            return false;
        }
        //foreach (child; _children) {
        //    if (child == other || child.contains(other)) {
        //        return true;
        //    }
        //}
        return false;
    }
}
//auto getComponent (T)(ref Maybe!EntityRef entity) {
//    return nothing!T();
//}
//auto getComponent (T)(ref const(Maybe!EntityRef) entity) {
//    return nothing!T();
//}
//auto transform (ref Maybe!EntityRef entity) { return entity.getComponent!WorldTransform; }
//auto transform (ref const(Maybe!EntityRef) entity) { return entity.getComponent!WorldTransform; }

pure WorldTransform transform (ref const(Maybe!EntityRef) entity) { return WorldTransform(mat4.identity); }


// Calculate local transform
pure @systemic void calculateTransform (in Position pos, in RotationAngle angle, in Scale scale, in Depth depth, ref LocalTransform transform) {
    auto c = angle.cos, s = angle.sin;
    transform = mat4(
        +c * angle * scale.x, +s * angle, 0.0,  pos.x,
        -s * angle, +c * angle * scale.y, 0.0,  pos.y,
        0.0,        0.0,                  1.0,  depth,
        0.0,        0.0,                  0.0,  1.0
    );
}

// Calculate world transform

// some entities need to be sorted.
// this is... one way to do that...

// sorting order (for transforms...)
pure @systemic_ordering int calculateTransform (in TransformHierarchy first, in TransformHierarchy second) { 
    if (first.depth != second.depth) {
        return cast(int)second.depth - cast(int)first.depth;
    }
    return second.contains(first) ? 1 : -1;
}

//@systemic_sorting void sortTransforms (inout EntityListOf!(TransformHierarchy) entities) {
//    entities.sort!((a, b) => a.depth != b.depth ?
//                                a.depth - b.depth :
//                                b.contains(a) ? 1 : -1);
//}
pure @systemic void calculateTransform (in TransformHierarchy hierarchy, in LocalTransform localTransform, ref WorldTransform worldTransform) {
    //worldTransform = hierarchy.parent.transform.map((WorldTransform transform) => transform * localTransform)
    //    .withDefault(localTransform);
}

// TBD / awesome things that maybe -could- be implemented:
//  - automatically track dirty components
//  => systems run iff dependents are dirty
//    - track dirty by comparing component states: something like:
    //    for all dirty input states...
    //        let state = entity.output_state...
    //        let oldState = state.dup;
    //        runSystemFunction(oldState, inputs...)
    //        state.dirty = state != oldState;
//  - automatic serialization
//    (duh...)
//  - automatic versioning:
//    b/c reflection, we can check when the internals of stuff changes
//    hell, we can even intelligently convert old => new data by using defaults (in some cases...)

// note that because we're using in / out keywords, NOT return values, our system functions can use arbitrary
//  numbers of input / output components

// obviously, there's a lot that could go wrong though, so the execution graph (DAG) will have to be checked,
// ideally at compile time