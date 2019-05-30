module engine.renderer.opengl_backend.vao;
import engine.renderer.opengl_backend.glutils;
import engine.renderer.opengl_backend.vertex_buffer;
import engine.renderer.opengl_backend.context;
import engine.renderer.opengl_backend.enums;
import derelict.opengl3.gl3;

public struct VertexArray {
    uint m_object = 0;

    uint get () {
        if (!m_object) {
            m_object = gl.CreateVertexArray();
        }
        return m_object;
    }
    bool bind () {
        return gl.BindVertexArray(get());
    }
    auto clear () {
        if (m_object) {
            gl.DeleteVertexArray(m_object);
            m_object = 0;
        }
        return this;
    }
    void bindVertexAttrib (ref VertexBuffer vbo, uint index, int count, GLType type, GLNormalized normalized, size_t stride, size_t offset) {
        if (bind() && vbo.bind()) {
            gl.EnableVertexAttribArray(index);
            gl.VertexAttribPointer(index, count, type, normalized, cast(int)stride, cast(void*)offset);
            gl.BindVertexArray(0);
        }
    }
    //void bindVertexAttrib (uint index, ref Ref!GLVbo vbo, int count, GLType type,
    //    GLNormalized normalized, size_t stride, size_t offset
    //) {
    //    bindVertexAttrib(index, vbo.get, count, type, normalized, stride, offset);
    //}
    //void bindVertexAttrib (uint index, GLVbo vbo, int count, GLType type,
    //    GLNormalized normalized, size_t stride, size_t offset
    //) {
    //    if (bind() && vbo.bind()) {
    //        gl.VertexAttribPointer(index, count, type, normalized, cast(int)stride, cast(void*)offset);
    //        gl.EnableVertexAttribArray(index);
    //        gl.BindVertexArray(0);
    //    }
    //}
    void setVertexAttribDivisor (uint index, uint divisor) {
        if (bind()) {
            gl.VertexAttribDivisor(index, divisor);
            gl.BindVertexArray(0);
        }
    }
}