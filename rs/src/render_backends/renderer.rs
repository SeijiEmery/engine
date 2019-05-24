pub use crate::engine_utils::*;
pub use cgmath::Matrix4;
pub use std::rc::Rc;
pub use std::cell::RefCell;

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
    fn begin_frame
    (&mut self);
    fn end_frame (&mut self);
}
pub type RendererBackend = Rc<RefCell<Renderer>>;
//impl RendererBackend {
//    pub fn get_renderer (renderer: &mut RendererBackend) -> &mut Renderer {
//        let r = &mut *renderer.borrow_mut();
//        r
//    }
//}


impl Renderer for RendererBackend {
    fn draw (&mut self, item: RenderItem) { (&mut *self.borrow_mut()).draw(item); }
    fn begin_frame (&mut self) { (&mut *self.borrow_mut()).begin_frame(); }
    fn end_frame (&mut self) { (&mut *self.borrow_mut()).end_frame(); }
}