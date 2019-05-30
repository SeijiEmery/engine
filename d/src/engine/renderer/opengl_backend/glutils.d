module engine.renderer.opengl_backend.glutils;
import derelict.opengl3.gl3;
import engine.utils.math;
import std.format: format;

public string glGetMessage (GLenum err) {
    switch (err) {
        case GL_INVALID_OPERATION:              return "GL_INVALID_OPERATION";
        case GL_INVALID_ENUM:                   return "GL_INVALID_ENUM";
        case GL_INVALID_VALUE:                  return "GL_INVALID_VALUE";
        case GL_INVALID_FRAMEBUFFER_OPERATION:  return "GL_INVALID_FRAMEBUFFER_OPERATION";
        case GL_OUT_OF_MEMORY:                  return "GL_OUT_OF_MEMORY";
        default:                                assert(0, format("Invalid GLenum error value: %d", err));
    }
}
public uint glCreateBuffer () {
    uint buffer; glGenBuffers(1, &buffer); return buffer;
}
public uint glCreateVertexArray () {
    uint vao; glGenVertexArrays(1, &vao); return vao;
}
public uint glCreateTexture () {
    uint tex; glGenTextures(1, &tex); return tex;
}
public void glDeleteBuffer (ref uint buffer) {
    glDeleteBuffers(1, &buffer); buffer = 0;
}
public void glDeleteVertexArray (ref uint vao ) {
    glDeleteVertexArrays(1, &vao); vao = 0;
}
public void glDeleteTexture (ref uint tex) {
    glDeleteTextures(1, &tex); tex = 0;
}

public void glSetUniform (uint l, float v) { glUniform1f(l, v); }
public void glSetUniform (uint l, vec2  v) { glUniform2fv(l, 1, v.value_ptr); }
public void glSetUniform (uint l, vec3  v) { glUniform3fv(l, 1, v.value_ptr); }
public void glSetUniform (uint l, vec4  v) { glUniform4fv(l, 1, v.value_ptr); }

public void glSetUniform (uint l, mat2  v) { glUniformMatrix2fv(l, 1, true, v.value_ptr); }
public void glSetUniform (uint l, mat3  v) { glUniformMatrix3fv(l, 1, true, v.value_ptr); }
public void glSetUniform (uint l, mat4  v) { glUniformMatrix4fv(l, 1, true, v.value_ptr); }

public void glSetUniform (uint l, int   v) { glUniform1i(l, v); }
public void glSetUniform (uint l, vec2i v) { glUniform2iv(l, 1, v.value_ptr); }
public void glSetUniform (uint l, vec3i v) { glUniform3iv(l, 1, v.value_ptr); }
public void glSetUniform (uint l, vec4i v) { glUniform4iv(l, 1, v.value_ptr); }

public void glSetUniform (uint l, float[] v) { glUniform1fv(l, cast(int)v.length, &v[0]); }
public void glSetUniform (uint l, vec2[]  v) { glUniform2fv(l, cast(int)v.length, v[0].value_ptr); }
public void glSetUniform (uint l, vec3[]  v) { glUniform3fv(l, cast(int)v.length, v[0].value_ptr); }
public void glSetUniform (uint l, vec4[]  v) { glUniform4fv(l, cast(int)v.length, v[0].value_ptr); }

public void glSetUniform (uint l, mat2[]  v) { glUniformMatrix2fv(l, cast(int)v.length, true, v[0].value_ptr); }
public void glSetUniform (uint l, mat3[]  v) { glUniformMatrix3fv(l, cast(int)v.length, true, v[0].value_ptr); }
public void glSetUniform (uint l, mat4[]  v) { glUniformMatrix4fv(l, cast(int)v.length, true, v[0].value_ptr); }

public void glSetUniform (uint l, int[]   v) { glUniform1iv(l, cast(int)v.length, &v[0]); }
public void glSetUniform (uint l, vec2i[] v) { glUniform2iv(l, cast(int)v.length, v[0].value_ptr); }
public void glSetUniform (uint l, vec3i[] v) { glUniform3iv(l, cast(int)v.length, v[0].value_ptr); }
public void glSetUniform (uint l, vec4i[] v) { glUniform4iv(l, cast(int)v.length, v[0].value_ptr); }
