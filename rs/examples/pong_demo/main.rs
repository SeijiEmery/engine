//#[macro_use]
extern crate engine_rs;
use engine_rs::{GameDelegate, RendererBackend, GameLoopState};
use engine_rs::*;
use engine_rs::{ActiveCamera, Camera, BoxShape, CircleShape};
use engine_rs::{ShapeRendererSystem};
use specs;
use specs::{Component, System, ReadStorage, Read, WriteStorage, VecStorage, Join};
use specs::world::Builder;
use engine_rs::ecs_components::render_components::{MaterialComponent, ShapeComponent, ShapeRendererComponent};
use engine_rs::ecs_components::transform_components::TransformComponent;
mod player_input;
mod player;
use player_input::{PlayerInput};


#[derive(Default)]
struct PongGame {
    player1: Option<specs::Entity>,
    player2: Option<specs::Entity>,
    ball: Option<specs::Entity>
}
impl GameDelegate for PongGame {
    fn register_components (&mut self, entities: &mut specs::World) {
        let main_camera : ActiveCamera = Camera::new();
        entities.add_resource(main_camera);

        player::register_entities(entities);
        self.player1 = Some(player::make_player(entities,
            1, 2.0, vec3(1.0, 1.0, 1.0),
            -0.85, 0.7, vec2(0.3, 0.08)));
        self.player2 = Some(player::make_player(entities,
            2, 2.0, vec3(1.0, 1.0, 1.0),
            0.85, 0.7, vec2(0.3, 0.08)));
        entities.add_resource(PlayerInput::new());
    }
    fn register_systems (&mut self, systems: &mut specs::DispatcherBuilder, renderer: &mut RendererBackend) {
        player::register_systems(systems);
        systems.add_thread_local(ShapeRendererSystem::new(renderer));
    }
    fn handle_event (&mut self, event: &glium::glutin::Event, state: &mut GameLoopState) {
        let input = &mut *state.ecs.write_resource::<PlayerInput>();
        input.on_event(event);
    }
    fn on_begin_frame (&mut self, state: &mut GameLoopState) {
        let input = &mut *state.ecs.write_resource::<PlayerInput>();
        let time = &*state.ecs.read_resource::<Time>();
        input.update(time);
    }
    fn on_end_frame (&mut self, _state: &mut GameLoopState) {}
    fn teardown (&mut self, _state: &mut GameLoopState) {
        println!("terminating...");
    }
}
run_game!(PongGame);
