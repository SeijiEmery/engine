module engine.core.runner;
import derelict.glfw3.glfw3;
import derelict.opengl3.gl3;
import std.exception: enforce;
import engine.core.window: Window, WindowBuilder;
import engine.core.window.context: WindowContextVersion;
import engine.utils.color;
import engine.utils.time;
import engine.renderer;
import engine.core.ecs;
import std.stdio: writefln;
import std.format: format;

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
    TimeTracker timeTracker;
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
        //auto renderer = createRenderer!(RendererBackend.MockRenderer);
        //auto renderer = createRenderer!(RendererBackend.MockDebugRenderer);

        // setup...
        writefln("registering ecs components + systems...");
        auto ecs = makeECS;
        dg.registerComponents(ecs.entities);
        dg.registerSystems(ecs.systems);
        
        timeTracker.initFinished;
        writefln("initialized in %s", timeTracker.startupTime);

        // run game with window...
        writefln("starting main loop...");
        Time time;
        while (!window.shouldClose) {
            // update time...
            timeTracker.beginFrame();
            timeTracker.update(time);
            timeTracker.avgDeltaTime.map((Duration dt) {
                window.setTitle(format("%s fps", 1.0 / dt.toFloatSecs));
            });

            dg.onBeginFrame();
            foreach (event; window.processEvents) {
                dg.handleEvent(event);
            }
            renderer.beginFrame();

            // run systems...
            ecs.systems.run(time.deltaTime.fromFloatSecs);

            // draw stuff...
            dg.render(renderer);

            renderer.endFrame();
            dg.onEndFrame();
            timeTracker.endFrame();
            window.swapBuffers();
        }
    } catch (Exception e) {
        writefln("Terminated with %s", e);
    } finally {
        writefln("main loop terminated, shutting down...");
        glfwTerminate();
    }
}
