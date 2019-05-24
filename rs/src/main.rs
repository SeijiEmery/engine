#[macro_use]
extern crate specs_derive;
#[macro_use]
extern crate glium;
extern crate specs;
mod renderer;

use specs::prelude::*;
use glium::{Surface, Display};
use glium::uniforms::AsUniformValue;
use core::borrow::Borrow;
use glium::buffer::BufferType::TransformFeedbackBuffer;
use glutin::VirtualKeyCode;
















trait Renderer <RenderData> {
    fn draw (&self, target: &mut glium::Frame, camera: &Camera, material: &Material, data: &RenderData);
}
struct BoxRenderer {
    vertex_buffer: glium::VertexBuffer<Vertex>,
    indices: glium::index::NoIndices,
    shader: glium::Program
}

impl Renderer<BoxShape> for BoxRenderer {
    fn draw (&self, target: &mut glium::Frame, camera: &Camera, material: &Material, shape: &BoxShape) {
        let color = &material.color;
        let uniforms = glium::uniform! {
//            mvp_matrix: [
//                [1.0, 0.0, 0.0, 0.0],
//                [0.0, 1.0, 0.0, 0.0],
//                [0.0, 0.0, 1.0, 0.0],
//                [0.0 , 0.0, 0.0, 1.0],
//            ],
            material_color: [ color.r, color.g, color.b, color.a ],
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

struct BasicRenderer {
    display: glium::Display,
    frame: Option<glium::Frame>,
    shape_renderer: ShapeRenderer,
}
impl BasicRenderer {
    fn new (display: glium::Display) -> BasicRenderer {
        shape_renderer = ShapeRenderer::new(&display);
        let frame: Option<glium::Frame> = None;
        return BasicRenderer { display, frame, shape_renderer };
    }
    fn begin_frame (&mut self) {
        self.frame = Some(display.draw());
        let mut frame = self.frame.unwrap();
        frame.clear_color(0.0, 0.0, 0.0, 1.0);
    }
    fn end_frame (&mut self) {
        let mut frame = self.frame.unwrap();
        frame.finish();
        self.frame = None;
    }
    fn draw_shape (&mut self, shape: &Shape, material: &Material, transform: &Transform, camera: &Camera) {
        let mut frame = self.frame.unwrap();
        self.shape_renderer.draw(&mut frame, &camera, material, shape);
    }
}






struct RendererSystem <'a, Renderer> {
    renderer: Renderer<'a>
}
impl <'a, Renderer> RendererSystem<'a, Renderer> {
    fn new (renderer: Renderer<'a>) -> RendererSystem<'a, Renderer> {
        return RendererSystem { renderer };
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

#[derive(Default, Debug)]
struct PlayerInputState {   // shared resource
    input: (f32, f32)
}
#[derive(Component)]
#[storage(VecStorage)]
struct PlayerComponent {}   // per-player component
struct PlayerInputSystem {  // runs updates...
}
impl<'a> System<'a> for PlayerInputSystem {
    type SystemData = (
        Read<'a, PlayerInputState>,
        ReadStorage<'a, PlayerComponent>,
        WriteStorage<'a, Transform>
    );
    fn run (&mut self, (input, player, mut transform): Self::SystemData) {
//        let input = &*input;
        for (player, transform) in (&player, &mut transform).join() {
            println!("updating player...");
//            transform.pos = (
//                transform.pos.0 + input.input.0,
//                transform.pos.1 + input.input.1
//            );
        }
    }
}

struct GameLoopState { running: bool }
struct GameLoop <'a, 'b> {
    ecs: specs::World,
    dispatcher: specs::Dispatcher<'a, 'b>,
    events_loop: glium::glutin::EventsLoop,
    state: GameLoopState
}

fn make_box (ecs: &mut specs::World) -> specs::Entity {
    let entity = ecs.create_entity()
        .with(Transform::new().with_pos(0.0, 0.0))
        .with(Renderable {})
        .with(Material { color: Color { r: 1.0, g: 0.0, b: 0.2, a: 1.0 } })
        .with(Shape::Box (BoxShape { w: 10.0, h: 10.0 }))
//        .with(PlayerComponent {})
        .build();
    entity
}

impl<'a, 'b> GameLoop <'a, 'b> {
    fn new () -> GameLoop<'a, 'b> {
        use glium::glutin;

        ecs.register::<Transform>();
        ecs.register::<Material>();
        ecs.register::<Shape>();
        ecs.register::<Renderable>();
        ecs.add_resource(Camera::new());
        ecs.add_resource(PlayerInputState { input: (0.0, 0.0) });
        let _ = make_box(&mut ecs);
        let mut renderer = RendererSystem::new(display);
        let mut dispatcher = DispatcherBuilder::new()
            .with_thread_local(renderer)
            .build();
        return GameLoop { ecs, dispatcher, events_loop, state: GameLoopState { running: true } };
    }
    fn run (&mut self) {

    }
}

fn main() {
    GameLoop::new().run();
}
