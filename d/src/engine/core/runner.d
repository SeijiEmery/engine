module engine.core.runner;
import derelict.glfw3.glfw3;
import derelict.opengl3.gl3;
import std.exception: enforce;
import engine.core.window: Window, WindowBuilder;
import engine.core.window.context: WindowContextVersion;
import engine.renderer;

public mixin template runGame (GameDelegate) {
    void main (string[] args) {
        import engine.core.runner: run;
        auto dg = makeGameDelegate!GameDelegate();
        run(dg, args);
    }
    auto makeGameDelegate (GameDelegate, Args...)(Args args) {
        static if (is(GameDelegate == class)) {
            return new GameDelegate(args);
        } else {
            return GameDelegate(args);
        }
    }
}

extern(C) nothrow void glfwPrintError(int error, const(char)* description) {
    import std.c.stdio : fputs, fputc, stderr;
    fputs(description, stderr);
    fputc('\n', stderr);
}

public void run (GameDelegate)(GameDelegate dg, string[] systemArgs) {
    try {
        DerelictGL3.load();
        DerelictGLFW3.load();
        glfwSetErrorCallback(&glfwPrintError);

        enforce(glfwInit(), "failed to initialize glfw!");
        auto wb = WindowBuilder();
        wb.contextVersion = WindowContextVersion.OpenGL_41;
        auto window = Window(wb);
        auto renderer = createRenderer!(RendererBackend.OpenGL);

        // setup...
        dg.registerComponents();
        dg.registerSystems();

        // run game with window...
        while (!window.shouldClose) {
            dg.onBeginFrame();
            foreach (event; window.processEvents) {
                dg.handleEvent(event);
            }
            renderer.beginFrame();

            // draw stuff...

            renderer.endFrame();
            dg.onEndFrame();
            window.swapBuffers();
        }
    } finally {
        glfwTerminate();
    }
}
