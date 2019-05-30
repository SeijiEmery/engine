import engine: runGame, WindowEvent;
import std.stdio;

struct EmptyWindow {
    void registerComponents () {}
    void registerSystems () {}
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
