use engine_rs::{Time, TransformComponent, Vec2, Vec3, vec3, vec2, CircleShape, Rad, ShapeComponent, BoxShape,
                ShapeRendererComponent, MaterialComponent, Color};
use specs::{Entity, World, Read, ReadStorage, WriteStorage, VecStorage, DispatcherBuilder,
            Component, System, Join, EntityBuilder };
use crate::player_input::MultiplayerInput;
use specs::world::Builder;

pub fn register_entities (entities: &mut World) {
    entities.register::<BallComponent>();
}
pub fn register_systems (systems: &mut DispatcherBuilder) {
    systems.add(BallPhysicsSystem{}, "ball paddle collision", &[]);
//    systems.add(PongPhysicsSystem{}, "pong physics system", &[]);
}
pub fn make_ball (entities: &mut World, pos: Vec2, velocity: Vec2, bounds: Vec2, color: Vec3, radius: f32) -> Entity {
    entities.create_entity()
        .with(BallComponent { velocity, bounds })
        .with(TransformComponent { pos: vec3(pos.x, pos.y, 1.0), scale: vec2(radius, radius), rot: Rad(0.0) })
        .with(ShapeComponent::Circle(CircleShape{ r: radius }))
        .with(ShapeRendererComponent { visible: true, outline: None })
        .with(MaterialComponent { color: Color { r: color.x, g: color.y, b: color.z, a: 1.0 } })
        .build()
}

pub struct BallComponent { velocity: Vec2, bounds: Vec2 }
impl Component for BallComponent { type Storage = VecStorage<BallComponent>; }

struct BallPhysicsSystem {}
impl<'a> System<'a> for BallPhysicsSystem {
    type SystemData = (
        Read<'a, Time>,
        WriteStorage<'a, BallComponent>,
        WriteStorage<'a, TransformComponent>
    );
    fn run (&mut self, (time, mut ball, mut transform): Self::SystemData) {
        let time = &*time;
        for (mut ball, mut transform) in (&mut ball, &mut transform).join() {
            let mut newpos = transform.pos + vec3(ball.velocity.x, ball.velocity.y, 0.0) * (time.dt as f32);
            if newpos.x < -ball.bounds.x {
//                newpos.x = -ball.bounds.x - newpos.x;
                ball.velocity.x *= -1.0;
            }
            if newpos.x > ball.bounds.x {
//                newpos.x = ball.bounds.x - newpos.x;
                ball.velocity.x *= -1.0;
            }
            if newpos.y < -ball.bounds.y {
//                newpos.y = -ball.bounds.y - newpos.y;
                ball.velocity.y *= -1.0;
            }
            if newpos.y > ball.bounds.y {
//                newpos.y = ball.bounds.y - newpos.y;
                ball.velocity.y *= -1.0;
            }
            transform.pos = newpos;
        }
    }
}
