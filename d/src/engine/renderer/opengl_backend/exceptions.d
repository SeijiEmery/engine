module engine.renderer.opengl_backend.exceptions;
public import std.exception: Exception, enforce;
public import std.format: format;

class GLException : Exception {
    this (string message, string file = __FILE__, ulong line = __LINE__) {
        super(message, file, line);
    }
}
class GLRuntimeException : GLException {
    this (string message, string context, string file = __FILE__, ulong line = __LINE__, string fcn = __PRETTY_FUNCTION__) {
        super(format("%s while calling %s in %s", message, context, fcn), file, line);
    }
}
