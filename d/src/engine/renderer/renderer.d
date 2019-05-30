module engine.renderer.renderer;
public import engine.utils.math;
import std.variant: Algebraic;

struct DrawBox            { vec4 color; }
struct DrawBoxOutline     { vec4 color; float outline; }
struct DrawCircle         { vec4 color; }
struct DrawCircleOutline  { vec4 color; float outline; }

alias RenderPrimitive = Algebraic!(
    DrawBox, DrawBoxOutline, DrawCircle, DrawCircleOutline);

struct RenderItem {
    RenderPrimitive primitive;
    mat4            transform;
    float           depth;
    bool            transparent;
}

RenderItem renderBox (mat4 transform, vec4 color) {
    RenderPrimitive primitive = DrawBox(color);
    return RenderItem(primitive, transform, transform.depth, color.a < 1.0);
}
RenderItem renderCircle (mat4 transform, vec4 color) {
    RenderPrimitive primitive = DrawCircle(color);
    return RenderItem(primitive, transform, transform.depth, color.a < 1.0);
}
RenderItem renderBoxOutline (mat4 transform, vec4 color, float outline) {
    RenderPrimitive primitive = DrawBoxOutline(color, outline);
    return RenderItem(primitive, transform, transform.depth, color.a < 1.0);
}
RenderItem renderCircleOutline (mat4 transform, vec4 color, float outline) {
    RenderPrimitive primitive = DrawCircleOutline(color, outline);
    return RenderItem(primitive, transform, transform.depth, color.a < 1.0);
}
