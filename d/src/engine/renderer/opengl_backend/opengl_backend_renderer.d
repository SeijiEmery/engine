module engine.renderer.opengl_backend.opengl_backend_renderer;
public import engine.renderer.renderer;

struct Renderer {
    private RenderItem[] items;

    void render (RenderItem item) { items ~= item; }
    void beginFrame () { items.length = 0; }
    void endFrame   () {
        
    }
}
