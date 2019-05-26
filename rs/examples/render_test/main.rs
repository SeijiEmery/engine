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

//#[derive(Component)]
//#[storage(VecStorage)]
struct RotateMotion { speed: f64 }
impl Component for RotateMotion { type Storage = VecStorage<RotateMotion>; }
struct RotatingSystem;
impl<'a> System<'a> for RotatingSystem {
     type SystemData = (
        Read<'a, Time>,
        ReadStorage<'a, RotateMotion>,
        WriteStorage<'a, TransformComponent>,
    );
    fn run (&mut self, (time, rotate_motion, mut transform): Self::SystemData) {
        let time  = &*time;
        for (rotate_motion, mut transform) in (&rotate_motion, &mut transform).join() {
            transform.rot = Rad(
                (rotate_motion.speed * time.total_simulation_time) as f32);
        }
    }
}
struct ScaleOscillator { max_scale: Vec2, min_scale: Vec2, speed: Vec2 }
impl Component for ScaleOscillator { type Storage = VecStorage<ScaleOscillator>; }
struct ScaleOscillatorSystem;
impl<'a> System<'a> for ScaleOscillatorSystem {
     type SystemData = (
        Read<'a, Time>,
        ReadStorage<'a, ScaleOscillator>,
        WriteStorage<'a, TransformComponent>,
    );
    fn run (&mut self, (time, oscillator, mut transform): Self::SystemData) {
        let time  = &*time;
        for (oscillator, mut transform) in (&oscillator, &mut transform).join() {
            transform.scale.x = oscillator.min_scale.x
                + (oscillator.max_scale.x - oscillator.min_scale.x)
                * 0.5 * (1.0 + (oscillator.speed.x * time.total_simulation_time as f32).cos());
            transform.scale.y = oscillator.min_scale.y
                + (oscillator.max_scale.y - oscillator.min_scale.y)
                * 0.5 * (1.0 + (oscillator.speed.y * time.total_simulation_time as f32).cos());
        }
    }
}
struct MoveOscillator { from: Vec2, to: Vec2, period: f64 }
impl Component for MoveOscillator { type Storage = VecStorage<MoveOscillator>; }
struct MoveOscillatorSystem;
impl<'a> System<'a> for MoveOscillatorSystem {
     type SystemData = (
        Read<'a, Time>,
        ReadStorage<'a, MoveOscillator>,
        WriteStorage<'a, TransformComponent>,
    );
    fn run (&mut self, (time, oscillator, mut transform): Self::SystemData) {
        let time  = &*time;
        for (oscillator, mut transform) in (&oscillator, &mut transform).join() {
            let speed = std::f64::consts::FRAC_2_PI / oscillator.period;
            let interp = 0.5 * (1.0 +
                (speed * time.total_simulation_time).sin()) as f32;
            let target = oscillator.from * interp + oscillator.to * (1.0 - interp);
            transform.pos.x = target.x;
            transform.pos.y = target.y;
            transform.pos.z = -1.0 + interp * 2.0;
        }
    }
}
struct DepthOscillator { from: f64, to: f64, period: f64 }
impl Component for DepthOscillator { type Storage = VecStorage<DepthOscillator>; }
struct DepthOscillatorSystem;
impl<'a> System<'a> for DepthOscillatorSystem {
     type SystemData = (
        Read<'a, Time>,
        ReadStorage<'a, DepthOscillator>,
        WriteStorage<'a, TransformComponent>,
    );
    fn run (&mut self, (time, oscillator, mut transform): Self::SystemData) {
        let time  = &*time;
        for (oscillator, mut transform) in (&oscillator, &mut transform).join() {
            let speed = std::f64::consts::FRAC_2_PI / oscillator.period;
            let interp = 0.5 * (1.0 +
                (speed * time.total_simulation_time).sin());
            let target = oscillator.from * interp + oscillator.to * (1.0 - interp);
            transform.pos.z = target as f32;
        }
    }
}
struct ColorOscillator { from: Vec4, to: Vec4, period: f64 }
impl Component for ColorOscillator { type Storage = VecStorage<ColorOscillator>; }
struct ColorOscillatorSystem;
impl<'a> System<'a> for ColorOscillatorSystem {
     type SystemData = (
        Read<'a, Time>,
        ReadStorage<'a, ColorOscillator>,
        WriteStorage<'a, MaterialComponent>,
    );
    fn run (&mut self, (time, oscillator, mut material): Self::SystemData) {
        let time  = &*time;
        for (oscillator, mut material) in (&oscillator, &mut material).join() {
            let speed = std::f64::consts::FRAC_2_PI / oscillator.period;
            let interp = 0.5 * (1.0 +
                (speed * time.total_simulation_time).sin()) as f32;
            let target = oscillator.from * interp + oscillator.to * (1.0 - interp);
            material.color = Color {
                r: target.x, g: target.y, b: target.z, a: target.w
            };
        }
    }
}

#[derive(Default)]
struct RenderTest {}
impl GameDelegate for RenderTest {
    fn register_components (&mut self, entities: &mut specs::World) {
        let main_camera : ActiveCamera = Camera::new();
        entities.register::<MaterialComponent>();
        entities.register::<TransformComponent>();
        entities.register::<ShapeComponent>();
        entities.register::<ShapeRendererComponent>();
        entities.register::<RotateMotion>();
        entities.register::<ScaleOscillator>();
        entities.register::<MoveOscillator>();
        entities.register::<DepthOscillator>();
        entities.register::<ColorOscillator>();
        entities.add_resource(main_camera);
        entities.create_entity()
            .with(ScaleOscillator {
                min_scale: vec2(0.05, 0.1),
                max_scale: vec2(1.0, 1.0),
                speed: vec2(1.0, 1.0) })
            .with(MaterialComponent::new(0.8, 0.2, 0.2, 1.0))
            .with(TransformComponent::new().with_depth(0.1).with_pos(0.4, 0.6).with_scale(0.2).with_angle(0.523))
            .with(ShapeComponent::Box(BoxShape{ w: 1.0, h: 1.0 }))
            .with(ShapeRendererComponent { visible: true, outline: None })
            .build();
        entities.create_entity()
            .with(RotateMotion { speed: 1.0 })
            .with(MaterialComponent::new(0.3, 0.5, 0.2, 1.0))
            .with(TransformComponent::new().with_depth(0.1).with_pos(-0.4, 0.6).with_scale(0.2).with_angle(-0.523))
            .with(ShapeComponent::Box(BoxShape{ w: 1.0, h: 1.0 }))
            .with(ShapeRendererComponent { visible: true, outline: Some(0.05) })
            .build();
        entities.create_entity()
            .with(ScaleOscillator {
                min_scale: vec2(0.2, 0.15),
                max_scale: vec2(0.7, 0.05),
                speed: vec2(5.0, 10.0)
            })
            .with(RotateMotion { speed: 10.0 })
            .with(MaterialComponent::new(0.8, 0.8, 0.2, 1.0))
            .with(TransformComponent::new().with_depth(0.8).with_pos(0.4, -0.6).with_scale(0.2).with_angle(0.523))
            .with(ShapeComponent::Circle(CircleShape{ r: 1.0 }))
            .with(ShapeRendererComponent { visible: true, outline: None })
            .build();
        entities.create_entity()
            .with(MoveOscillator {
                from: vec2(-0.6, -0.7), to: vec2(0.4, 0.5), period: 0.5
            })
            .with(MaterialComponent::new(1.0, 0.0, 0.0, 0.99))
            .with(TransformComponent::new().with_depth(1.0).with_pos(-0.4, -0.6).with_scale(0.2).with_angle(-0.523))
            .with(ShapeComponent::Circle(CircleShape{ r: 1.0 }))
            .with(ShapeRendererComponent { visible: true, outline: Some(0.05) })
            .build();

        entities.create_entity()
            .with(MaterialComponent::new(0.8, 0.6, 0.4, 1.0))
            .with(ColorOscillator { from: vec4(1.0, 0.5, 0.5, 0.9), to: vec4(0.0, 0.5, 0.0, 0.1), period: 0.5 })
            .with(TransformComponent::new().with_depth(0.30).with_pos(0.0, 0.0).with_scale(1.0))
            .with(ShapeComponent::Circle(CircleShape{ r: 1.0 }))
            .with(ShapeRendererComponent { visible: true, outline: None })
            .build();
        entities.create_entity()
            .with(MaterialComponent::new(0.1, 0.6, 0.8, 1.0))
            .with(TransformComponent::new().with_depth(0.31).with_pos(0.0, 0.0).with_scale(1.0))
            .with(ShapeComponent::Circle(CircleShape{ r: 1.0 }))
            .with(ShapeRendererComponent { visible: true, outline: Some(0.05) })
            .build();
    }
    fn register_systems (&mut self, systems: &mut specs::DispatcherBuilder, renderer: &mut RendererBackend) {
        systems.add(RotatingSystem{}, "rotate motion", &[]);
        systems.add(ScaleOscillatorSystem{}, "scale oscillator system", &[]);
        systems.add(MoveOscillatorSystem{}, "moving oscillator system", &[]);
        systems.add(DepthOscillatorSystem{}, "depth oscillator system", &[]);
        systems.add(ColorOscillatorSystem{}, "color oscillator system", &[]);
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
