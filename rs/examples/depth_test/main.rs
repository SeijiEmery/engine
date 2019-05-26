//#[macro_use]
extern crate engine_rs;
use engine_rs::{GameDelegate, RendererBackend, GameLoopState};
use engine_rs::*;
use engine_rs::{ActiveCamera, Camera, BoxShape, CircleShape};
use engine_rs::{ShapeRendererSystem};
#[macro_use]
use specs_derive;
#[macro_use]
use specs;
#[macro_use]
use specs::prelude::*;
use specs::{Component, System, SystemData, ReadStorage, Read, WriteStorage};
use specs::world::Builder;
use engine_rs::ecs_components::render_components::{MaterialComponent, ShapeComponent, ShapeRendererComponent};
use engine_rs::ecs_components::transform_components::TransformComponent;
use core::borrow::Borrow;

fn red   (a: f32) -> MaterialComponent { MaterialComponent::new(1.0, 0.0, 0.0, a) }
fn green (a: f32) -> MaterialComponent { MaterialComponent::new(0.0, 1.0, 0.0, a) }
fn blue  (a: f32) -> MaterialComponent { MaterialComponent::new(0.0, 0.0, 1.0, a) }

fn make_box (entities: &mut specs::World, material: MaterialComponent, x: f32, y: f32, depth: f32) {
    entities.create_entity()
        .with(material)
        .with(TransformComponent::new().with_depth(depth).with_pos(x, y).with_scale(0.4))
        .with(ShapeComponent::Box(BoxShape{ w: 1.0, h: 1.0 }))
        .with(ShapeRendererComponent { visible: true, outline: None })
        .build();
}
fn draw_series (entities: &mut specs::World, start: Vec2, end: Vec2, a0: f32, a1: f32, a2: f32) {
    let p0 = start;
    let p1 = (start + end) * 0.5;
    let p2 = end;
    make_box(entities, red(a0), p0.x, p0.y, 0.1);
    make_box(entities, green(a1), p1.x, p1.y, 0.2);
    make_box(entities, blue(a2), p2.x, p2.y, 0.3);
}

#[derive(Default)]
struct DepthTest {}
impl GameDelegate for DepthTest {
    fn register_components (&mut self, entities: &mut specs::World) {
        let main_camera : ActiveCamera = Camera::new();
        entities.register::<MaterialComponent>();
        entities.register::<TransformComponent>();
        entities.register::<ShapeComponent>();
        entities.register::<ShapeRendererComponent>();
        entities.add_resource(main_camera);

        draw_series(entities, vec2(-0.7, -0.7), vec2(-0.3, -0.5), 1.0, 1.0, 1.0);
        draw_series(entities, vec2( 0.3, -0.7), vec2( 0.7, -0.5), 0.8, 1.0, 1.0);

        draw_series(entities, vec2(-0.7, -0.1), vec2(-0.3,  0.1), 1.0, 0.8, 1.0);
        draw_series(entities, vec2( 0.3, -0.1), vec2( 0.7,  0.1), 1.0, 1.0, 0.8);

        draw_series(entities, vec2(-0.7, 0.5), vec2(-0.3,  0.7), 0.8, 0.8, 1.0);
        draw_series(entities, vec2( 0.3, 0.5), vec2( 0.7,  0.7), 1.0, 0.8, 0.8);
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
run_game!(DepthTest);
