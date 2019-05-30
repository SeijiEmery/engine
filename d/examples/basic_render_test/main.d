import engine: runGame, WindowEvent, EntityManager, SystemManager;
import engine.renderer;
import engine.utils.math;
import engine.utils.color;
import std.stdio;

struct BasicRenderTest {
    void registerComponents (ref EntityManager) {}
    void registerSystems (ref SystemManager) {}
    void handleEvent (WindowEvent event) {}
    void render (Renderer)(ref Renderer renderer) {
        renderer.draw(renderBox(mat4.identity, color("#ff0000")));
        renderer.draw(renderBoxOutline(mat4.identity, color("#00ff00"), 0.1));
        renderer.draw(renderCircle(mat4.identity, color("#0000ff")));
        renderer.draw(renderCircleOutline(mat4.identity, color("#ffff00"), 0.1));
    }
    void onBeginFrame () {}
    void onEndFrame () {}
    void teardown () {
        writefln("terminating...");
    }
}
mixin runGame!BasicRenderTest;
