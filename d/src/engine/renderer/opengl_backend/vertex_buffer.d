module engine.renderer.opengl_backend.vertex_buffer;
import engine.renderer.opengl_backend.glutils;
import engine.renderer.opengl_backend.enums;
import engine.renderer.opengl_backend.context;
import derelict.opengl3.gl3;

alias VertexBuffer  = GLBuffer!(GLBufferType.GL_ARRAY_BUFFER);
alias ElementBuffer = GLBuffer!(GLBufferType.GL_ELEMENT_ARRAY_BUFFER);

struct GLBuffer (GLBufferType BufferType) {
    uint m_object = 0;
    ~this () { clear(); }

    uint get () {
        if (!m_object) {
            m_object = gl.CreateBuffer();
        }
        return m_object;
    }
    bool bind () {
        return gl.BindBuffer!BufferType(get());
    }
    auto clear () {
        if (m_object) {
            gl.DeleteBuffer(m_object);
        }
        return this;
    }
    void bufferData (GLenum usage, T)(const T[] data) {
        bufferData(data, cast(GLBufferUsage)usage);
    }
    void bufferData (T)(const T[] data, GLBufferUsage usage) {
        if (bind()) {
            gl.BufferData(BufferType, data.length * T.sizeof, data.ptr, usage);
        }
    }
}
