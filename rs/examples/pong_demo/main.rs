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
mod ball;
use player_input::{MultiplayerInput, PlayerInputState, PlayerKeyBindings};
use glium::index::IndicesSource::MultidrawArray;

#[derive(Default)]
struct PongGame {
    player1: Option<specs::Entity>,
    player2: Option<specs::Entity>,
    ball: Option<specs::Entity>,
    window_width: f32, window_height: f32,
}
impl GameDelegate for PongGame {
    fn register_components (&mut self, entities: &mut specs::World) {
        let main_camera : ActiveCamera = Camera::new();
        entities.add_resource(main_camera);

        player::register_entities(entities);
        ball::register_entities(entities);
        self.player1 = Some(player::make_player(entities,
            1, 2.0, vec3(1.0, 1.0, 1.0),
            -0.85, 0.7, vec2(0.3, 0.08)));
        self.player2 = Some(player::make_player(entities,
            2, 2.0, vec3(1.0, 1.0, 1.0),
            0.85, 0.7, vec2(0.3, 0.08)));

        let player1= PlayerInputState::new(PlayerKeyBindings::Arrows);
        let player2 = PlayerInputState::new(PlayerKeyBindings::WASD);
        let white = vec3(1.0, 1.0, 1.0);
        let ball = ball::make_ball(entities, vec2(0.0, 0.0), vec2(-0.8, 0.2),
                                   1.0, vec2(0.85, 0.85),
                                   white, 0.08);

        // for stress testing
//        let n : i32 = 1_000;
//        for i in 0 .. n {
//            ball::make_ball(entities, vec2(0.0, 0.0),
//                            vec2(i as f32 / n as f32 * 2.0 - 1.0, 0.2).normalize_to(1.0),
//                            10.0, vec2(0.85, 0.85),
//                            white, 0.08);
//        }
//        let player2 = PlayerInputState::new(PlayerKeyBindings::None);
        let input = MultiplayerInput { player1, player2 };
        entities.add_resource(input);
        entities.add_resource(ball::CursorTarget{ pos: vec2(0.0, 0.0)});
        entities.add_resource(ball::AspectRatio::new(1.0));
    }
    fn register_systems (&mut self, systems: &mut specs::DispatcherBuilder, renderer: &mut RendererBackend) {
        player::register_systems(systems);
        ball::register_systems(systems);
        systems.add_thread_local(ShapeRendererSystem::new(renderer));
    }
    fn handle_event (&mut self, event: &glium::glutin::Event, state: &mut GameLoopState) {
        let input = &mut *state.ecs.write_resource::<MultiplayerInput>();
        input.on_event(event);
        match event {
            glium::glutin::Event::WindowEvent {
                event: glutin::WindowEvent::Resized(size), ..
            } => {
                self.window_width = size.width as f32;
                self.window_height = size.height as f32;
                let aspect_ratio = &mut *state.ecs.write_resource::<ball::AspectRatio>();
                aspect_ratio.set(size.width as f32 / size.height as f32);
            },
            glium::glutin::Event::WindowEvent {
                event: glutin::WindowEvent::CursorMoved {
                    position, ..
                }, ..
            } => {
                let target = &mut *state.ecs.write_resource::<ball::CursorTarget>();
                target.pos = vec2(
                    position.x as f32 / self.window_width,
                    position.y as f32 / self.window_height);

                target.pos *= 2.0;
                target.pos.x -= 1.0;
                target.pos.y = 1.0 - target.pos.y;
            }, _ => ()
        }
    }
    fn on_begin_frame (&mut self, state: &mut GameLoopState) {
        let input = &mut *state.ecs.write_resource::<MultiplayerInput>();
        let time = &*state.ecs.read_resource::<Time>();
        input.update(time);
    }
    fn on_end_frame (&mut self, _state: &mut GameLoopState) {}
    fn teardown (&mut self, _state: &mut GameLoopState) {
        println!("terminating...");
    }
}
run_game!(PongGame);
