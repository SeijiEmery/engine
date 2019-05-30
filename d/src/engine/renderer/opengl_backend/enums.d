module engine.renderer.opengl_backend.enums;
import engine.utils.math;
import derelict.opengl3.gl3;

// Traced calls...
enum GLTracedCalls {
    DrawArrays,
    DrawIndexed,
};

enum GLTextureType : GLenum { 
    GL_TEXTURE_2D           = derelict.opengl3.gl3.GL_TEXTURE_2D,
}
enum GLBufferType : GLenum { 
    GL_ARRAY_BUFFER         = derelict.opengl3.gl3.GL_ARRAY_BUFFER,
    GL_ELEMENT_ARRAY_BUFFER = derelict.opengl3.gl3.GL_ELEMENT_ARRAY_BUFFER,
    GL_UNIFORM_BUFFER       = derelict.opengl3.gl3.GL_UNIFORM_BUFFER,
}
enum GLBufferUsage : GLenum {
    GL_STATIC_DRAW          = derelict.opengl3.gl3.GL_STATIC_DRAW,
    GL_DYNAMIC_DRAW         = derelict.opengl3.gl3.GL_DYNAMIC_DRAW,
    GL_STREAM_DRAW          = derelict.opengl3.gl3.GL_STREAM_DRAW,
}
enum GLNormalized : GLboolean {
    TRUE                    = GL_TRUE,
    FALSE                   = GL_FALSE,
}

enum GLType : GLenum {
    GL_FLOAT = derelict.opengl3.gl3.GL_FLOAT,
    GL_FLOAT_VEC2 = derelict.opengl3.gl3.GL_FLOAT_VEC2,
    GL_FLOAT_VEC3 = derelict.opengl3.gl3.GL_FLOAT_VEC3,
    GL_FLOAT_VEC4 = derelict.opengl3.gl3.GL_FLOAT_VEC4,
    GL_DOUBLE = derelict.opengl3.gl3.GL_DOUBLE,
    GL_DOUBLE_VEC2 = derelict.opengl3.gl3.GL_DOUBLE_VEC2,
    GL_DOUBLE_VEC3 = derelict.opengl3.gl3.GL_DOUBLE_VEC3,
    GL_DOUBLE_VEC4 = derelict.opengl3.gl3.GL_DOUBLE_VEC4,
    GL_INT = derelict.opengl3.gl3.GL_INT,
    GL_INT_VEC2 = derelict.opengl3.gl3.GL_INT_VEC2,
    GL_INT_VEC3 = derelict.opengl3.gl3.GL_INT_VEC3,
    GL_INT_VEC4 = derelict.opengl3.gl3.GL_INT_VEC4,
    GL_UNSIGNED_INT = derelict.opengl3.gl3.GL_UNSIGNED_INT,
    GL_UNSIGNED_INT_VEC2 = derelict.opengl3.gl3.GL_UNSIGNED_INT_VEC2,
    GL_UNSIGNED_INT_VEC3 = derelict.opengl3.gl3.GL_UNSIGNED_INT_VEC3,
    GL_UNSIGNED_INT_VEC4 = derelict.opengl3.gl3.GL_UNSIGNED_INT_VEC4,
    GL_BOOL = derelict.opengl3.gl3.GL_BOOL,
    GL_BOOL_VEC2 = derelict.opengl3.gl3.GL_BOOL_VEC2,
    GL_BOOL_VEC3 = derelict.opengl3.gl3.GL_BOOL_VEC3,
    GL_BOOL_VEC4 = derelict.opengl3.gl3.GL_BOOL_VEC4,
    GL_FLOAT_MAT2 = derelict.opengl3.gl3.GL_FLOAT_MAT2,
    GL_FLOAT_MAT3 = derelict.opengl3.gl3.GL_FLOAT_MAT3,
    GL_FLOAT_MAT4 = derelict.opengl3.gl3.GL_FLOAT_MAT4,
    GL_FLOAT_MAT2x3 = derelict.opengl3.gl3.GL_FLOAT_MAT2x3,
    GL_FLOAT_MAT2x4 = derelict.opengl3.gl3.GL_FLOAT_MAT2x4,
    GL_FLOAT_MAT3x2 = derelict.opengl3.gl3.GL_FLOAT_MAT3x2,
    GL_FLOAT_MAT3x4 = derelict.opengl3.gl3.GL_FLOAT_MAT3x4,
    GL_FLOAT_MAT4x2 = derelict.opengl3.gl3.GL_FLOAT_MAT4x2,
    GL_FLOAT_MAT4x3 = derelict.opengl3.gl3.GL_FLOAT_MAT4x3,
    GL_DOUBLE_MAT2 = derelict.opengl3.gl3.GL_DOUBLE_MAT2,
    GL_DOUBLE_MAT3 = derelict.opengl3.gl3.GL_DOUBLE_MAT3,
    GL_DOUBLE_MAT4 = derelict.opengl3.gl3.GL_DOUBLE_MAT4,
    GL_DOUBLE_MAT2x3 = derelict.opengl3.gl3.GL_DOUBLE_MAT2x3,
    GL_DOUBLE_MAT2x4 = derelict.opengl3.gl3.GL_DOUBLE_MAT2x4,
    GL_DOUBLE_MAT3x2 = derelict.opengl3.gl3.GL_DOUBLE_MAT3x2,
    GL_DOUBLE_MAT3x4 = derelict.opengl3.gl3.GL_DOUBLE_MAT3x4,
    GL_DOUBLE_MAT4x2 = derelict.opengl3.gl3.GL_DOUBLE_MAT4x2,
    GL_DOUBLE_MAT4x3 = derelict.opengl3.gl3.GL_DOUBLE_MAT4x3,
    GL_SAMPLER_1D = derelict.opengl3.gl3.GL_SAMPLER_1D,
    GL_SAMPLER_2D = derelict.opengl3.gl3.GL_SAMPLER_2D,
    GL_SAMPLER_3D = derelict.opengl3.gl3.GL_SAMPLER_3D,
    GL_SAMPLER_CUBE = derelict.opengl3.gl3.GL_SAMPLER_CUBE,
    GL_SAMPLER_1D_SHADOW = derelict.opengl3.gl3.GL_SAMPLER_1D_SHADOW,
    GL_SAMPLER_2D_SHADOW = derelict.opengl3.gl3.GL_SAMPLER_2D_SHADOW,
    GL_SAMPLER_1D_ARRAY = derelict.opengl3.gl3.GL_SAMPLER_1D_ARRAY,
    GL_SAMPLER_2D_ARRAY = derelict.opengl3.gl3.GL_SAMPLER_2D_ARRAY,
    GL_SAMPLER_1D_ARRAY_SHADOW = derelict.opengl3.gl3.GL_SAMPLER_1D_ARRAY_SHADOW,
    GL_SAMPLER_2D_ARRAY_SHADOW = derelict.opengl3.gl3.GL_SAMPLER_2D_ARRAY_SHADOW,
    GL_SAMPLER_2D_MULTISAMPLE = derelict.opengl3.gl3.GL_SAMPLER_2D_MULTISAMPLE,
    GL_SAMPLER_2D_MULTISAMPLE_ARRAY = derelict.opengl3.gl3.GL_SAMPLER_2D_MULTISAMPLE_ARRAY,
    GL_SAMPLER_CUBE_SHADOW = derelict.opengl3.gl3.GL_SAMPLER_CUBE_SHADOW,
    GL_SAMPLER_BUFFER = derelict.opengl3.gl3.GL_SAMPLER_BUFFER,
    GL_SAMPLER_2D_RECT = derelict.opengl3.gl3.GL_SAMPLER_2D_RECT,
    GL_SAMPLER_2D_RECT_SHADOW = derelict.opengl3.gl3.GL_SAMPLER_2D_RECT_SHADOW,
    GL_INT_SAMPLER_1D = derelict.opengl3.gl3.GL_INT_SAMPLER_1D,
    GL_INT_SAMPLER_2D = derelict.opengl3.gl3.GL_INT_SAMPLER_2D,
    GL_INT_SAMPLER_3D = derelict.opengl3.gl3.GL_INT_SAMPLER_3D,
    GL_INT_SAMPLER_CUBE = derelict.opengl3.gl3.GL_INT_SAMPLER_CUBE,
    GL_INT_SAMPLER_1D_ARRAY = derelict.opengl3.gl3.GL_INT_SAMPLER_1D_ARRAY,
    GL_INT_SAMPLER_2D_ARRAY = derelict.opengl3.gl3.GL_INT_SAMPLER_2D_ARRAY,
    GL_INT_SAMPLER_2D_MULTISAMPLE = derelict.opengl3.gl3.GL_INT_SAMPLER_2D_MULTISAMPLE,
    GL_INT_SAMPLER_2D_MULTISAMPLE_ARRAY = derelict.opengl3.gl3.GL_INT_SAMPLER_2D_MULTISAMPLE_ARRAY,
    GL_INT_SAMPLER_BUFFER = derelict.opengl3.gl3.GL_INT_SAMPLER_BUFFER,
    GL_INT_SAMPLER_2D_RECT = derelict.opengl3.gl3.GL_INT_SAMPLER_2D_RECT,
    GL_UNSIGNED_INT_SAMPLER_1D = derelict.opengl3.gl3.GL_UNSIGNED_INT_SAMPLER_1D,
    GL_UNSIGNED_INT_SAMPLER_2D = derelict.opengl3.gl3.GL_UNSIGNED_INT_SAMPLER_2D,
    GL_UNSIGNED_INT_SAMPLER_3D = derelict.opengl3.gl3.GL_UNSIGNED_INT_SAMPLER_3D,
    GL_UNSIGNED_INT_SAMPLER_CUBE = derelict.opengl3.gl3.GL_UNSIGNED_INT_SAMPLER_CUBE,
    GL_UNSIGNED_INT_SAMPLER_1D_ARRAY = derelict.opengl3.gl3.GL_UNSIGNED_INT_SAMPLER_1D_ARRAY,
    GL_UNSIGNED_INT_SAMPLER_2D_ARRAY = derelict.opengl3.gl3.GL_UNSIGNED_INT_SAMPLER_2D_ARRAY,
    GL_UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE = derelict.opengl3.gl3.GL_UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE,
    GL_UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE_ARRAY = derelict.opengl3.gl3.GL_UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE_ARRAY,
    GL_UNSIGNED_INT_SAMPLER_BUFFER = derelict.opengl3.gl3.GL_UNSIGNED_INT_SAMPLER_BUFFER,
    GL_UNSIGNED_INT_SAMPLER_2D_RECT = derelict.opengl3.gl3.GL_UNSIGNED_INT_SAMPLER_2D_RECT,
}

/*
 * GL3n type polyfill to match glsl
 */

public alias dvec2 = GLdvec2;
public alias dvec3 = GLdvec3;
public alias dvec4 = GLdvec4;

public alias ivec2 = GLivec2;
public alias ivec3 = GLivec3;
public alias ivec4 = GLivec4;

public alias uvec2 = GLuvec2;
public alias uvec3 = GLuvec3;
public alias uvec4 = GLuvec4;

public alias bvec2 = GLbvec2;
public alias bvec3 = GLbvec3;
public alias bvec4 = GLbvec4;

public alias mat2x3 = GLmat2x3;
public alias mat2x4 = GLmat2x4;
public alias mat3x2 = GLmat3x2;
public alias mat3x4 = GLmat3x4;
public alias mat4x2 = GLmat4x2;
public alias mat4x3 = GLmat4x3;

public alias dmat2   = GLdmat2;
public alias dmat2x3 = GLdmat2x3;
public alias dmat2x4 = GLdmat2x4;

public alias dmat3   = GLdmat3;
public alias dmat3x2 = GLdmat3x2;
public alias dmat3x4 = GLdmat3x4;
public alias dmat4   = GLdmat4;
public alias dmat4x2 = GLdmat4x2;
public alias dmat4x3 = GLdmat4x3;

/*
 * Fully qualified GLSL types
 */

public alias GLvec1 = GLfloat;               static assert(is(GLfloat == float));
public alias GLvec2 = Vector!(GLfloat, 2);   static assert(is(GLvec2  == vec2));
public alias GLvec3 = Vector!(GLfloat, 3);   static assert(is(GLvec3  == vec3));
public alias GLvec4 = Vector!(GLfloat, 4);   static assert(is(GLvec4  == vec4));

public alias GLdvec1 = GLdouble;             static assert(is(GLdouble == double));
public alias GLdvec2 = Vector!(GLdouble, 2); static assert(is(GLdvec2  == vec2d));
public alias GLdvec3 = Vector!(GLdouble, 3); static assert(is(GLdvec3  == vec3d));
public alias GLdvec4 = Vector!(GLdouble, 4); static assert(is(GLdvec4  == vec4d));

public alias GLivec1 = GLint;                static assert(is(GLint   == int));
public alias GLivec2 = Vector!(GLint, 2);    static assert(is(GLivec2 == vec2i));
public alias GLivec3 = Vector!(GLint, 3);    static assert(is(GLivec3 == vec3i));
public alias GLivec4 = Vector!(GLint, 4);    static assert(is(GLivec4 == vec4i));

public alias GLuvec1 = GLuint;               static assert(is(GLuint == uint));
public alias GLuvec2 = Vector!(GLuint, 2);
public alias GLuvec3 = Vector!(GLuint, 3);
public alias GLuvec4 = Vector!(GLuint, 4);

public alias GLbvec1 = GLboolean;               static assert(is(GLboolean == ubyte));
public alias GLbvec2 = Vector!(GLboolean, 2);
public alias GLbvec3 = Vector!(GLboolean, 3);
public alias GLbvec4 = Vector!(GLboolean, 4);

public alias GLmat2     = Matrix!(GLfloat, 2, 2);  static assert(is(GLmat2  == mat2));
public alias GLmat2x3   = Matrix!(GLfloat, 2, 3);  //static assert(is(GLmat23 == mat23));
public alias GLmat2x4   = Matrix!(GLfloat, 2, 4);  //static assert(is(GLmat24 == mat24));
public alias GLmat3     = Matrix!(GLfloat, 3, 3);  static assert(is(GLmat3  == mat3));
public alias GLmat3x2   = Matrix!(GLfloat, 3, 2);  //static assert(is(GLmat32 == mat32));
public alias GLmat3x4   = Matrix!(GLfloat, 3, 4);  //static assert(is(GLmat34 == mat34));
public alias GLmat4     = Matrix!(GLfloat, 4, 4);  static assert(is(GLmat4  == mat4));
public alias GLmat4x2   = Matrix!(GLfloat, 4, 2);  //static assert(is(GLmat42 == mat42));
public alias GLmat4x3   = Matrix!(GLfloat, 4, 3);  //static assert(is(GLmat43 == mat43));

public alias GLdmat2    = Matrix!(GLdouble, 2, 2); //static assert(is(GLdmat2 == mat2d));
public alias GLdmat2x3  = Matrix!(GLdouble, 2, 3); //static assert(is(GLdmat23 == mat23d));
public alias GLdmat2x4  = Matrix!(GLdouble, 2, 4); //static assert(is(GLdmat24 == mat24d));
public alias GLdmat3    = Matrix!(GLdouble, 3, 3); //static assert(is(GLdmat3 == mat3d));
public alias GLdmat3x2  = Matrix!(GLdouble, 3, 2); //static assert(is(GLdmat32 == mat32d));
public alias GLdmat3x4  = Matrix!(GLdouble, 3, 4); //static assert(is(GLdmat34 == mat34d));
public alias GLdmat4    = Matrix!(GLdouble, 4, 4); //static assert(is(GLdmat4 == mat4d));
public alias GLdmat4x2  = Matrix!(GLdouble, 4, 2); //static assert(is(GLdmat42 == mat42d));
public alias GLdmat4x3  = Matrix!(GLdouble, 4, 3); //static assert(is(GLdmat43 == mat43d));

struct GLsampler1D { uint location; }
struct GLsampler2D { uint location; }
struct GLsampler3D { uint location; }
struct GLsamplerCube { uint location; }
struct GLsampler1DShadow { uint location; }
struct GLsampler2DShadow { uint location; }
struct GLsampler1DArray { uint location; }
struct GLsampler2DArray { uint location; }
struct GLsampler1DArrayShadow { uint location; }
struct GLsampler2DArrayShadow { uint location; }
struct GLsampler2DMS { uint location; }
struct GLsampler2DMSArray { uint location; }
struct GLsamplerCubeShadow { uint location; }
struct GLsamplerBuffer { uint location; }
struct GLsampler2DRect { uint location; }
struct GLsampler2DRectShadow { uint location; }
struct GLisampler1D { uint location; }
struct GLisampler2D { uint location; }
struct GLisampler3D { uint location; }
struct GLisamplerCube { uint location; }
struct GLisampler1DArray { uint location; }
struct GLisampler2DArray { uint location; }
struct GLisampler2DMS { uint location; }
struct GLisampler2DMSArray { uint location; }
struct GLisamplerBuffer { uint location; }
struct GLisampler2DRect { uint location; }
struct GLusampler1D { uint location; }
struct GLusampler2D { uint location; }
struct GLusampler3D { uint location; }
struct GLusamplerCube { uint location; }
struct GLusampler1DArray { uint location; }
struct GLusampler2DArray { uint location; }
struct GLusampler2DMS { uint location; }
struct GLusampler2DMSArray { uint location; }
struct GLusamplerBuffer { uint location; }
struct GLusampler2DRect { uint location; }


GLType glTypeOf (T)() {
    static if (is(T == GLfloat)) { return GLType.GL_FLOAT; }
    static if (is(T == GLvec2)) { return GLType.GL_FLOAT_VEC2; }
    static if (is(T == GLvec3)) { return GLType.GL_FLOAT_VEC3; }
    static if (is(T == GLvec4)) { return GLType.GL_FLOAT_VEC4; }
    static if (is(T == GLdouble)) { return GLType.GL_DOUBLE; }
    static if (is(T == GLdvec2)) { return GLType.GL_DOUBLE_VEC2; }
    static if (is(T == GLdvec3)) { return GLType.GL_DOUBLE_VEC3; }
    static if (is(T == GLdvec4)) { return GLType.GL_DOUBLE_VEC4; }
    static if (is(T == GLint)) { return GLType.GL_INT; }
    static if (is(T == GLivec2)) { return GLType.GL_INT_VEC2; }
    static if (is(T == GLivec3)) { return GLType.GL_INT_VEC3; }
    static if (is(T == GLivec4)) { return GLType.GL_INT_VEC4; }
    static if (is(T == GLuint)) { return GLType.GL_UNSIGNED_INT; }
    static if (is(T == GLuvec2)) { return GLType.GL_UNSIGNED_INT_VEC2; }
    static if (is(T == GLuvec3)) { return GLType.GL_UNSIGNED_INT_VEC3; }
    static if (is(T == GLuvec4)) { return GLType.GL_UNSIGNED_INT_VEC4; }
    static if (is(T == GLboolean)) { return GLType.GL_BOOL; }
    static if (is(T == GLbvec2)) { return GLType.GL_BOOL_VEC2; }
    static if (is(T == GLbvec3)) { return GLType.GL_BOOL_VEC3; }
    static if (is(T == GLbvec4)) { return GLType.GL_BOOL_VEC4; }
    static if (is(T == GLmat2)) { return GLType.GL_FLOAT_MAT2; }
    static if (is(T == GLmat3)) { return GLType.GL_FLOAT_MAT3; }
    static if (is(T == GLmat4)) { return GLType.GL_FLOAT_MAT4; }
    static if (is(T == GLmat2x3)) { return GLType.GL_FLOAT_MAT2x3; }
    static if (is(T == GLmat2x4)) { return GLType.GL_FLOAT_MAT2x4; }
    static if (is(T == GLmat3x2)) { return GLType.GL_FLOAT_MAT3x2; }
    static if (is(T == GLmat3x4)) { return GLType.GL_FLOAT_MAT3x4; }
    static if (is(T == GLmat4x2)) { return GLType.GL_FLOAT_MAT4x2; }
    static if (is(T == GLmat4x3)) { return GLType.GL_FLOAT_MAT4x3; }
    static if (is(T == GLdmat2)) { return GLType.GL_DOUBLE_MAT2; }
    static if (is(T == GLdmat3)) { return GLType.GL_DOUBLE_MAT3; }
    static if (is(T == GLdmat4)) { return GLType.GL_DOUBLE_MAT4; }
    static if (is(T == GLdmat2x3)) { return GLType.GL_DOUBLE_MAT2x3; }
    static if (is(T == GLdmat2x4)) { return GLType.GL_DOUBLE_MAT2x4; }
    static if (is(T == GLdmat3x2)) { return GLType.GL_DOUBLE_MAT3x2; }
    static if (is(T == GLdmat3x4)) { return GLType.GL_DOUBLE_MAT3x4; }
    static if (is(T == GLdmat4x2)) { return GLType.GL_DOUBLE_MAT4x2; }
    static if (is(T == GLdmat4x3)) { return GLType.GL_DOUBLE_MAT4x3; }
    static if (is(T == GLsampler1D)) { return GLType.GL_SAMPLER_1D; }
    static if (is(T == GLsampler2D)) { return GLType.GL_SAMPLER_2D; }
    static if (is(T == GLsampler3D)) { return GLType.GL_SAMPLER_3D; }
    static if (is(T == GLsamplerCube)) { return GLType.GL_SAMPLER_CUBE; }
    static if (is(T == GLsampler1DShadow)) { return GLType.GL_SAMPLER_1D_SHADOW; }
    static if (is(T == GLsampler2DShadow)) { return GLType.GL_SAMPLER_2D_SHADOW; }
    static if (is(T == GLsampler1DArray)) { return GLType.GL_SAMPLER_1D_ARRAY; }
    static if (is(T == GLsampler2DArray)) { return GLType.GL_SAMPLER_2D_ARRAY; }
    static if (is(T == GLsampler1DArrayShadow)) { return GLType.GL_SAMPLER_1D_ARRAY_SHADOW; }
    static if (is(T == GLsampler2DArrayShadow)) { return GLType.GL_SAMPLER_2D_ARRAY_SHADOW; }
    static if (is(T == GLsampler2DMS)) { return GLType.GL_SAMPLER_2D_MULTISAMPLE; }
    static if (is(T == GLsampler2DMSArray)) { return GLType.GL_SAMPLER_2D_MULTISAMPLE_ARRAY; }
    static if (is(T == GLsamplerCubeShadow)) { return GLType.GL_SAMPLER_CUBE_SHADOW; }
    static if (is(T == GLsamplerBuffer)) { return GLType.GL_SAMPLER_BUFFER; }
    static if (is(T == GLsampler2DRect)) { return GLType.GL_SAMPLER_2D_RECT; }
    static if (is(T == GLsampler2DRectShadow)) { return GLType.GL_SAMPLER_2D_RECT_SHADOW; }
    static if (is(T == GLisampler1D)) { return GLType.GL_INT_SAMPLER_1D; }
    static if (is(T == GLisampler2D)) { return GLType.GL_INT_SAMPLER_2D; }
    static if (is(T == GLisampler3D)) { return GLType.GL_INT_SAMPLER_3D; }
    static if (is(T == GLisamplerCube)) { return GLType.GL_INT_SAMPLER_CUBE; }
    static if (is(T == GLisampler1DArray)) { return GLType.GL_INT_SAMPLER_1D_ARRAY; }
    static if (is(T == GLisampler2DArray)) { return GLType.GL_INT_SAMPLER_2D_ARRAY; }
    static if (is(T == GLisampler2DMS)) { return GLType.GL_INT_SAMPLER_2D_MULTISAMPLE; }
    static if (is(T == GLisampler2DMSArray)) { return GLType.GL_INT_SAMPLER_2D_MULTISAMPLE_ARRAY; }
    static if (is(T == GLisamplerBuffer)) { return GLType.GL_INT_SAMPLER_BUFFER; }
    static if (is(T == GLisampler2DRect)) { return GLType.GL_INT_SAMPLER_2D_RECT; }
    static if (is(T == GLusampler1D)) { return GLType.GL_UNSIGNED_INT_SAMPLER_1D; }
    static if (is(T == GLusampler2D)) { return GLType.GL_UNSIGNED_INT_SAMPLER_2D; }
    static if (is(T == GLusampler3D)) { return GLType.GL_UNSIGNED_INT_SAMPLER_3D; }
    static if (is(T == GLusamplerCube)) { return GLType.GL_UNSIGNED_INT_SAMPLER_CUBE; }
    static if (is(T == GLusampler1DArray)) { return GLType.GL_UNSIGNED_INT_SAMPLER_1D_ARRAY; }
    static if (is(T == GLusampler2DArray)) { return GLType.GL_UNSIGNED_INT_SAMPLER_2D_ARRAY; }
    static if (is(T == GLusampler2DMS)) { return GLType.GL_UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE; }
    static if (is(T == GLusampler2DMSArray)) { return GLType.GL_UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE_ARRAY; }
    static if (is(T == GLusamplerBuffer)) { return GLType.GL_UNSIGNED_INT_SAMPLER_BUFFER; }
    static if (is(T == GLusampler2DRect)) { return GLType.GL_UNSIGNED_INT_SAMPLER_2D_RECT; }

    import std.format: format;
    assert(0, format("Invalid type: %s", T.stringof));
}

enum GLPrimitive : GLenum {
    GL_POINTS = derelict.opengl3.gl3.GL_POINTS,
    GL_LINES = derelict.opengl3.gl3.GL_LINES,
    GL_LINE_STRIP = derelict.opengl3.gl3.GL_LINE_STRIP,
    GL_LINE_LOOP = derelict.opengl3.gl3.GL_LINE_LOOP,
    GL_TRIANGLES = derelict.opengl3.gl3.GL_TRIANGLES,
    GL_TRIANGLE_STRIP = derelict.opengl3.gl3.GL_TRIANGLE_STRIP,
    GL_TRIANGLE_FAN = derelict.opengl3.gl3.GL_TRIANGLE_FAN,
}
enum GLShaderType : GLenum { 
    VERTEX   = derelict.opengl3.gl3.GL_VERTEX_SHADER, 
    FRAGMENT = derelict.opengl3.gl3.GL_FRAGMENT_SHADER, 
    GEOMETRY = derelict.opengl3.gl3.GL_GEOMETRY_SHADER,
}
enum GLStatus { None = 0x0, Ok = 0x1, Error = 0x3 }

bool ok    (GLStatus status) { return status == GLStatus.Ok;    }
bool error (GLStatus status) { return status == GLStatus.Error; }
bool none  (GLStatus status) { return status == GLStatus.None;  }

//void setOk    (ref GLStatus status, bool ok = true)    { status |= (ok ? GLStatus.Ok : GLStatus.Error);  }
//void setError (ref GLStatus status, bool err = true)   { if (err) status |= GLStatus.Error; }
//void clear    (ref GLStatus status)                    { status = GLStatus.None;   }
