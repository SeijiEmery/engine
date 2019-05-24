pub use crate::engine_utils::*;
pub use cgmath::Matrix4;

pub struct SpriteRef;
pub enum RenderPrimitive {
    SolidBox(Color),
    SolidCircle(Color),
    OutlineBox(f32, Color),
    OutlineCircle(f32, Color),
    Sprite(SpriteRef),
    Text(String)
}
pub struct RenderItem {
    pub primitive: RenderPrimitive,
    pub transform: Mat4,
}
pub trait Renderer {
    fn draw (&mut self, item: RenderItem);
    fn begin_frame (&mut self);
    fn end_frame (&mut self);
}
