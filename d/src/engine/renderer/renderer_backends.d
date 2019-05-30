module engine.renderer.renderer_backends;
import engine.renderer.renderer;
import std.typecons: refCounted;

enum RendererBackend { MockRenderer, MockDebugRenderer, OpenGL };

auto createRenderer (RendererBackend backend)(RendererParams params = RendererParams()) {
    static if (backend == RendererBackend.OpenGL) {
        import engine.renderer.opengl_backend: Renderer;
        return refCounted(Renderer(params));
    } else if (backend == RendererBackend.MockRenderer) {
        import engine.renderer.renderer: MockRenderer;
        return refCounted(MockRenderer(params));
    } else if (backend == RendererBackend.MockDebugRenderer) {
        import engine.renderer.renderer: MockRenderer;
        auto renderer = refCounted(MockRenderer(params));
        renderer.debugDrawCalls = true;
        return renderer;
    }
}
