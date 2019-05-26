use crate::renderer;
pub use renderer::*;
use crate::engine_utils::color::{Color};
use glium::{Surface, DrawParameters};
use cgmath::conv::{array4x4};
//#[macro_use]
use crate::glium;

pub struct GliumRenderer {
    display: glium::Display,
    frame: glium::Frame,
    shape_renderer: ShapeRenderer,
}
impl GliumRenderer {
    pub fn new (display: glium::Display) -> GliumRenderer {
        let mut frame = display.draw(); frame.set_finish().unwrap();
        let shape_renderer = ShapeRenderer::new(&display);
        return GliumRenderer { display, shape_renderer, frame }
    }
}
impl Renderer for GliumRenderer {
    fn draw (&mut self, item: RenderItem) {
        match item.primitive {
            //            RenderPrimitive::SolidBox(Color) => println!("unimplemented: render solid box!"),
            //            RenderPrimitive::SolidCircle(Color) => println!("unimplemented: render solid circle!"),
            //            RenderPrimitive::OutlineBox(f32, Color) => println!("unimplemented: render outlined box!"),
            //            RenderPrimitive::OutlineCircle(f32, Color) => println!("unimplemented: render outlined circle!"),
            RenderPrimitive::Sprite(_) => println!("unimplemented: render sprite!"),
            RenderPrimitive::Text(_) => println!("unimplemented: render text!"),
            _ => self.shape_renderer.draw(&mut self.frame, item.transform, item.primitive),
        }
    }
    fn begin_frame (&mut self) {
        let mut frame = self.display.draw();
        frame.clear_all((0.0, 0.0, 0.0, 0.0),0.0, 0);
        self.frame = frame;
    }
    fn end_frame (&mut self) {
        self.frame.set_finish().unwrap();
    }
}

#[derive(Copy, Clone)]
struct Vertex {
    position: [f32; 2],
}
implement_vertex!(Vertex, position);

struct ShapeRenderer {
    quad_vertices: glium::VertexBuffer<Vertex>,
    quad_indices: glium::index::NoIndices,
    shape_shader: glium::Program,
}
impl ShapeRenderer {
    fn new (display: &glium::Display) -> ShapeRenderer {
        let vertices = vec![
            Vertex { position: [ -0.5,  0.5 ] },
            Vertex { position: [ -0.5, -0.5 ] },
            Vertex { position: [  0.5, -0.5 ] },
            Vertex { position: [ -0.5,  0.5 ] },
            Vertex { position: [  0.5, -0.5 ] },
            Vertex { position: [  0.5,  0.5 ] },
        ];
        let display = display.clone();
        let quad_vertices = glium::VertexBuffer::new(&display, &vertices).unwrap();
        let quad_indices = glium::index::NoIndices(glium::index::PrimitiveType::TrianglesList);

        let shape_vertex_shader = r#"
            #version 410
            in vec2 position;
            out vec2 local_coords;
            uniform mat4 transform;
            void main () {
                gl_Position = transform * vec4(position, 0.0, 1.0);
                local_coords = position * 2;
            }
        "#;
        let shape_fragment_shader = r#"
            #version 410
            out vec4        out_color;
            in vec2         local_coords;
            uniform vec4    color;
            uniform float   outline_width;

            subroutine void shape_shader();
            subroutine uniform shape_shader shading_mode;

            subroutine(shape_shader) void draw_solid_box () {
                out_color = color;
            }
            subroutine(shape_shader) void draw_solid_circle () {
                if (dot(local_coords, local_coords) < 1.0) {
                    out_color = color;
                } else {
                    discard;
                }
            }
            subroutine(shape_shader) void draw_outline_box () {
                vec2 from_center = abs(local_coords);
                if (max(from_center.x, from_center.y) >= 1.0 - outline_width) {
                    out_color = color;
                } else {
                    discard;
                }
            }
            subroutine(shape_shader) void draw_outline_circle () {
                float from_center = dot(local_coords, local_coords);
                if (from_center <= 1.0 && from_center >= 1.0 - outline_width) {
                    out_color = color;
                } else {
                    discard;
                }
            }
            void main () {
                shading_mode();
            }
        "#;
        let shape_shader = glium::Program::from_source(
            &display, shape_vertex_shader, shape_fragment_shader, None,
        ).unwrap();
        return ShapeRenderer { quad_vertices, quad_indices, shape_shader };
    }
    fn draw_with_params (&self, frame: &mut glium::Frame, transform: Mat4, mode: &str, outline: f32, color: Color) {
        let uniforms = uniform! [
            transform: array4x4(transform),
            shading_mode: (mode, glium::program::ShaderStage::Fragment),
            outline_width: outline,
            color: color
        ];
        use glium::draw_parameters::{DrawParameters, Depth, DepthTest, DepthClamp, Blend};
        frame.draw(
            &self.quad_vertices,
            self.quad_indices,
            &self.shape_shader, &uniforms,
            &DrawParameters {
                depth: Depth {
                    test: DepthTest::IfMore,
                    write: true,
                    range: (0.0, 1.),
                    clamp: DepthClamp::Clamp
                },
                blend: Blend::alpha_blending(),
                .. Default::default()
            });
    }
    fn draw (&self, frame: &mut glium::Frame, transform: Mat4, primitive: RenderPrimitive) {
        match primitive {
            RenderPrimitive::SolidBox(color) => self.draw_with_params(frame, transform, "draw_solid_box", 0.0, color),
            RenderPrimitive::SolidCircle(color) => self.draw_with_params(frame, transform, "draw_solid_circle", 0.0, color),
            RenderPrimitive::OutlineBox(width, color) => self.draw_with_params(frame, transform, "draw_outline_box", width, color),
            RenderPrimitive::OutlineCircle(width, color) => self.draw_with_params(frame, transform, "draw_outline_circle", width, color),
            _ => ()
        }
    }
}
