//#[macro_use]
//use specs_derive;
use specs;
use specs::prelude::*;


#[derive(Component)]
#[storage(VecStorage)]
pub struct Transform {
    pos: (f32, f32),
    scale: f32,
    rot: f32,
}
impl Transform {
    fn new () -> Transform {
        return Transform {
            pos: (0.0, 0.0),
            scale: 1.0,
            rot: 0.0
        }
    }
    fn with_pos (&self, x: f32, y: f32) -> Transform {
        return Transform { pos: (x, y), scale: self.scale, rot: self.rot };
    }
    fn with_scale (&self, s: f32) -> Transform {
        return Transform { pos: self.pos, scale: s, rot: self.rot };
    }
    fn with_angle (&self, r: f32) -> Transform {
        return Transform { pos: self.pos, scale: self.scale, rot: r };
    }
}
