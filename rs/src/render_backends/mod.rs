pub mod renderer;
pub use renderer::{Renderer, RenderItem, RenderPrimitive};
mod glium_renderer;
use glium_renderer::{GliumRenderer};
//pub fn make_glium_renderer<R> (display: glium::Display) -> R where R: Renderer {
//pub fn make_glium_renderer (display: glium::Display) -> Renderer {
pub fn make_glium_renderer (display: glium::Display) -> GliumRenderer {
    return GliumRenderer::new(display);
}
