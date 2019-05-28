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
    systems.add(DebugMakeBallFollowCursorSystem{}, "ball debug", &[]);
    systems.add(BallPhysicsSystem{}, "ball paddle collision", &[]);
//    systems.add(PongPhysicsSystem{}, "pong physics system", &[]);
}
pub fn make_ball (entities: &mut World, pos: Vec2, velocity: Vec2, acceleration_per_minute: f32, bounds: Vec2, color: Vec3, size: f32) -> Entity {
    let enable_movement = true;
    let radius = size * 0.5;
    let acceleration_rate = acceleration_per_minute / 60.0;
    entities.create_entity()
        .with(BallComponent { velocity, acceleration_rate, bounds, pos, radius, enable_movement })
        .with(TransformComponent { pos: vec3(pos.x, pos.y, 1.0), scale: vec2(size, size), rot: Rad(0.0) })
        .with(ShapeComponent::Circle(CircleShape{ r: radius }))
//        .with(ShapeRendererComponent { visible: true, outline: None })
        .with(MaterialComponent { color: Color { r: color.x, g: color.y, b: color.z, a: 1.0 } })
        .build()
}

#[derive(Debug)]
pub struct BallComponent { velocity: Vec2, bounds: Vec2, pos: Vec2, radius: f32, acceleration_rate: f32, enable_movement: bool }
impl Component for BallComponent { type Storage = VecStorage<BallComponent>; }

#[derive(Debug)]
pub struct PaddleComponent {}
impl Component for PaddleComponent { type Storage = VecStorage<PaddleComponent>; }

#[derive(Debug)]
pub struct CursorTarget { pub pos: Vec2 }
impl Default for CursorTarget { fn default() -> CursorTarget { CursorTarget { pos: vec2(0.0, 0.0) } }}
pub struct DebugMakeBallFollowCursorSystem {}
impl<'a> System<'a> for DebugMakeBallFollowCursorSystem {
    type SystemData = (
        Read<'a, CursorTarget>,
        WriteStorage<'a, BallComponent>,
    );
    fn run (&mut self, (target, mut balls): Self::SystemData) {
        let target = &*target;
        for mut ball in (&mut balls).join() {
            if !ball.enable_movement {
                ball.pos = target.pos;
            }
        }
    }
}

#[derive(Default)]
pub struct AspectRatio(f32);
impl AspectRatio {
    pub fn new (aspect_ratio: f32) -> AspectRatio { AspectRatio(aspect_ratio) }
    pub fn set (&mut self, aspect_ratio: f32) {
        self.0 = aspect_ratio;
    }
}

struct BallPhysicsSystem {}
impl<'a> System<'a> for BallPhysicsSystem {
    type SystemData = (
        Read<'a, Time>,
        WriteStorage<'a, BallComponent>,
        WriteStorage<'a, TransformComponent>,
        ReadStorage<'a, PaddleComponent>,
        WriteStorage<'a, MaterialComponent>,
        Read<'a, AspectRatio>,
    );
    fn run (&mut self, (time, mut balls, mut transforms, paddles, mut materials, aspect_ratio): Self::SystemData) {
        let time = &*time;
        let aspect_ratio = (&*aspect_ratio).0;
        for mut ball in (&mut balls).join() {
            // update ball position
            let starting_pos = ball.pos;
            if ball.enable_movement {
                ball.pos += ball.velocity * time.dt as f32;
            }
            let mut changed_velocity = false;

            // resolve ball / wall collisions
            if ball.pos.x.abs() > ball.bounds.x && (ball.pos.x < 0.0) == (ball.velocity.x < 0.0) {
                changed_velocity = true;
                ball.velocity.x *= -1.0;
            }
            if ball.pos.y.abs() > ball.bounds.y && (ball.pos.y < 0.0) == (ball.velocity.y < 0.0) {
                changed_velocity = true;
                ball.velocity.y *= -1.0;
            }

            // resolve ball / paddle collisions
            for (paddle, box_transform, mut paddle_material) in (&paddles, &transforms, &mut materials).join() {
                let mut box_size = box_transform.scale * 0.5;
                let box_pos = vec2(box_transform.pos.x, box_transform.pos.y);

                let cbs = ball.pos - box_pos; // translate box into circle coords
                let cbs_abs = vec2(cbs.x.abs(), cbs.y.abs()); // abs => 1st quadrant

                // collision tests:
                if ( // 1. circle overlaps with any corner?
                    cbs_abs - box_size).magnitude() <= ball.radius
                    // 2. circle penetrates any edge along one axis AND circle center is completely
                    // within box on other axis. Need BOTH of these tests to work properly.
                    // Note: if we just did (cbs_abs - box_size).x < radius && (...).y < radius
                    // that -would- replace all of these tests BUT would give us box / box intersection,
                    // not box / circle intersection
                    || (cbs_abs.x < box_size.x + ball.radius && cbs_abs.y < box_size.y)
                    || (cbs_abs.y < box_size.y + ball.radius && cbs_abs.x < box_size.x)
                {
                    changed_velocity = true;
                    paddle_material.color = Color { r: 1.0, g: 0.0, b: 0.0, a: 1.0 };
                    if (ball.velocity.y < 0.0) == (box_transform.pos.y < 0.0) {
                        let ball_speed = ball.velocity.magnitude();
                        let hit_pos_normalized = (ball.pos.x - box_transform.pos.x) / box_transform.scale.x;
                        let up: f32 = if ball.velocity.y < 0.0 { 1.0 } else { -1.0 };
                        ball.velocity = vec2(hit_pos_normalized, up).normalize_to(ball_speed);
                    }
                } else {
                    paddle_material.color = Color { r: 1.0, g: 1.0, b: 1.0, a: 1.0 };
                }
            }
            // recalculate position if / when setting velocity (prevents the ball from clipping through things...)
            if changed_velocity {
                ball.pos = starting_pos + ball.velocity * time.dt as f32;
            }
            // update velocity (speedup ball...)
            ball.velocity += ball.velocity * ball.acceleration_rate * (time.dt as f32);
        }
        for (ball, mut transform) in (&balls, &mut transforms).join() {
            transform.pos.x = ball.pos.x;
            transform.pos.y = ball.pos.y;
            transform.scale.y = transform.scale.x * aspect_ratio;
        }
    }
}
