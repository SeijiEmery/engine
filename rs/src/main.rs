#[macro_use]
extern crate glium;

use glium::{Surface, Display};

#[derive(Copy, Clone)]
struct Vertex {
    position: [f32; 2],
}
implement_vertex!(Vertex, position);

trait Renderable {
    fn draw (&self, target: &mut glium::Frame);
}
struct TriangleGeometry {
    vertex_buffer: glium::VertexBuffer<Vertex>,
    indices: glium::index::NoIndices,
    shader: glium::Program,
}
impl TriangleGeometry {
    fn new (display: glium::Display) -> TriangleGeometry {
        let vertices = vec![
            Vertex { position: [-0.5, -0.5]},
            Vertex { position: [ 0.0, 0.5]},
            Vertex { position: [ 0.5, -0.25]}
        ];
        let vertex_buffer = glium::VertexBuffer::new(&display, &vertices);
        let indices = glium::index::NoIndices(glium::index::PrimitiveType::TrianglesList);

        let vertex_shader = r#"
            #version 410
            in vec2 position;
            void main () {
                gl_Position = vec4(position, 0.0, 1.0);
            }
        "#;
        let fragment_shader = r#"
            #version 410
            out vec4 color;
            void main () {
                color = vec4(1.0, 0.0, 0.0, 1.0);
            }
        "#;
        let program = glium::Program::from_source(&display, vertex_shader, fragment_shader, None).unwrap();
        return TriangleGeometry {
            vertex_buffer: vertex_buffer.unwrap(),
            indices: indices,
            shader: program
        }
    }
}
impl Renderable for TriangleGeometry {
    fn draw (&self, target: &mut glium::Frame) {
        target.draw(&self.vertex_buffer, self.indices, &self.shader,
            &glium::uniforms::EmptyUniforms, &Default::default()).unwrap();
    }
}

fn main() {
    use glium::glutin;
    let mut events_loop = glutin::EventsLoop::new();
    let wb = glutin::WindowBuilder::new();
    let cb = glutin::ContextBuilder::new();
    let display = glium::Display::new(wb, cb, &events_loop).unwrap();
    let mut closed = false;

    let triangle = TriangleGeometry::new(display.clone());
    while !closed {
        let mut target = display.draw();
        target.clear_color(0.0, 0.0, 0.0, 1.0);
        triangle.draw(&mut target);
        target.finish().unwrap();
        events_loop.poll_events(|ev| {
            match ev {
                glutin::Event::WindowEvent { event, .. } => match event {
                    glutin::WindowEvent::CloseRequested => closed = true,
                    glutin::WindowEvent::Resized(sz) => println!("resized: {:?}", sz),
                    _ => ()
                },
                _ => ()
            }
        });
    }
}
