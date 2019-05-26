//#[macro_use]
//use specs_derive;
use specs;
use specs::prelude::*;
//use crate::engine_utils::*;
use crate::engine_utils::{Vec3, Vec2, Rad, Vector2, Vector3, Mat4, Camera};

#[derive(Component)]
#[storage(VecStorage)]
pub struct TransformComponent {
    pub pos:    Vec3,
    pub scale:  Vec2,
    pub rot:    Rad<f32>,
}
impl TransformComponent {
    pub fn new () -> TransformComponent {
        return TransformComponent {
            pos: Vector3 { x: 0.0, y: 0.0, z: 0.0 },
            scale: Vector2 { x: 1.0, y: 1.0 },
            rot: Rad(0.0)
        }
    }
    pub fn with_pos (&self, x: f32, y: f32) -> TransformComponent {
        return TransformComponent { pos: Vector3 { x, y, z: 0.0 }, scale: self.scale, rot: self.rot };
    }
    pub fn with_scale (&self, s: f32) -> TransformComponent {
        return TransformComponent { pos: self.pos, scale: Vector2 { x: s, y: s }, rot: self.rot };
    }
    pub fn with_angle (&self, r: f32) -> TransformComponent {
        return TransformComponent { pos: self.pos, scale: self.scale, rot: Rad(r) };
    }
    pub fn local_to_world_space_matrix (&self) -> Mat4 {
        let cos_theta = self.rot.0.cos();
        let sin_theta = self.rot.0.sin();
        return Mat4::new(
            self.scale.x * cos_theta, self.scale.y * -sin_theta, 0.0, 0.0,
            self.scale.x * sin_theta, self.scale.y * cos_theta, 0.0, 0.0,
            0.0, 0.0, 1.0, 0.0,
            self.pos.x, self.pos.y, self.pos.z, 1.0
        );
//        return Mat4::new(
//            self.scale.x * cos_theta, sin_theta, 0.0, self.pos.x,
//            -sin_theta, self.scale.y * cos_theta, 0.0, self.pos.y,
//            0.0, 0.0, 1.0, self.pos.z,
//            0.0, 0.0, 0.0, 1.0
//        );
    }
    pub fn local_to_camera_space_matrix (&self, _camera: &Camera) -> Mat4 {
        return self.local_to_world_space_matrix();
    }
}
