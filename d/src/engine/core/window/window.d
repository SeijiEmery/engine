module engine.core.window.window;
import engine.core.window.context: WindowContextVersion, configureWindowContextVersionHints;
import engine.utils.math;
import engine.utils.maybe: Maybe;
import std.exception: enforce;
import std.stdio: writefln;
import std.string: toStringz;
import derelict.glfw3.glfw3;

struct WindowBuilder {
    Maybe!vec2i     size;
    Maybe!string    title;
    WindowContextVersion contextVersion = WindowContextVersion.OpenGL_41;
}

struct Window {
    private GLFWwindow* m_window;
    alias m_window this;

    this (WindowBuilder builder) {
        writefln("Creating window");
        builder.contextVersion.configureWindowContextVersionHints();

        auto size  = builder.size.withDefault(vec2i(-1, -1));
        auto title = builder.title.withDefault("");

        auto x = builder.size.map((vec2i pos) => pos.x).withDefault(800);
        builder.size.map((vec2i pos) { writefln("%s", pos); });

        auto window = this.m_window = glfwCreateWindow(
            size.x, size.y, title.toStringz,
            glfwGetPrimaryMonitor(),
            null);
        enforce(window, "Failed to create glfw window!");
        glfwSetWindowUserPointer(window, cast(void*)this);

        // register event hooks...
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
}
