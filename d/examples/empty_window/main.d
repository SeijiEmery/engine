import engine: runGame, WindowEvent, EntityManager, SystemManager;
import std.stdio;

struct EmptyWindow {
    void registerComponents (ref EntityManager) {}
    void registerSystems (ref SystemManager) {}
    void handleEvent (WindowEvent event) {
        writefln("Got event %s", event);
    }
    void render (Renderer)(ref Renderer renderer) {}
    void onBeginFrame () {}
    void onEndFrame () {}
    void teardown () {
        writefln("terminating...");
    }
}
mixin runGame!EmptyWindow;
