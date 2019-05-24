pub mod color;
pub use color::{Color};
use cgmath::{Matrix4, Vector4, Vector3, Vector2};

pub type Mat4 = Matrix4<f32>;
pub type Vec4 = Vector4<f32>;
pub type Vec3 = Vector3<f32>;
pub type Vec2 = Vector2<f32>;
pub type Scalar = f32;
