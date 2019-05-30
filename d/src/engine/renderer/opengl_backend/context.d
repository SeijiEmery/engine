module engine.renderer.opengl_backend.context;
import engine.renderer.opengl_backend.glutils;
import engine.renderer.opengl_backend.enums;
import engine.renderer.opengl_backend.config;
import engine.renderer.opengl_backend.exceptions;
import derelict.opengl3.gl3;
import std.format: format;

// Global context
__gshared GLContext gl;

shared static this () {
    gl = new GLContext();
}

final class GLContext {
    struct ContextState {
        uint shader      = 0;
        uint vao         = 0;
        uint buffer      = 0;
        uint texture     = 0;
        int  textureSlot = -1;
    }
    ContextState m_state;

    private static bool doBind (T)(ref T target, const T value) {
        if (target != value) {
            target = value;
            return true;
        }
        return false;
    }

    private auto getv (string name, T)(uint object, GLenum pname) {
        T value;
        static if (is(T == int))  { this.opDispatch!("Get"~name~"iv")(object, pname, &value); }
        static if (is(T == uint)) { this.opDispatch!("Get"~name~"uiv")(object, pname, &value); }
        return value;
    }


    // Nicely wraps all GL operations with error checking code, etc.
    // We can further "override" by defining functions like "bind" (called as "gl.bind(...)"), etc. 
    template opDispatch (string fcn) {
        auto opDispatch (
            string caller_file = __FILE__, 
            ulong caller_line = __LINE__, 
            string caller_fcn = __PRETTY_FUNCTION__, 
            Args...
        )(
            Args args
        ) {
            immutable bool hasReturn = !is(typeof(mixin("gl"~fcn)(args)) == void);

            static if (hasReturn)   auto result = mixin("gl"~fcn)(args);
            else                    mixin("gl"~fcn)(args);
 
            // If value in enum to track call #s, update that call value
            static if (__traits(compiles, mixin("GLTracedCalls."~fcn))) {
                mixin("callTraceCount[GLTracedCalls."~fcn~"]++;");
            }

            debug static if (DEBUG_LOG_GL_CALLS) {
                import std.stdio;
                static if (hasReturn) writefln("(opengl-debug) gl%s(%s) => %s", fcn, joinArgs(args), result);
                else                  writefln("(opengl-debug) gl%s(%s)", fcn, joinArgs(args));
            }

            // Check for errors.
            checkError(format("gl%s(%s)", fcn, joinArgs(args)), caller_file, caller_line, caller_fcn);

            // Return result (if any).
            static if (hasReturn)    return result;
        }
    }
    private static string joinArgs (Args...)(Args args) {
        import std.conv;
        import std.array;

        string[] sargs;
        foreach (arg; args)
            sargs ~= arg.to!string();
        return sargs.join(", ");
    }

    // Internal call used to check errors after making GL calls.
    public void checkError (lazy string fcn, string caller_file = __FILE__, ulong caller_line = __LINE__, string caller_fcn = __PRETTY_FUNCTION__) {
        static if (GL_RUNTIME_ERROR_CHECKING_ENABLED) {
            auto err = glGetError();
            if (err != GL_NO_ERROR) {
                throw new GLRuntimeException(glGetMessage(err), fcn, caller_file, caller_line, caller_fcn);
            }
        }
    }

    // Flushes / Ignores all errors
    public void flushErrors () {
        while (glGetError()) {}
    }

    // Records GL Call count for specified calls (defined in GLTracedCalls)
    private int[GLTracedCalls.max] callTraceCount;
    public auto ref getCallCounts () { return callTraceCount; }
    public void   resetCallCounts () { callTraceCount[0..$] = 0; }

    //
    // GL Calls, etc...
    //

    bool BindProgram (uint program) {
        //if (doBind(m_state.shader, program))
            this.UseProgram(program);
        return program != 0;
    }
    bool BindVertexArray (uint vao) {
        //if (doBind(m_state.vao, vao))
            this.opDispatch!"BindVertexArray"(vao);
        return vao != 0;
    }
    bool BindBuffer (GLenum bufferType)(uint buffer) {
        //if (doBind(m_state.buffer, buffer))
            this.opDispatch!"BindBuffer"(bufferType, buffer);
        return buffer != 0;
    }
    bool BindTexture (GLenum type)(uint texture, int textureSlot) {
        //if (doBind(m_state.textureSlot, textureSlot))
            this.opDispatch!"ActiveTexture"(GL_TEXTURE0 + textureSlot);
        //if (doBind(m_state.texture, texture))
            this.opDispatch!"BindTexture"(textureType, texture);
        return texture != 0;
    }
}
