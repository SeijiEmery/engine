module engine.renderer.opengl_backend.opengl_backend_renderer;
import engine.renderer.opengl_backend.vertex_buffer;
import engine.renderer.opengl_backend.shader;
import engine.renderer.renderer;
import std.variant;
import std.stdio: writefln;

struct Renderer {
    private RenderItem[] items;
    private RendererImpl renderer;

    this (RendererParams params) {
        this.renderer = RendererImpl(params);
    }
    void beginFrame () { items.length = 0; }
    void draw (RenderItem item) { 
        items ~= item; 
    }
    void endFrame   () {
        foreach (item; items) {
            renderer.draw(item);
        }
    }
}
struct RendererImpl {
    Shader       shader;
    //VertexBuffer vbo;

    this (RendererParams params) {
        this.shader = ShaderBuilder()
            .withFragment(FRAGMENT_SHADER)
            .withVertex(VERTEX_SHADER)
            .build();
    }
    void drawShape (string shader_subroutine, mat4 transform, vec4 color, float outline, bool transparent) {
        shader.setSubroutine("draw_primitive", shader_subroutine);
        shader.setUniform("transform", transform);
        shader.setUniform("color", color);
        shader.setUniform("outline_width", outline);
    }
    void draw (RenderItem item) {
        item.primitive.visit!(
            (DrawBox primitive) { 
                drawShape("draw_solid_box", item.transform, primitive.color, 0.0, item.transparent);
            },
            (DrawCircle primitive) { 
                drawShape("draw_solid_circle", item.transform, primitive.color, 0.0, item.transparent);
            },
            (DrawBoxOutline primitive) {
                drawShape("draw_outline_box", item.transform, primitive.color, primitive.outline, item.transparent);
            },
            (DrawCircleOutline primitive) {
                drawShape("draw_outline_circle", item.transform, primitive.color, primitive.outline, item.transparent);
            }
        );
    }
}

immutable float[] QUAD_GEOMETRY = [
    -0.5,  0.5,
    -0.5, -0.5,
     0.5, -0.5,
    -0.5,  0.5,
     0.5, -0.5,
     0.5,  0.5,
];
immutable string VERTEX_SHADER = r"
    #version 410
    in vec2 position;
    out vec2 local_coords;
    uniform mat4 transform;
    void main () {
        gl_Position = transform * vec4(position, 0.0, 1.0);
        local_coords = position * 2;
    }
";
immutable string FRAGMENT_SHADER = r"
    #version 410
    out vec4        out_color;
    in vec2         local_coords;
    uniform vec4    color;
    uniform float   outline_width;

    subroutine void draw_function();
    subroutine uniform draw_function draw_primitive;

    subroutine(draw_function) void draw_solid_box () {
        out_color = vec4(color.rgb * color.a, color.a);
    }
    subroutine(draw_function) void draw_solid_circle () {
        if (dot(local_coords, local_coords) < 1.0) {
            out_color = vec4(color.rgb * color.a, color.a);
        } else {
            discard;
        }
    }
    subroutine(draw_function) void draw_outline_box () {
        vec2 from_center = abs(local_coords);
        if (max(from_center.x, from_center.y) >= 1.0 - outline_width) {
            out_color = vec4(color.rgb * color.a, color.a);
        } else {
            discard;
        }
    }
    subroutine(draw_function) void draw_outline_circle () {
        float from_center = dot(local_coords, local_coords);
        if (from_center <= 1.0 && from_center >= 1.0 - outline_width) {
            out_color = vec4(color.rgb * color.a, color.a);
        } else {
            discard;
        }
    }
    void main () {
        draw_primitive();
    }
";
