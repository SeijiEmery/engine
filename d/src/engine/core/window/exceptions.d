module engine.core.window.exceptions;

class WindowCreationException : Exception {
    this (string message, string file = __FILE__, ulong line = __LINE__) {
        super(message, file, line);
    }
}
