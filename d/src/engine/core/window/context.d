module engine.core.window.context;
import engine.core.window.exceptions;
import derelict.glfw3.glfw3;
import derelict.opengl3.gl3;
import std.exception: enforce;

enum WindowContextVersion {
    None      = 0,
    OpenGL_21 = 21,
    OpenGL_32 = 31,
    OpenGL_41 = 41,
    OpenGL_45 = 45,
    OpenGL_ES_20 = 120,
    OpenGL_ES_30 = 130,
    Vulkan = 50,
}

// ported from gsb
void configureWindowContextVersionHints (WindowContextVersion contextVersion) {
    final switch (contextVersion) {
        case WindowContextVersion.None: {
            glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API);
        } break;
        case WindowContextVersion.OpenGL_21: {
            glfwWindowHint(GLFW_CLIENT_API, GLFW_OPENGL_API);
            glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 2);
            glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 1);
            //glfwWindowHint(GLFW_FORWARD_COMPAT, false);
        } break;
        case WindowContextVersion.OpenGL_32: {
            glfwWindowHint(GLFW_CLIENT_API, GLFW_OPENGL_API);
            glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
            glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 2);
            //glfwWindowHint(GLFW_FORWARD_COMPAT, false);
        } break;
        case WindowContextVersion.OpenGL_41: {
            glfwWindowHint(GLFW_CLIENT_API, GLFW_OPENGL_API);
            glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
            glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 1);
            glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
            //glfwWindowHint(GLFW_FORWARD_COMPAT, true);
        } break;
        case WindowContextVersion.OpenGL_45: {
            glfwWindowHint(GLFW_CLIENT_API, GLFW_OPENGL_API);
            glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
            glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 5);
            glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
            //glfwWindowHint(GLFW_FORWARD_COMPAT, true);
        } break;
        case WindowContextVersion.OpenGL_ES_20: {
            glfwWindowHint(GLFW_CLIENT_API, GLFW_OPENGL_ES_API);
            glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 2);
            glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0);
        } break;
        case WindowContextVersion.OpenGL_ES_30: {
            glfwWindowHint(GLFW_CLIENT_API, GLFW_OPENGL_API);
            glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
            glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 0);
        } break;
        case WindowContextVersion.Vulkan: {
            enforce!WindowCreationException(false, "vulkan not available");
            //enforce!WindowCreationException(glfwVulkanAvailable(), "Failed to initialize GLFW window: Vulkan is not available");
            glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API);
        } break;
    }
}
