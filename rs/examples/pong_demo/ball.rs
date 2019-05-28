use engine_rs::{Time, TransformComponent, Vec2, Vec3, vec3, vec2, CircleShape, Rad, ShapeComponent, BoxShape,
                ShapeRendererComponent, MaterialComponent, Color};
use specs::{Entity, World, Read, ReadStorage, WriteStorage, VecStorage, DispatcherBuilder,
            Component, System, Join, EntityBuilder };
use crate::player_input::MultiplayerInput;
use specs::world::Builder;
use cgmath::InnerSpace;

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
        WriteStorage<'a, MaterialComponent>,
    );
    fn run (&mut self, (time, mut balls, mut transforms, paddles, mut materials): Self::SystemData) {
        let time = &*time;
        for mut ball in (&mut balls).join() {
            // resolve ball / wall collisions
            if ball.pos.x.abs() > ball.bounds.x && (ball.pos.x < 0.0) == (ball.velocity.x < 0.0) { ball.velocity.x *= -1.0; }
            if ball.pos.y.abs() > ball.bounds.y && (ball.pos.y < 0.0) == (ball.velocity.y < 0.0) { ball.velocity.y *= -1.0; }

            // resolve ball / paddle collisions
            for (paddle, box_transform, mut paddle_material) in (&paddles, &transforms, &mut materials).join() {
                let box_size = box_transform.scale;
                let bcs = vec2(box_transform.pos.x, box_transform.pos.y) - ball.pos; // box in circle coords

                paddle_material.color = Color { r: 1.0, g: 1.0, b: 1.0, a: 1.0 };
                if bcs.x.abs() - box_size.x < 0.0 && bcs.y.abs() - box_size.x < 0.0
                    && (ball.velocity.y < 0.0) == (box_transform.pos.y < 0.0) {
                    paddle_material.color = Color { r: 1.0, g: 0.0, b: 0.0, a: 1.0 };
                    let ball_speed = ball.velocity.magnitude();
                    let hit_pos_normalized = (ball.pos.x - box_transform.pos.x) / box_transform.scale.x;
                    let up : f32 = if ball.velocity.y <= 0.0 { 1.0 } else { -1.0 };
                    ball.velocity = vec2(hit_pos_normalized, up).normalize_to(ball_speed);
                }
            }
            // update ball position
            ball.pos += ball.velocity * time.dt as f32;
        }
        for (ball, mut transform) in (&balls, &mut transforms).join() {
            transform.pos.x = ball.pos.x;
            transform.pos.y = ball.pos.y;
        }
    }
}
