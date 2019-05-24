use crate::engine_utils::math::*;

#[derive(Debug)]
pub struct Camera {
    pub camera_view_transform: Mat4,
    pub game_to_camera_units: Mat4,
}
impl Camera {
    fn new () -> Camera {
        return Camera {
            camera_view_transform: Matrix4::identity(),
            game_to_camera_units: Matrix4::identity()
        }
    }
}
impl Default for Camera {
    fn default () -> Camera {
        return Camera::new()
    }
}



pub type ActiveCamera = Camera;
