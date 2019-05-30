module engine.core.window.events;
import std.variant: Algebraic;
import engine.utils.math;
public import derelict.glfw3.glfw3;

alias WindowEvent = Algebraic!(
    WindowClosed, WindowSetFocused, WindowSetMinimized, WindowMoved,
    WindowResized, WindowDpiChanged,
    MouseMoved, MouseScrolled, KeyPressed, MousePressed, TextEntered);

enum PressState { PRESSED, RELEASED, REPEAT, UNKNOWN };
bool pressed  (PressState state) { return state == PressState.PRESSED; }
bool released (PressState state) { return state == PressState.RELEASED; }
bool repeated (PressState state) { return state == PressState.REPEAT; }
private PressState pressStateFromGlfw (int state) {
    switch (state) {
        case GLFW_PRESS: return PressState.PRESSED;
        case GLFW_RELEASE: return PressState.RELEASED;
        case GLFW_REPEAT: return PressState.REPEAT;
        default: return PressState.UNKNOWN;
    }
}

// misc window events
struct WindowClosed     {}
struct WindowSetFocused    { bool focused; }
struct WindowSetMinimized  { bool focused; }
struct WindowMoved   { vec2i pos; }

// window resize events
struct WindowResized { vec2i size, oldSize; }
struct WindowDpiChanged { double dpi, oldDpi; }

// window input events
struct MouseMoved    { vec2d pos, delta; }
struct MouseScrolled { vec2d dir; }
struct KeyPressed    { PressState state; int key; int scancode; }
struct MousePressed  { PressState state; int button; }
struct TextEntered { dchar[] text; }



struct WindowEventProcessor {
    private WindowEvent[] eventBuffer;
    private vec2i windowSize;
    private vec2i windowFramebufferSize;
    private vec2d mousePos;
    private dchar[] textBuffer;
    private double lastDPI;

    this (GLFWwindow* window) {
        // set window user pointer to this event processor
        // (which should NOT be moved in memory, period...)
        glfwSetWindowUserPointer(window, cast(void*)&this);

        // setup event handlers...
        glfwWindowCallback!("WindowClose", function (WindowEventProcessor* cb) {
            cb.pushEvent(WindowClosed());
        })(window);
        glfwWindowCallback!("WindowFocus", function (WindowEventProcessor* cb, int focused) {
            cb.pushEvent(WindowSetFocused(focused != 0));
        })(window);
        glfwWindowCallback!("WindowIconify", function (WindowEventProcessor* cb, int minimized) {
            cb.pushEvent(WindowSetMinimized(minimized != 0));
        })(window);
        glfwWindowCallback!("WindowSize", function (WindowEventProcessor* cb, int w, int h) {
            cb.pushEvent(WindowResized(vec2i(w, h), cb.windowSize));
            cb.windowSize = vec2i(w, h);
        })(window);
        glfwWindowCallback!("FramebufferSize", function (WindowEventProcessor* cb, int w, int h) {
            cb.windowFramebufferSize = vec2i(w, h);
        })(window);
        glfwWindowCallback!("WindowPos", function (WindowEventProcessor* cb, int x, int y) {
            cb.pushEvent(WindowMoved(vec2i(x, y)));
        })(window);
        glfwWindowCallback!("Key", function (WindowEventProcessor* cb, int key, int scancode, int action, int mods) {
            cb.pushEvent(KeyPressed(action.pressStateFromGlfw, key, scancode));
        })(window);
        glfwWindowCallback!("Char", function (WindowEventProcessor* cb, uint codepoint) {
            cb.textBuffer ~= cast(dchar)codepoint;
        })(window);
        glfwWindowCallback!("MouseButton", function (WindowEventProcessor* cb, int button, int action, int mods) {
            cb.pushEvent(MousePressed(action.pressStateFromGlfw, button));
        })(window);
        glfwWindowCallback!("CursorPos", function (WindowEventProcessor* cb, double x, double y) {
            auto pos = vec2d(x, y);
            cb.pushEvent(MouseMoved(pos, cb.mousePos - pos));
            cb.mousePos = pos;
        })(window);
        glfwWindowCallback!("CursorPos", function (WindowEventProcessor* cb, double x, double y) {
            cb.pushEvent(MouseScrolled(vec2d(x, y)));
        })(window);
    }
    private void pushEvent (T)(T ev) @system nothrow {
        WindowEvent event = ev;
        this.eventBuffer ~= event;
    }
    public auto events () {
        // clear events, textBuffer...
        eventBuffer.length = 0;
        textBuffer.length = 0;
        auto lastDPI = windowFramebufferSize.y / windowSize.y;

        // poll events, calling the event callbacks above
        glfwPollEvents();

        // create special events not directly created from glfw callbacks
        auto newDPI = windowFramebufferSize.y / windowSize.y;
        if (newDPI != lastDPI) {
            pushEvent(WindowDpiChanged(newDPI, lastDPI));
        }
        if (textBuffer.length) {
            pushEvent(TextEntered(textBuffer));
        }

        // return resulting event list
        return cast(const WindowEvent[])eventBuffer;
    }
}

// crap for wrapping GLFW events...
void glfwWindowCallback(string name, alias dg)(GLFWwindow* window) {
    mixin("glfwSet" ~ name ~ "Callback(window, &WrapCall!(dg).callback);");
}
private struct WrapCall (alias dg) {
    import std.traits: Parameters;
    static extern (C) void callback (GLFWwindow* window, Parameters!(dg)[1..$] args) @trusted nothrow {
        dg(cast(WindowEventProcessor*)glfwGetWindowUserPointer(window), args);
    }
}
