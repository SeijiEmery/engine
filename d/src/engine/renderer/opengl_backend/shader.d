module engine.renderer.opengl_backend.shader;
import engine.utils.maybe;

enum ShaderType { 
    VERTEX, 
    FRAGMENT, 
    GEOMETRY 
}
struct ShaderBuilder {
    Maybe!string[ShaderType] shaders;
    auto ref withVertex   (string vertex)  { shaders[ShaderType.VERTEX] = just(vertex);      return this; }
    auto ref withFragment (string fragment) { shaders[ShaderType.FRAGMENT] = just(fragment); return this; }
    auto ref withGeometry (string geometry) { shaders[ShaderType.GEOMETRY] = just(geometry); return this; }
    Shader build () { return Shader(this); }
}
struct Shader {
    this (ShaderBuilder builder) {

    }
}
