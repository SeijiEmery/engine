#[macro_use]
extern crate specs_derive;
#[macro_use]
extern crate glium;
extern crate specs;
use specs::prelude::*;
use glium::{Surface, Display};

#[derive(Component)]
#[storage(VecStorage)]
struct Transform {
    pos: (f32, f32),
    scale: f32,
    rot: f32,
}
struct Color { r: f32, g: f32, b: f32, a: f32 }

#[derive(Component)]
#[storage(VecStorage)]
struct Material {
    color: Color
}

#[derive(Component)]
#[storage(VecStorage)]
enum Shape {
    Box { w: f32, h: f32 },
    Circle { r: f32 }
}

#[derive(Component)]
#[storage(VecStorage)]
struct Renderable {}

#[derive(Copy, Clone)]
struct Vertex {
    position: [f32; 2],
}
implement_vertex!(Vertex, position);

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
//        let program = glium::Program::from_source(&display, vertex_shader, fragment_shader, None).unwrap();
//        return TriangleGeometry {
//            vertex_buffer: vertex_buffer.unwrap(),
//            indices: indices,
//            shader: program
//        }
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
    display: glium::Display
}
impl RendererSystem {
    fn new (display: glium::Display) -> RendererSystem {
        return RendererSystem { display };
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
        for (render_item, transform, shape, material) in (&render_items, &transforms, &shapes, &materials).join() {

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
