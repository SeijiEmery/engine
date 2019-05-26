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

#[derive(Default)]
struct PlayerInput(f32);
struct PlayerComponent { min_x: f32, max_x: f32, speed: f32 }
impl Component for PlayerComponent { type Storage = VecStorage<PlayerComponent>; }
struct PlayerInputSystem {}
impl<'a> System<'a> for PlayerInputSystem {
    type SystemData = (
        Read<'a, Time>,
        Read<'a, PlayerInput>,
        ReadStorage<'a, PlayerComponent>,
        WriteStorage<'a, TransformComponent>
    );
    fn run (&mut self, (time, input, player, mut transform): Self::SystemData) {
        let time = &*time;
        let input = &*input;
        for (player, mut transform) in (&player, &mut transform).join() {
            let mut x = transform.pos.x + player.speed * input.0 * (time.dt as f32);
            if x < player.min_x { x = player.min_x; }
            if x > player.max_x { x = player.max_x; }
            transform.pos.x = x;
        }
    }
}

#[derive(Default)]
struct PongGame {}
impl GameDelegate for PongGame {
    fn register_components (&mut self, entities: &mut specs::World) {
        let main_camera : ActiveCamera = Camera::new();
        entities.register::<MaterialComponent>();
        entities.register::<TransformComponent>();
        entities.register::<ShapeComponent>();
        entities.register::<ShapeRendererComponent>();
        entities.register::<PlayerComponent>();
        entities.add_resource(main_camera);
        entities.add_resource(PlayerInput(0.0));

        // player paddle
        entities.create_entity()
            .with(PlayerComponent { speed: 1.0, min_x: -0.7, max_x: 0.7 })
            .with( TransformComponent { pos: vec3(0.0, -0.7, 1.0), scale: vec2(0.5, 0.2), rot: Rad(0.0) })
            .with(ShapeComponent::Box(BoxShape{ w: 0.5, h: 0.2 }))
            .with(ShapeRendererComponent { visible: true, outline: None })
            .with(MaterialComponent { color: Color { r: 1.0, g: 1.0, b: 1.0, a: 1.0 } })
            .build();
    }
    fn register_systems (&mut self, systems: &mut specs::DispatcherBuilder, renderer: &mut RendererBackend) {
        systems.add(PlayerInputSystem{}, "player input", &[]);
        systems.add_thread_local(ShapeRendererSystem::new(renderer));
    }
    fn handle_event (&mut self, _event: &glium::glutin::Event, _game_state: &mut GameLoopState) {}
    fn on_begin_frame (&mut self) {}
    fn on_end_frame (&mut self) {}
    fn teardown (&mut self) {
        println!("terminating...");
    }
}
run_game!(PongGame);
