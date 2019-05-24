use glium;
use glium::uniforms::AsUniformValue;

pub struct Color { r: f32, g: f32, b: f32, a: f32 }
impl AsUniformValue for Color {
    fn as_uniform_value (&self) -> glium::uniforms::UniformValue {
        return glium::uniforms::UniformValue::Vec4([
            self.r, self.g, self.b, self.a
        ]);
    }
}
