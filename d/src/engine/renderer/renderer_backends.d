module engine.renderer.renderer_backends;
import std.typecons: refCounted;

enum RendererBackend { OpenGL };

auto createRenderer (RendererBackend backend)() {
    static if (backend == RendererBackend.OpenGL) {
        import engine.renderer.opengl_backend: Renderer;
        return refCounted(Renderer());
    }
}
