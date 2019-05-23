#[macro_use]
extern crate specs_derive;
#[macro_use]
extern crate glium;
extern crate specs;
use specs::prelude::*;
use glium::{Surface, Display};
use glium::uniforms::AsUniformValue;
use core::borrow::Borrow;

#[derive(Component)]
#[storage(VecStorage)]
struct Transform {
    pos: (f32, f32),
    scale: f32,
    rot: f32,
}
struct Color { r: f32, g: f32, b: f32, a: f32 }
impl AsUniformValue for Color {
    fn as_uniform_value (&self) -> glium::uniforms::UniformValue {
        return glium::uniforms::UniformValue::Vec4([
            self.r, self.g, self.b, self.a
        ]);
    }
}


#[derive(Component)]
#[storage(VecStorage)]
struct Material {
    color: Color
}

struct BoxShape { w: f32, h: f32 }
struct CircleShape { r: f32 }

#[derive(Component)]
#[storage(VecStorage)]
enum Shape {
    Box(BoxShape),
    Circle(CircleShape),
}

#[derive(Component)]
#[storage(VecStorage)]
struct Renderable {}

#[derive(Copy, Clone)]
struct Vertex {
    position: [f32; 2],
}
implement_vertex!(Vertex, position);

trait Renderer <RenderData> {
    fn draw (&self, target: &mut glium::Frame, camera: &Camera, material: &Material, data: &RenderData);
}
struct BoxRenderer {
    vertex_buffer: glium::VertexBuffer<Vertex>,
    indices: glium::index::NoIndices,
    shader: glium::Program
}
impl BoxRenderer {
    fn new (display: &glium::Display) -> BoxRenderer {
        let vertices = vec![
            Vertex { position: [ -0.5,  0.5 ] },
            Vertex { position: [ -0.5, -0.5 ] },
            Vertex { position: [  0.5, -0.5 ] },
            Vertex { position: [ -0.5,  0.5 ] },
            Vertex { position: [  0.5, -0.5 ] },
            Vertex { position: [  0.5,  0.5 ] },
        ];
        let display = display.clone();
        let vertex_buffer = glium::VertexBuffer::new(&display, &vertices).unwrap();
        let indices = glium::index::NoIndices(glium::index::PrimitiveType::TrianglesList);
        let vertex_shader_src = r#"
            #version 410
            in vec2 position;
            uniform mat4 mvp_matrix;
            void main () {
                gl_Position = mvp_matrix * vec4(position, 0.0, 1.0);
            }
        "#;
        let fragment_shader_src = r#"
            #version 410
            out vec4 out_color;
            uniform vec4 material_color;
            void main () {
                out_color = material_color;
            }
        "#;
        let shader = glium::Program::from_source(
            &display,
            vertex_shader_src,
            fragment_shader_src,
            None
        ).unwrap();
        return BoxRenderer { vertex_buffer, indices, shader }
    }
}
impl Renderer<BoxShape> for BoxRenderer {
    fn draw (&self, target: &mut glium::Frame, camera: &Camera, material: &Material, shape: &BoxShape) {
        let color = &material.color;
        let uniforms = glium::uniform! {
            mvp_matrix: [
                [1.0, 0.0, 0.0, 0.0],
                [0.0, 1.0, 0.0, 0.0],
                [0.0, 0.0, 1.0, 0.0],
                [0.0 , 0.0, 0.0, 1.0],
            ],
            out_color: [ color.r, color.g, color.b, color.a ],
        };
        target.draw(&self.vertex_buffer, self.indices, &self.shader, &uniforms,
            &Default::default()).unwrap();
    }
}
struct CircleRenderer {}
impl CircleRenderer {
    fn new (display: &glium::Display) -> CircleRenderer {
        return CircleRenderer {}
    }
}
impl Renderer<CircleShape> for CircleRenderer {
    fn draw (&self, target: &mut glium::Frame, camera: &Camera, material: &Material, shape: &CircleShape) {
        println!("Drawing circles is unimplemented!");
    }
}


struct ShapeRenderer {
    box_renderer: BoxRenderer,
    circle_renderer: CircleRenderer,
}
impl ShapeRenderer {
    fn new (display: &glium::Display) -> ShapeRenderer {
        let box_renderer = BoxRenderer::new(&display);
        let circle_renderer = CircleRenderer::new(&display);
        return ShapeRenderer { box_renderer, circle_renderer };
    }
}
impl Renderer<Shape> for ShapeRenderer {
    fn draw (&self, target: &mut glium::Frame, camera: &Camera, material: &Material, shape: &Shape) {
        match shape {
            Shape::Box(shape) => self.box_renderer.draw(target, camera, material, shape),
            Shape::Circle(shape) => self.circle_renderer.draw(target, camera, material, shape),
        }
    }
}










//trait Renderable {
//    fn draw (&self, target: &mut glium::Frame);
//}
//struct TriangleGeometry {
//    vertex_buffer: glium::VertexBuffer<Vertex>,
//    indices: glium::index::NoIndices,
//    shader: glium::Program,
//}
//impl TriangleGeometry {
//    fn new (display: glium::Display) -> TriangleGeometry {
//        let vertices = vec![
//            Vertex { position: [-0.5, -0.5]},
//            Vertex { position: [ 0.0, 0.5]},
//            Vertex { position: [ 0.5, -0.25]}
//        ];
//        let vertex_buffer = glium::VertexBuffer::new(&display, &vertices);
//        let indices = glium::index::NoIndices(glium::index::PrimitiveType::TrianglesList);
//
//        let vertex_shader = r#"
//            #version 410
//            in vec2 position;
//            void main () {
//                gl_Position = vec4(position, 0.0, 1.0);
//            }
//        "#;
//        let fragment_shader = r#"
//            #version 410
//            out vec4 color;
//            void main () {
//                color = vec4(1.0, 0.0, 0.0, 1.0);
//            }
//        "#;
//
//    }
//}
//impl Renderable for TriangleGeometry {
//    fn draw (&self, target: &mut glium::Frame) {
//        target.draw(&self.vertex_buffer, self.indices, &self.shader,
//            &glium::uniforms::EmptyUniforms, &Default::default()).unwrap();
//    }
//}

#[derive(Default)]
struct Camera {}
impl Camera {
    fn new () -> Camera {
        return Camera {};
    }
}

struct RendererSystem {
    display: glium::Display,
    renderer: ShapeRenderer,
}
impl RendererSystem {
    fn new (display: glium::Display) -> RendererSystem {
        let renderer = ShapeRenderer::new(&display);
        return RendererSystem { display, renderer };
    }
}
impl<'a> System<'a> for RendererSystem {
    type SystemData = (
        Read<'a, Camera>,
        ReadStorage<'a, Renderable>,
        ReadStorage<'a, Transform>,
        ReadStorage<'a, Shape>,
        ReadStorage<'a, Material>
    );
    fn run (&mut self, (camera, render_items, transforms, shapes, materials): Self::SystemData) {
        let mut frame = self.display.draw();
        frame.clear_color(0.0, 0.0, 0.0, 1.0);
        let camera = &*camera;
        for (render_item, transform, shape, material) in (&render_items, &transforms, &shapes, &materials).join() {
            self.renderer.draw(&mut frame, &camera, material, shape);
        }
        frame.finish().unwrap();
    }
}

struct GameLoopState { running: bool }
struct GameLoop <'a, 'b> {
    ecs: specs::World,
    dispatcher: specs::Dispatcher<'a, 'b>,
    events_loop: glium::glutin::EventsLoop,
    state: GameLoopState
}

impl<'a, 'b> GameLoop <'a, 'b> {
    fn new () -> GameLoop<'a, 'b> {
        use glium::glutin;
        let mut events_loop = glutin::EventsLoop::new();
        let wb = glutin::WindowBuilder::new();
        let cb = glutin::ContextBuilder::new();
        let display = glium::Display::new(wb, cb, &events_loop).unwrap();
        let mut ecs = specs::World::new();
        ecs.register::<Transform>();
        ecs.register::<Material>();
        ecs.register::<Shape>();
        ecs.register::<Renderable>();
        ecs.add_resource(Camera::new());

        let mut renderer = RendererSystem::new(display);
        let mut dispatcher = DispatcherBuilder::new()
            .with_thread_local(renderer)
            .build();
        return GameLoop { ecs, dispatcher, events_loop, state: GameLoopState { running: true } };
    }
    fn run (&mut self) {
        while self.state.running {
            self.dispatcher.dispatch(&mut self.ecs.res);
            let state = &mut self.state;
            self.events_loop.poll_events(|ev| {
                match ev {
                    glutin::Event::WindowEvent { event, .. } => match event {
                        glutin::WindowEvent::CloseRequested => state.running = false,
                        _ => ()
                    },
                    _ => ()
                }
            })
        }
    }
}

fn main() {
    GameLoop::new().run();
}
