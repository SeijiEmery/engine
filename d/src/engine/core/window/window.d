module engine.core.window.window;
import engine.core.window.context: WindowContextVersion, configureWindowContextVersionHints;
import engine.utils.math;
import std.exception: enforce;
import std.stdio: writefln;
import std.string: toStringz;
import derelict.glfw3.glfw3;


struct WindowBuilder {
    vec2i   size  = vec2i(800, 600);
    string  title = "";
    WindowContextVersion contextVersion = WindowContextVersion.OpenGL_41;
}

struct Window {
    private GLFWwindow* m_window;
    alias m_window this;

    this (WindowBuilder builder) {
        writefln("Creating window");
        builder.contextVersion.configureWindowContextVersionHints();
        auto window = this.m_window = glfwCreateWindow(
            builder.size.x, builder.size.y,
            builder.title.toStringz,
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
