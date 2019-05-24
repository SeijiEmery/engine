use glium;
use glium::uniforms::AsUniformValue;

#[derive(Debug, Copy, Clone, PartialEq, PartialOrd)]
pub struct Color { pub r: f32, pub g: f32, pub b: f32, pub a: f32 }
impl AsUniformValue for Color {
    fn as_uniform_value (&self) -> glium::uniforms::UniformValue {
        return glium::uniforms::UniformValue::Vec4([
            self.r, self.g, self.b, self.a
        ]);
    }
}
