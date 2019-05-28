use engine_rs::{Time, TransformComponent, Vec2, Vec3, vec3, vec2, CircleShape, Rad, ShapeComponent, BoxShape,
                ShapeRendererComponent, MaterialComponent, Color};
use specs::{Entity, World, Read, ReadStorage, WriteStorage, VecStorage, DispatcherBuilder,
            Component, System, Join, EntityBuilder };
use crate::player_input::MultiplayerInput;
use specs::world::Builder;

pub fn register_entities (entities: &mut World) {
    entities.register::<BallComponent>();
    entities.register::<PaddleComponent>();
}
pub fn register_systems (systems: &mut DispatcherBuilder) {
    systems.add(BallPhysicsSystem{}, "ball paddle collision", &[]);
//    systems.add(PongPhysicsSystem{}, "pong physics system", &[]);
}
pub fn make_ball (entities: &mut World, pos: Vec2, velocity: Vec2, bounds: Vec2, color: Vec3, radius: f32) -> Entity {
    entities.create_entity()
        .with(BallComponent { velocity, bounds, pos, radius })
        .with(TransformComponent { pos: vec3(pos.x, pos.y, 1.0), scale: vec2(radius, radius), rot: Rad(0.0) })
        .with(ShapeComponent::Circle(CircleShape{ r: radius }))
        .with(ShapeRendererComponent { visible: true, outline: None })
        .with(MaterialComponent { color: Color { r: color.x, g: color.y, b: color.z, a: 1.0 } })
        .build()
}

#[derive(Debug)]
pub struct BallComponent { velocity: Vec2, bounds: Vec2, pos: Vec2, radius: f32 }
impl Component for BallComponent { type Storage = VecStorage<BallComponent>; }

#[derive(Debug)]
pub struct PaddleComponent {}
impl Component for PaddleComponent { type Storage = VecStorage<PaddleComponent>; }

struct BallPhysicsSystem {}
impl<'a> System<'a> for BallPhysicsSystem {
    type SystemData = (
        Read<'a, Time>,
        WriteStorage<'a, BallComponent>,
        WriteStorage<'a, TransformComponent>,
        ReadStorage<'a, PaddleComponent>,
    );
    fn run (&mut self, (time, mut ball, mut transforms, paddle): Self::SystemData) {
        let time = &*time;
        for mut ball in (&mut ball).join() {
            // update ball position
            ball.pos += ball.velocity * time.dt as f32;

            // resolve ball / wall collisions
            if ball.pos.x.abs() > ball.bounds.x { ball.velocity.x *= -1.0; }
            if ball.pos.y.abs() > ball.bounds.y { ball.velocity.y *= -1.0; }

            // resolve ball / paddle collisions
            for (paddle, box_transform) in (&paddle, &transforms).join() {

            }
        }
        for (ball, mut transform) in (&ball, &mut transforms).join() {
            transform.pos.x = ball.pos.x;
            transform.pos.y = ball.pos.y;
        }
    }
}
