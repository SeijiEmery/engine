use crate::renderer;
pub use renderer::*;
use crate::engine_utils::color::{Color};
use glium::{Surface};
use cgmath::conv::{array4x4};
//#[macro_use]
use crate::glium;

pub struct GliumRenderer {
    display: glium::Display,
    frame: glium::Frame,
    shape_renderer: ShapeRenderer,
    render_list: Vec<RenderItem>,
}
impl GliumRenderer {
    pub fn new (display: glium::Display) -> GliumRenderer {
        let mut frame = display.draw(); frame.set_finish().unwrap();
        let shape_renderer = ShapeRenderer::new(&display);
        let render_list = Vec::<RenderItem>::new();
        return GliumRenderer { display, shape_renderer, frame, render_list }
    }
}
impl GliumRenderer {
    fn draw_items (&mut self) {
        // sort by depth
        use std::cmp::Ord;


        self.render_list.sort_by(|a, b| a.depth.partial_cmp(&b.depth).unwrap());

        // draw opaque items first, then transparent

        // fuck it
        for item in &self.render_list {
            if !item.transparent {
                self.shape_renderer.draw(&mut self.frame, &item);
            }
        }
        for item in &self.render_list {
            if item.transparent {
                self.shape_renderer.draw(&mut self.frame, &item);
            }
        }

//        let (transparent, opaque) : (&Vec<RenderItem>, &Vec<RenderItem>)
//            = self.render_list.into_iter().partition(|item| item.transparent);
//        for item in opaque {
//            self.shape_renderer.draw(&mut self.frame, &item);
//        }
//        for item in transparent {
//            self.shape_renderer.draw(&mut self.frame, &item);
//        }
    }
}
impl Renderer for GliumRenderer {
    fn draw (&mut self, item: RenderItem) {
        self.render_list.push(item);
    }
    fn begin_frame (&mut self) {
        let mut frame = self.display.draw();
        frame.clear_all((0.0, 0.0, 0.0, 0.0),0.0, 0);
        self.render_list.clear();
        self.frame = frame;
    }
    fn end_frame (&mut self) {
        self.draw_items();
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
    render_items: Vec<RenderItem>,
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

            subroutine void draw_function();
            subroutine uniform draw_function draw_primitive;

            subroutine(draw_function) void draw_solid_box () {
                out_color = vec4(color.rgb * color.a, color.a);
            }
            subroutine(draw_function) void draw_solid_circle () {
                if (dot(local_coords, local_coords) < 1.0) {
                    out_color = vec4(color.rgb * color.a, color.a);
                } else {
                    discard;
                }
            }
            subroutine(draw_function) void draw_outline_box () {
                vec2 from_center = abs(local_coords);
                if (max(from_center.x, from_center.y) >= 1.0 - outline_width) {
                    out_color = vec4(color.rgb * color.a, color.a);
                } else {
                    discard;
                }
            }
            subroutine(draw_function) void draw_outline_circle () {
                float from_center = dot(local_coords, local_coords);
                if (from_center <= 1.0 && from_center >= 1.0 - outline_width) {
                    out_color = vec4(color.rgb * color.a, color.a);
                } else {
                    discard;
                }
            }
            void main () {
                draw_primitive();
            }
        "#;
        let shape_shader = glium::Program::from_source(
            &display, shape_vertex_shader, shape_fragment_shader, None,
        ).unwrap();
        let render_items = Vec::<RenderItem>::new();
        return ShapeRenderer { quad_vertices, quad_indices, shape_shader, render_items };
    }
    fn draw_with_params (&self, frame: &mut glium::Frame, transform: &Mat4, draw_function: &str, outline: f32, color: Color, transparent: bool) {
        let uniforms = uniform! [
            transform: array4x4(*transform),
            draw_primitive: (draw_function, glium::program::ShaderStage::Fragment),
            outline_width: outline,
            color: color
        ];
        use glium::draw_parameters::{DrawParameters, Depth, DepthTest, DepthClamp, Blend};
        let DP_OPAQUE : DrawParameters = DrawParameters {
            depth: Depth { test: DepthTest::IfMoreOrEqual, write: true, .. Default::default() },
            .. Default::default()
        };
        let DP_TRANSPARENT : DrawParameters = DrawParameters {
            depth: Depth { test: DepthTest::IfMoreOrEqual, write: false, .. Default::default() },
            blend: Blend::alpha_blending(),
            .. Default::default()
        };
        let dp = if transparent { &DP_TRANSPARENT } else { &DP_OPAQUE };
        frame.draw(
            &self.quad_vertices,
            self.quad_indices,
            &self.shape_shader, &uniforms,
            &dp).unwrap();
    }
    fn draw (&self, frame: &mut glium::Frame, item: &RenderItem) {
//        println!("Drawing {:?}", item);
        match item.primitive {
            RenderPrimitive::SolidBox(color) => self.draw_with_params(frame, &item.transform, "draw_solid_box", 0.0, color, item.transparent),
            RenderPrimitive::SolidCircle(color) => self.draw_with_params(frame, &item.transform, "draw_solid_circle", 0.0, color, item.transparent),
            RenderPrimitive::OutlineBox(width, color) => self.draw_with_params(frame, &item.transform, "draw_outline_box", width, color, item.transparent),
            RenderPrimitive::OutlineCircle(width, color) => self.draw_with_params(frame, &item.transform, "draw_outline_circle", width, color, item.transparent),
            RenderPrimitive::Sprite(_) => println!("unimplemented: render sprite!"),
            RenderPrimitive::Text(_) => println!("unimplemented: render text!"),
        }
    }
}
