use engine_rs::{Time, TransformComponent, Vec2, Vec3, vec3, Rad, ShapeComponent, BoxShape,
                ShapeRendererComponent, MaterialComponent, Color};
use specs::{Entity, World, Read, ReadStorage, WriteStorage, VecStorage, DispatcherBuilder,
            Component, System, Join, EntityBuilder };
use crate::player_input::MultiplayerInput;
use crate::ball::PaddleComponent;
use specs::world::Builder;

pub fn register_entities (entities: &mut World) {
    entities.register::<PlayerComponent>();
    entities.register::<TransformComponent>();
    entities.register::<ShapeComponent>();
    entities.register::<ShapeRendererComponent>();
    entities.register::<MaterialComponent>();
}
pub fn register_systems (systems: &mut DispatcherBuilder) {
    systems.add(PlayerInputSystem{}, "player input", &[]);
}
pub fn make_player (entities: &mut World, id: i32, speed: f32, color: Vec3, position: f32, bounds: f32, scale: Vec2) -> Entity {
    entities.create_entity()
        .with(PlayerComponent { id, speed, min_x: -bounds, max_x: bounds })
        .with(PaddleComponent{})
        .with(TransformComponent { pos: vec3(0.0, position, 1.0), scale, rot: Rad(0.0) })
        .with(ShapeComponent::Box(BoxShape{ w: scale.x, h: scale.y }))
        .with(ShapeRendererComponent { visible: true, outline: None })
        .with(MaterialComponent { color: Color { r: color.x, g: color.y, b: color.z, a: 1.0 } })
        .build()
}

pub struct PlayerComponent { id: i32, min_x: f32, max_x: f32, speed: f32 }
impl Component for PlayerComponent { type Storage = VecStorage<PlayerComponent>; }

struct PlayerInputSystem {}
impl<'a> System<'a> for PlayerInputSystem {
    type SystemData = (
        Read<'a, Time>,
        Read<'a, MultiplayerInput>,
        ReadStorage<'a, PlayerComponent>,
        WriteStorage<'a, TransformComponent>
    );
    fn run (&mut self, (time, input, player, mut transform): Self::SystemData) {
        let time = &*time;
        let input = &*input;
        for (player, mut transform) in (&player, &mut transform).join() {
            let input = input.get(player.id).unwrap();
            let mut x = transform.pos.x + player.speed * input.dir() * (time.dt as f32);
            if x < player.min_x { x = player.min_x; }
            if x > player.max_x { x = player.max_x; }
            transform.pos.x = x;
        }
    }
}
