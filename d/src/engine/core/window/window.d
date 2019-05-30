module engine.core.window.window;
import engine.core.window.context: WindowContextVersion, configureWindowContextVersionHints;
import engine.core.window.events;
import engine.utils.math;
import engine.utils.maybe: Maybe;
import std.exception: enforce;
import std.stdio: writefln;
import std.string: toStringz;
import derelict.glfw3.glfw3;

struct WindowBuilder {
    Maybe!vec2i     size;
    Maybe!string    title;
    bool            fullscreen = false;
    WindowContextVersion contextVersion = WindowContextVersion.OpenGL_41;
}

struct Window {
    private GLFWwindow* m_window;
    private WindowEventProcessor eventProcessor;
    alias m_window this;
public:
    this (WindowBuilder builder) {
        writefln("Creating window");
        builder.contextVersion.configureWindowContextVersionHints();

        auto size  = builder.size.withDefault(builder.getDefaultWindowResolution());
        auto title = builder.title.withDefault("");
        builder.size.map((vec2i pos) { writefln("%s", pos); });

        auto window = this.m_window = glfwCreateWindow(
            size.x, size.y, title.toStringz,
            builder.fullscreen ? glfwGetPrimaryMonitor() : null,
            null);
        enforce(window, "Failed to create glfw window!");

        // register event hooks through the event processor...
        this.eventProcessor = WindowEventProcessor(window);
    }
    ~this () {
        writefln("Closing window");
        if (m_window) {
            m_window.glfwDestroyWindow();
        }
        m_window = null;
    }

    // getters / setters
    void setTitle (string title) {
        m_window.glfwSetWindowTitle(title.toStringz);
    }
    bool shouldClose () {
        return m_window.glfwWindowShouldClose() != 0;
    }
    void swapBuffers () {
        m_window.glfwSwapBuffers();
    }
    void makeContextCurrent () {
        import derelict.opengl3.gl3;
        m_window.glfwMakeContextCurrent();
        DerelictGL3.reload();
    }
    const(WindowEvent[]) processEvents () { 
        return eventProcessor.processEvents;
    }
}

// get default window resolution (for fullscreen OR windowed) if window builder hasn't specified .size
// called lazily using wb.size.withDefault(), see withDefault() impl in engine.utils.maybe
vec2i getDefaultWindowResolution (WindowBuilder wb) {
    auto mode = glfwGetPrimaryMonitor().glfwGetVideoMode();
    auto monitorSize = vec2i(mode.width, mode.height);
    return wb.fullscreen ?
        monitorSize :
        vec2i(800, 600);
        //monitorSize - vec2i(50, 50);
}