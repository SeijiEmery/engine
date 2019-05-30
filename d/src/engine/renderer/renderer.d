module engine.renderer.renderer;
public import engine.utils.math;
import std.variant: Algebraic;

struct RendererParams {}

// Mock renderer:
// - any renderer implements this interface (beginFrame() / endFrame() / draw())
// - checks that the renderer's API is being used correctly
// - stores all drawcalls in a public array (this can be used for debugging)
struct MockRenderer {
    import std.exception: enforce;
    import std.stdio: writefln;

    public bool debugDrawCalls = false;
    public RenderItem[] drawcalls;
    private bool rendererActive = false;

    this (RendererParams params) {}

    // called at the beginning of a frame
    void beginFrame () { 
        rendererActive = true;
        enforce(drawcalls.length == 0, "drawcalls were modified outside of frame!");
        if (debugDrawCalls) { writefln("MockRenderer.beginFrame()"); }
    }
    
    // draw something. Valid only when called between beginFrame() / endFrame()
    void draw (RenderItem item) {
        enforce(rendererActive, "invalid draw() call: not between beginFrame() / endFrame()!");
        drawcalls ~= item;
        if (debugDrawCalls) { writefln("MockRenderer.draw(%s)", item); }
    }
    void endFrame () { 
        rendererActive = false; 
        drawcalls.length = 0;
        if (debugDrawCalls) { writefln("MockRenderer.endFrame()"); }
    }
}

// RenderItem spec: encapsulates all information needed for one 2d draw call
struct RenderItem {
    RenderPrimitive primitive;      // what are we drawing?
    mat4            transform;      // encapsulates ALL transformation info
    float           depth;          // depth (we pull this out for sorting)
    bool            transparent;    // transparency (we also pull this out for sorting)
}

// A render primitive is a kind of rendering operation that we support.
// We only support the following operations:
alias RenderPrimitive = Algebraic!(
    DrawBox, DrawBoxOutline, DrawCircle, DrawCircleOutline);

// Draws a 1 x 1 box (scaled / rotated / translated by the matrix transform) with a given solid color
struct DrawBox            { vec4 color; }

// Draws a 1 x 1 box outline (scaled / rotated / translated by the matrix transform) 
// with a given outline color and outline width
struct DrawBoxOutline     { vec4 color; float outline; }

// Draws a 1 x 1 circle / ellipse (scaled / rotated / translated by the matrix transform) with a given solid color
struct DrawCircle         { vec4 color; }

// Draws a 1 x 1 circle / ellipse outline (scaled / rotated / translated by the matrix transform) 
// with a given outline color and outline width
struct DrawCircleOutline  { vec4 color; float outline; }

// Helper functions to create render items

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
