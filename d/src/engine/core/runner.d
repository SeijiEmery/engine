module engine.core.runner;
import derelict.glfw3.glfw3;
import derelict.opengl3.gl3;
import std.exception: enforce;
import engine.core.window: Window, WindowBuilder;
import engine.core.window.context: WindowContextVersion;
import engine.utils.color;
import engine.renderer;
import std.stdio: writefln;

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
        writefln("initializing glfw + opengl...");
        DerelictGL3.load();
        DerelictGLFW3.load();
        glfwSetErrorCallback(&glfwPrintError);

        enforce(glfwInit(), "failed to initialize glfw!");
        auto wb = WindowBuilder();
        wb.contextVersion = WindowContextVersion.OpenGL_41;
        auto window = Window(wb);
        window.makeContextCurrent();

        writefln("setting up renderer...");
        import engine.renderer.opengl_backend: Renderer;
        auto renderer = Renderer(RendererParams());
        //auto renderer = createRenderer!(RendererBackend.OpenGL);
        writefln("ok...");
        //auto renderer = createRenderer!(RendererBackend.MockRenderer);
        //auto renderer = createRenderer!(RendererBackend.MockDebugRenderer);

        // setup...
        writefln("registering ecs components + systems...");
        dg.registerComponents();
        dg.registerSystems();

        // run game with window...
        writefln("starting main loop...");
        while (!window.shouldClose) {
            dg.onBeginFrame();
            foreach (event; window.processEvents) {
                dg.handleEvent(event);
            }
            renderer.beginFrame();

            // draw stuff...
            renderer.draw(renderBox(mat4.identity, color("#ff0000")));

            renderer.endFrame();
            dg.onEndFrame();
            window.swapBuffers();
        }
    } catch (Exception e) {
        writefln("Terminated with %s", e);
    } finally {
        writefln("main loop terminated, shutting down...");
        glfwTerminate();
    }
}
