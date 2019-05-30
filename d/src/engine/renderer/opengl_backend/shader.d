module engine.renderer.opengl_backend.shader;
import engine.renderer.opengl_backend.glutils;
import engine.renderer.opengl_backend.enums;
import engine.renderer.opengl_backend.context;
import engine.renderer.opengl_backend.exceptions;
import engine.utils.maybe;
import derelict.opengl3.gl3;
import std.stdio: writefln;
import std.exception: enforce;
import std.format: format;
import std.string: toStringz, lineSplitter;
import std.array: join;

enum ShaderType { 
    VERTEX, 
    FRAGMENT, 
    GEOMETRY 
}
enum ShaderStatus {
    Empty            = 0,
    PendingRecompile = 1,
    Ready            = 2,
    CompileError     = 4,
    LinkError        = 5,
    ValidateError    = 6,
}
bool ready       (ShaderStatus status) @safe { return status == ShaderStatus.Ready; }
bool recompiling (ShaderStatus status) @safe { return status == ShaderStatus.PendingRecompile; }
bool ok          (ShaderStatus status) @safe { return status.ready || status.recompiling; }
bool error       (ShaderStatus status) @safe { return status >= ShaderStatus.CompileError; }
bool empty       (ShaderStatus status) @safe { return status == ShaderStatus.Empty; }

/*
 * Global data describing what shader is currently bound.
 * functions should only be called from the graphics thread
 */

private __gshared uint g_boundProgram = 0;

struct ShaderBuilder {
    Maybe!string[ShaderType] shaders;
    auto ref withVertex   (string vertex)   { shaders[ShaderType.VERTEX]   = just(vertex);   return this; }
    auto ref withFragment (string fragment) { shaders[ShaderType.FRAGMENT] = just(fragment); return this; }
    auto ref withGeometry (string geometry) { shaders[ShaderType.GEOMETRY] = just(geometry); return this; }
    Shader build () { return Shader(this); }
}
struct Shader {    
    this (ShaderBuilder builder) {
        loadSource(builder);
    }
    void loadSource (ShaderBuilder builder) {
        try {
            m_program.createProgram();
            setStatus(ShaderStatus.PendingRecompile);
            loadProgramFromSource(this, m_program, builder.shaders);
            enforce(bind());
            loadUniforms();
            m_error = null;
            setStatus(ShaderStatus.Ready);
            return this;
        } catch (ShaderCompilationException exception) {
            m_error = exception;
            setStatus(ShaderStatus.CompileError);
        } catch (ShaderLinkException exception) {
            m_error = exception;
            setStatus(ShaderStatus.LinkError);
        } catch (ShaderValidationException exception) {
            m_error = exception;
            setStatus(ShaderStatus.ValidateError);
        } finally {
            writefln("Finished loadShader: %s", this);
        }
    }

    /* Get shader program (may return zero). To not return zero, call bind() first. */
    public uint program () @safe { return m_program; }
    
    /* Get current shader status */
    public ShaderStatus status () @safe
        in { assert(m_status.empty == (m_program == 0), format("%s, %s", m_status, m_program)); }
        body { return m_status; }

    private void setStatus (ShaderStatus status) @safe
        in { 
            assert((status.empty) == (m_program == 0));
            assert((status.error) == (m_error !is null));
        }
        body { m_status = status; }
    
    /* Get current shader error message. Returns null if !status.error */
    public Exception getError () @safe 
        in { assert((m_error !is null) == this.m_status.error); }
        body { return m_error; }

    /* Unbind this / all shaders. Call this before / after executing any non-shader.d code */
    public static void unbind () { 
        g_boundProgram = 0;
        gl.BindProgram(0);
    }

    /* Binds this shader program - necessary before most calls */
    public bool bind () {
        gl.BindProgram(g_boundProgram = program);
        m_subroutines.writeState(program);
        return program != 0;
    }

    /* Lazily bind this program */
    public bool lazyBind () {
        if (program != g_boundProgram) {
            return bind();
        }
        return program != 0;
    }

    /* Used within certain functions to maintain API correctness without calling bind() everywhere */
    private void enforceBound () {
        //static if (REV3_CHECK_OPENGL_OBJECT_BINDINGS) {
        //    enforce(g_boundShader == this,
        //        new ShaderOperationException(this, "Shader was not bound!"));
        //}
    }

    private static uint[] g_tempArray1;

    /* Load shader from shader sources */
    public Shader loadSource (const(string[ShaderType]) sources, ref uint[] tempArray = g_tempArray1) {
        import std.stdio: writefln;
        writefln("Loading %s with sources", this);
        foreach (type, source; sources) {
            import std.algorithm: map;
            import std.string: lineSplitter, stripLeft;
            import std.array: join;
            writefln("\t%s:\n\t\t%s", type, source.lineSplitter.join("\n\t\t"));
        }

        try {
            m_program.createProgram();
            setStatus(ShaderStatus.PendingRecompile);
            loadProgramFromSource(this, m_program, sources, tempArray);
            enforce(bind());
            loadUniforms();
            m_error = null;
            setStatus(ShaderStatus.Ready);
            return this;
        } catch (ShaderCompilationException exception) {
            m_error = exception;
            setStatus(ShaderStatus.CompileError);
        } catch (ShaderLinkException exception) {
            m_error = exception;
            setStatus(ShaderStatus.LinkError);
        }/+ catch (ShaderValidationException exception) {
            m_error = exception;
            setStatus(ShaderStatus.ValidateError);
        }+/ finally {
            writefln("Finished loadShader: %s", this);
        }
        return this;
    }
    public Shader loadBinary (const(ubyte[]) data) {
        try {
            m_program.createProgram();
            setStatus(ShaderStatus.PendingRecompile);
            loadProgramFromBinary(this, m_program, data);
            enforce(bind());
            loadUniforms();
            setStatus(ShaderStatus.Ready);
        }/+ catch (ShaderValidationException exception) {
            m_error = exception;
            setStatus(ShaderStatus.ValidateError);
        }+/ finally {
            import std.stdio: writefln;
            writefln("Finished loadBinary: %s", this);
        }
        return this;
    }
    public ubyte[] readBinary (ubyte[] data) {
        enforceBound;
        enforce(status.ok,
            new ShaderOperationException(
                this, "Cannot read status of non-loaded shader program!"));
        return readProgramBinary(program);
    }
    private void loadUniforms () {
        import std.stdio: writefln;
        writefln("Loading shader uniforms %s", this);

        GLUniformInfo[] uniforms;
        GLUniformBlockInfo[] uniformBlocks;
        int[] tempValues;
        uint[] tempIndices;
        char[] tempBuffer;

        getActiveUniforms(program, uniforms, tempValues, tempIndices, tempBuffer);
        glGetActiveUniformBlocks(program, uniformBlocks, tempBuffer);

        writefln("%d uniforms:", uniforms.length);
        foreach (uniform; uniforms) {
            writefln("\t%s", uniform);
        }
        writefln("%d uniform blocks:", uniformBlocks.length);
        foreach (uniformBlock; uniformBlocks) {
            writefln("\t%s", uniformBlock);
        }
        m_subroutines.loadSubroutineInfo(program);
        m_subroutines.writeState(program);

        static assert(glTypeOf!int == GLType.GL_INT);
    }
    struct SubroutineManager {
        struct Stage {
            ShaderType shaderType;
            uint[]       state;
            Uniform[]    uniforms;

            private void writeState () {
                gl.UniformSubroutinesuiv(cast(GLenum)shaderType, cast(int)state.length, state.ptr);
            }
            private bool maybeSetSubroutine (string name, string value) {
                foreach (uniform; uniforms) {
                    if (uniform.name == name && value in uniform.values) {
                        state[uniform.index] = uniform.values[value];
                        writeState();
                        return true;
                    }
                }
                return false;
            }
        }
        struct Uniform {
            string      name;
            int         index;
            int[string] values;
        }
        Stage[] stages;
        char[]  name;
        int[]   indices;

        private void loadStage (uint program, ShaderType shaderType) {
            import std.stdio: writefln;

            int numUniforms, maxlen;
            gl.GetProgramStageiv(program, cast(GLenum)shaderType, GL_ACTIVE_SUBROUTINE_UNIFORM_LOCATIONS, &numUniforms);
            writefln("\tStage %s has %d uniforms", shaderType, numUniforms);
            if (numUniforms <= 0) return;
            stages ~= Stage(shaderType, new uint[numUniforms], new Uniform[numUniforms]);
            auto stage = &stages[$-1];

            gl.GetProgramStageiv(program, cast(GLenum)shaderType, GL_ACTIVE_SUBROUTINE_MAX_LENGTH, &maxlen);
            assert(maxlen > 0);
            name.length = maxlen;
            writefln("\t\tmax name length = %d", maxlen);

            foreach (i, ref uniform; stage.uniforms) {
                int length; gl.GetActiveSubroutineUniformName(
                    program, shaderType, cast(int)i, maxlen, &length, name.ptr);
                uniform.name = cast(string)name[0 .. length].dup;
                uniform.index = cast(int)i;
                writefln("\t\tsubroutine uniform %d '%s'", uniform.index, uniform.name);

                int numCompat;
                gl.GetActiveSubroutineUniformiv(
                    program, shaderType, cast(int)i, GL_NUM_COMPATIBLE_SUBROUTINES, &numCompat);

                indices.length = numCompat;
                gl.GetActiveSubroutineUniformiv(
                    program, shaderType, cast(int)i, GL_COMPATIBLE_SUBROUTINES, indices.ptr);

                foreach (index; indices) {
                    gl.GetActiveSubroutineName(
                        program, cast(GLenum)shaderType, index, maxlen, &length, name.ptr);
                    uniform.values[cast(string)name[0 .. length].dup] = cast(int)index;
                    writefln("\t\t\tsubroutine value %d '%s'", cast(int)index, cast(string)name[0 .. length]);
                }
            }
        }

        public void writeState (uint program) {
            foreach (ref stage; stages) {
                stage.writeState();
            }
        }

        public void loadSubroutineInfo (uint program) {
            stages.length = 0;
            loadStage(program, ShaderType.VERTEX);
            loadStage(program, ShaderType.FRAGMENT);
            loadStage(program, ShaderType.GEOMETRY);
            name.length = 0;
            indices.length = 0;
        }
        public bool setSubroutine (string name, string value) {
            bool setAny = false;
            foreach (ref stage; stages) {
                setAny |= stage.maybeSetSubroutine(name, value);
            }
            return setAny;
        }
        public void clear () {
            stages.length = 0;
        }
    }
    SubroutineManager m_subroutines;

    public Shader maybeSetUniform (T)(string name, T value) {
        if (lazyBind()) { setUniform(name, value); } return this;
    }
    public Shader maybeSetSubroutine (string name, string value) {
        if (lazyBind()) { setSubroutine(name, value); } return this;
    }
    public Shader setUniform (T)(string name, T value) {
        enforceBound;
        foreach (ref uniform; m_uniforms) {
            if (uniform.name == name) {
                static if (REV3_ENABLE_TYPECHECKED_UNIFORMS) {
                    //enforce(uniform.checkType!T,
                    //    new ShaderInvalidUniformTypeException(
                    //        this, name, T));
                }
                gl.SetUniform(uniform.location, value);
                return this;
            }
        }
        int location = gl.GetUniformLocation(program, name.toStringz);
        enforce(location != -1,
            new ShaderInvalidUniformException(this, name));

        m_uniforms ~= Uniform(name, location);
        gl.SetUniform(location, value);
        return this;
    }
    public Shader setSubroutine (string name, string value) {
        enforce(m_subroutines.setSubroutine(name, value),
            new ShaderInvalidSubroutineValueException(this, name, value));
        return this;
    }

    /* Get a list of all shader uniforms */
    public const(Uniform)[] getUniforms () const {
        return m_uniforms;
    }

    /* Get a list of all shader subroutines */
    //public const(Subroutine)[] getSubroutines () const {
    //    return m_subroutines;
    //}

    /* Clear shader state, resetting all values; will reload shader from source if used afterwards */
    public void clear () {
        m_program.deleteProgram();
        m_error = null;
        setStatus(ShaderStatus.Empty);
        m_uniforms.length = 0;
        m_subroutines.clear();
    }

    struct Uniform {
        string          name;
        uint            location = 0;
    }
    private Uniform* getUniform (string name) {
        foreach (ref uniform; m_uniforms) {
            if (uniform.name == name) {
                return &uniform;
            }
        }
        uint location = gl.GetUniformLocation(m_program, name.toStringz);
        m_uniforms ~= Uniform(name, location);
        return &m_uniforms[$-1];
    }

    private uint            m_program = 0;
    private Uniform[]       m_uniforms;
    private ShaderStatus    m_status;
    private Exception       m_error = null;    
}

/*
 *  Implementation details
 */

private void createProgram (ref uint object) {
    if (object == 0) { object = gl.CreateProgram(); }
}
private void createShader (ref uint object, GLenum shaderType) {
    if (object == 0) { object = gl.CreateShader(shaderType); }
} 

private void deleteProgram (ref uint object) {
    if (object != 0) { gl.DeleteProgram(object); object = 0; }
}
private void deleteShader (ref uint object) {
    if (object != 0) { gl.DeleteShader(object); object = 0; }
}

private int getProgramiv (uint object, GLenum pname) {
    int value; gl.GetProgramiv(object, pname, &value); return value;
}
private int getShaderiv (uint object, GLenum pname) {
    int value; gl.GetShaderiv(object, pname, &value); return value;
}

private void shaderSource (uint shader, string src) {
    const(char)* source = src.toStringz;
    int          length = cast(int)src.length;
    gl.ShaderSource(shader, 1, &source, &length);
}
private bool compileShader (uint shader) {
    gl.CompileShader(shader);
    return getShaderiv(shader, GL_COMPILE_STATUS) == GL_TRUE;
}
private bool linkProgram (uint program) {
    gl.LinkProgram(program);
    return getProgramiv(program, GL_LINK_STATUS) == GL_TRUE;
}
private bool validateProgram (uint program) {
    gl.ValidateProgram(program);
    return getProgramiv(program, GL_VALIDATE_STATUS) == GL_TRUE;
}

private string getShaderInfoLog (uint shader) {
    int length = getShaderiv(shader, GL_INFO_LOG_LENGTH);
    if (length <= 0) return "[Empty Log]";

    auto log = new char[length];
    gl.GetShaderInfoLog(shader, length, &length, &log[0]);
    return cast(string)log[0 .. length];
}
private string getProgramInfoLog (uint program) {
    int length = getProgramiv(program, GL_INFO_LOG_LENGTH);
    if (length <= 0) return "[Empty Log]";

    auto log = new char[length];
    gl.GetProgramInfoLog(program, length, &length, &log[0]);
    return cast(string)log[0 .. length];
}

private ubyte[] readProgramBinary (uint program) {
    int programSize = getProgramiv(program, GL_PROGRAM_BINARY_LENGTH);
    if (programSize <= 0) return null;

    ubyte[] data = new ubyte[GLenum.sizeof + programSize];
    GLenum* format = cast(GLenum*)(&data[0]);
    ubyte*  ptr    = &data[0] + GLenum.sizeof;
    int length;

    gl.GetProgramBinary(program, programSize, &length, format, cast(void*)ptr);
    return data[0 .. (GLenum.sizeof + length)];
}
private void setProgramBinary (uint program, const(ubyte[]) data) {
    GLenum  format = *(cast(GLenum*)(&data[0]));
    const(ubyte)* ptr = &data[0] + GLenum.sizeof;
    int length     = cast(int)data.length;

    gl.ProgramBinary(program, format, cast(void*)ptr, length);
}

private void loadProgramFromSource (
    Shader shaderObject,
    ref uint program, 
    const(string[ShaderType]) sources,
    ref uint[] tempShaderList       // temp array - pass this in so we can recycle and avoid unecessary allocations
) {
    uint shader;
    try {
        tempShaderList.length = 0;
        program.createProgram();

        foreach (shaderType, src; sources) {
            shader = gl.CreateShader(cast(GLenum)shaderType);
            shader.shaderSource(src);

            enforce(shader.compileShader(),
                new ShaderCompilationException(
                    shaderObject, shaderType, src, shader.getShaderInfoLog));

            gl.AttachShader(program, shader);
            tempShaderList ~= shader;
            shader = 0;
        }

        enforce(program.linkProgram(),
            new ShaderLinkException(
                shaderObject, program.getProgramInfoLog));

        //enforce(program.validateProgram(),
        //    new ShaderValidationException(
        //        shaderObject, program.getProgramInfoLog));
    } finally {
        if (shader != 0) {
            gl.DeleteShader(shader);
        }
        foreach (_shader; tempShaderList) {
            gl.DetachShader(program, _shader);
            gl.DeleteShader(_shader);
        }
    }
}

private void loadProgramFromBinary (
    Shader shaderObject,
    ref uint program,
    const(ubyte[]) data
) {
    program.createProgram();
    program.setProgramBinary(data);

    //enforce(program.validateProgram(),
    //    new ShaderValidationException(
    //        shaderObject, program.getProgramInfoLog));
}

struct ShaderVertexAttribute {
    string name;
    GLuint index;
    GLenum  type;
    int    count;
}
void getActiveAttributes (
    uint program, 
    ref ShaderVertexAttribute[] attribs,
    ref char[] tempBuffer
) {
    int count  = getProgramiv(program, GL_ACTIVE_ATTRIBUTES);
    int length = getProgramiv(program, GL_ACTIVE_ATTRIBUTE_MAX_LENGTH);

    attribs.length = count;
    tempBuffer.length  = length;

    foreach (i, ref attrib; attribs) {
        gl.GetActiveAttrib(program, attrib.index = cast(uint)i,
            cast(int)tempBuffer.length, &length, &attrib.count, &attrib.type, &tempBuffer[0]);
        attrib.name = cast(string)tempBuffer[0 .. length];
    }
}

struct GLUniformInfo {
    string name;
    GLuint index;
    GLType type;
    size_t arrayLength;
    short  uniformBlockIndex;
    short  uniformBlockOffset;
    short  arrayStride;
    short  matrixStride;
    bool   isRowMajor;
    int    atomicCounterBufferIndex;
}
void getActiveUniforms (
    uint program,
    ref GLUniformInfo[] uniforms,
    ref int[]  tempValues,
    ref uint[] tempIndices,
    ref char[] tempBuffer
) {
    int count  = getProgramiv(program, GL_ACTIVE_UNIFORMS);
    int length = getProgramiv(program, GL_ACTIVE_UNIFORM_MAX_LENGTH);

    uniforms.length    = count;
    tempValues.length  = count;
    tempIndices.length = count;
    tempBuffer.length = length;
    
    /* Fetch uniform names */
    foreach (i, ref x; tempIndices) { x = cast(int)i; }
    gl.GetActiveUniformsiv(program, count, &tempIndices[0], GL_UNIFORM_NAME_LENGTH, &tempValues[0]);
    foreach (i, ref x; tempValues) {
        uniforms[i].index = cast(int)i;
        gl.GetActiveUniformName(program, cast(int)i, cast(int)tempBuffer.length, &length, &tempBuffer[0]);
        uniforms[i].name = cast(string)tempBuffer[0 .. length].dup;
    }

    /* Fetch all other fields */
    void loadField (T, string field)(GLenum pname) {
        gl.GetActiveUniformsiv(program, count, &tempIndices[0], pname, &tempValues[0]);
        foreach (i, ref x; tempValues) { mixin("uniforms[i]."~field~" = cast(T)x;"); }
    }
    loadField!(GLType, "type")(GL_UNIFORM_TYPE);
    loadField!(size_t, "arrayLength")(GL_UNIFORM_SIZE);
    loadField!(short,  "uniformBlockIndex")(GL_UNIFORM_BLOCK_INDEX);
    loadField!(short,  "uniformBlockOffset")(GL_UNIFORM_OFFSET);
    loadField!(short,  "arrayStride")(GL_UNIFORM_ARRAY_STRIDE);
    loadField!(short,  "matrixStride")(GL_UNIFORM_MATRIX_STRIDE);
    loadField!(bool,   "isRowMajor")(GL_UNIFORM_IS_ROW_MAJOR);
    //loadField!(int,    "atomicCounterBufferIndex")(GL_UNIFORM_ATOMIC_COUNTER_BUFFER_INDEX);
}

struct GLUniformBlockInfo {
    string  name;
    int     index;
    int     size;
    int[]   uniformIndices;
    uint    shaderRefBitmask = 0;

    public int shaderIndex (GLenum type) {
        switch (type) {
            case GL_VERTEX_SHADER:   return 0;
            case GL_FRAGMENT_SHADER: return 1;
            case GL_GEOMETRY_SHADER: return 2;
            default: assert(0, format("Invalid shader type: %d", type));
        }
    }
    bool referencedBy (GLenum shaderType) {
        return (shaderRefBitmask & (1 << shaderIndex(shaderType))) != 0;
    }
}
void glGetActiveUniformBlocks (uint program, ref GLUniformBlockInfo[] blocks, ref char[] tempBuffer) {
    int count = getProgramiv(program, GL_ACTIVE_UNIFORM_BLOCKS);
    blocks.length = count;

    foreach (i, ref block; blocks) {
        block.index = cast(int)i;

        int length = 0;
        gl.GetActiveUniformBlockiv(program, cast(int)i, GL_UNIFORM_BLOCK_NAME_LENGTH, &length);

        tempBuffer.length = length;
        gl.GetActiveUniformBlockName(program, cast(int)i, length, &length, &tempBuffer[0]);
        block.name = cast(string)tempBuffer[0 .. length];

        gl.GetActiveUniformBlockiv(program, cast(int)i, GL_UNIFORM_BLOCK_DATA_SIZE, &block.size);
        gl.GetActiveUniformBlockiv(program, cast(int)i, GL_UNIFORM_BLOCK_ACTIVE_UNIFORMS, &count);
        block.uniformIndices = new int[count];
        gl.GetActiveUniformBlockiv(program, cast(int)i, GL_UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES, &block.uniformIndices[0]);

        int v;
        block.shaderRefBitmask = 0;
        void getRefInfo (string name)() {
            gl.GetActiveUniformBlockiv(program, cast(int)i, mixin("GL_UNIFORM_BLOCK_REFERENCED_BY_"~name), &v);
            block.shaderRefBitmask |= (1 << block.shaderIndex(mixin("GL_"~name)));
        }
        getRefInfo!"VERTEX_SHADER";
        getRefInfo!"FRAGMENT_SHADER";
        getRefInfo!"GEOMETRY_SHADER";

        //static if (openglVersion >= 40) {
        //    getRefInfo!"TESS_CONTROL_SHADER";
        //    getRefInfo!"TESS_EVALUATION_SHADER";
        //}
        //static if (openglVersion >= 43) {
        //    getRefInfo!"COMPUTE_SHADER";
        //}
    }
}



// Root class for all exceptions thrown by Shader
class ShaderException : GLException {
    public const Shader shader;

    this (Shader shader, string message, string file = __FILE__, ulong line = __LINE__) {
        this.shader = shader;
        super(message, file, line);
    }
}
// Base class for any kind of loading exception (ie. while calling loadSource() or loadBinary()),
// which usually signals a compile / link error or, in the case of loadBinary(), data corruption.
class ShaderLoadException : ShaderException {
    this (Shader shader, string message, string file = __FILE__, ulong line = __LINE__) {
        super(shader, message, file, line);
    }
}
// Thrown by Shader.loadSource() while compiling a shader object; signals an error in
// a particular shader's source code.
class ShaderCompilationException : ShaderLoadException {
    public const(ShaderType) shaderType;
    public const(string)       source;
    public const(string)       errorMsg;

    this (Shader shader, ShaderType shaderType, string source, string error, string file = __FILE__, ulong line = __LINE__) {
        this.shaderType = shaderType;
        this.source     = source;
        this.errorMsg   = error;
        super(shader, 
            format("Error compiling shader %s (%s):\n\t%s\nfrom source code:\n\t%s\n",
                shader, shaderType, error.lineSplitter.join("\n\t"), source.lineSplitter.join("\n\t")),
            file, line);
    }
}
// Thrown by Shader.loadSource() while linking the program object; signals an error in one
// of the shader's source code (note: somewhat less helpful...)
class ShaderLinkException : ShaderLoadException {
    public const(string)     errorMsg;

    this (Shader shader, string error, string file = __FILE__, ulong line = __LINE__) {
        this.errorMsg = error;
        super(shader, format("Error linking shader %s:\n\t%s\n",
            shader, error.lineSplitter.join("\n\t")),
        file, line);
    }
}
// Thrown by Shader.loadSource() or Shader.loadBinary().
// For the latter, this probably means that the binary data was wrong / corrupt;
// for the former, it just means that something wrong happened and the shader is not ok
class ShaderValidationException : ShaderLoadException {
    public const(string)     errorMsg;

    this (Shader shader, string error, string file = __FILE__, ulong line = __LINE__) {
        this.errorMsg = error;
        super(shader, format("Error validating shader %s:\n\t%s\n",
            shader, error.lineSplitter.join("\n\t")),
        file, line);
    }
}
// Base class for all exceptions that were the user's fault.
class ShaderRuntimeException : ShaderException {
    this (Shader shader, string error, string file = __FILE__, ulong line = __LINE__) {
        super(shader, error, file, line);
    }
}
// Thrown when the shader's API was broken: the shader was not bound before calling XYZ, etc. 
class ShaderOperationException : ShaderRuntimeException {
    this (Shader shader, string error, string file = __FILE__, ulong line = __LINE__) {
        super(shader, error, file, line);
    }
}
// Thrown when the user attempted to write to an invalid shader uniform.
class ShaderInvalidUniformException : ShaderRuntimeException {
    public const(string) uniform;

    this (Shader shader, string uniform, string file = __FILE__, ulong line = __LINE__) {
        this.uniform = uniform;
        super(shader, format("Missing uniform '%s' in shader %s", uniform, shader), file, line);
    }
}
// Thrown when the user attempted to write a value of the wrong type to a shader uniform (name was correct).
class ShaderInvalidUniformTypeException : ShaderRuntimeException {
    public const(string) uniform;
    public const(string) type;

    this (Shader shader, string uniform, string type, string file = __FILE__, ulong line = __LINE__) {
        this.uniform = uniform;
        this.type = type;
        super(shader, format("Invalid type '%s' for uniform '%s' in shader %s", type, uniform, shader), file, line);
    }
}
// Thrown when the user attempted to set the value of a nonexistent shader subroutine.
class ShaderInvalidSubroutineException : ShaderRuntimeException {
    public const(string) subroutine;

    this (Shader shader, string subroutine, string file = __FILE__, ulong line = __LINE__) {
        this.subroutine = subroutine;
        super(shader, format("Missing subroutine '%s' in shader %s", subroutine, shader), file, line);
    }
}
// Thrown when the user attempted to set an invalid value to an existing shader subroutine.
class ShaderInvalidSubroutineValueException : ShaderRuntimeException {
    public const(string) subroutine;
    public const(string) value;

    this (Shader shader, string subroutine, string value, string file = __FILE__, ulong line = __LINE__) {
        this.subroutine = subroutine;
        this.value = value;
        super(shader, format("Invalid value '%s' for subroutine '%s' in shader %s", value, subroutine, shader), file, line);
    }
}
