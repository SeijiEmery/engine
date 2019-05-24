//#[macro_use]
extern crate engine_rs;
use engine_rs::{GameDelegate, RendererBackend, GameLoopState};
use engine_rs::*;
use engine_rs::{ActiveCamera, Camera, BoxShape, CircleShape};
use engine_rs::{ShapeRendererSystem};
use specs;
use specs::world::Builder;
use engine_rs::ecs_components::render_components::{MaterialComponent, ShapeComponent, ShapeRendererComponent};
use engine_rs::ecs_components::transform_components::TransformComponent;

#[derive(Default)]
struct RenderTest {}
impl GameDelegate for RenderTest {
    fn register_components (&mut self, entities: &mut specs::World) {
        let main_camera : ActiveCamera = Camera::new();
        entities.register::<MaterialComponent>();
        entities.register::<TransformComponent>();
        entities.register::<ShapeComponent>();
        entities.register::<ShapeRendererComponent>();
        entities.add_resource(main_camera);
        entities.create_entity()
            .with(MaterialComponent::new(0.8, 0.2, 0.2, 0.0))
            .with(TransformComponent::new().with_pos(0.0, 0.0).with_scale(0.2).with_angle(0.523))
            .with(ShapeComponent::Box(BoxShape{ w: 1.0, h: 1.0 }))
            .with(ShapeRendererComponent { visible: true, outline: None })
            .build();
    }
    fn register_systems (&mut self, systems: &mut specs::DispatcherBuilder, renderer: &mut RendererBackend) {
        systems.add_thread_local(ShapeRendererSystem::new(renderer));
    }
    fn handle_event (&mut self, _event: &glium::glutin::Event, _game_state: &mut GameLoopState) {}
    fn on_begin_frame (&mut self) {}
    fn on_end_frame (&mut self) {}
    fn teardown (&mut self) {
        println!("terminating...");
    }
}
run_game!(RenderTest);
