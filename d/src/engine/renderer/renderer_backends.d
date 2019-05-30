module engine.renderer.renderer_backends;
import std.typecons: refCounted;

enum RendererBackend { MockRenderer, MockDebugRenderer, OpenGL };

auto createRenderer (RendererBackend backend)() {
    static if (backend == RendererBackend.OpenGL) {
        import engine.renderer.opengl_backend: Renderer;
        return refCounted(Renderer());
    } else if (backend == RendererBackend.MockRenderer) {
        import engine.renderer.renderer: MockRenderer;
        return refCounted(MockRenderer());
    } else if (backend == RendererBackend.MockDebugRenderer) {
        import engine.renderer.renderer: MockRenderer;
        auto renderer = refCounted(MockRenderer());
        renderer.debugDrawCalls = true;
        return renderer;
    }
}
