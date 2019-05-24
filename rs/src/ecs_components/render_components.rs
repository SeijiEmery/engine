//#[macro_use]
//use specs_derive;
use specs::prelude::*;
use crate::engine_utils::color::{Color};

#[derive(Component)]
#[storage(VecStorage)]
pub struct MaterialComponent {
    pub color: Color
}
impl MaterialComponent {
    pub fn new (r: f32, g: f32, b: f32, a: f32) -> MaterialComponent {
        return MaterialComponent {
            color: Color { r, g, b, a }
        };
    }
}


pub struct BoxShape { pub w: f32, pub h: f32 }
pub struct CircleShape { pub r: f32 }

#[derive(Component)]
#[storage(VecStorage)]
pub enum ShapeComponent {
    Box(BoxShape),
    Circle(CircleShape),
}

#[derive(Component)]
#[storage(VecStorage)]
pub struct ShapeRendererComponent {
    pub visible: bool,
    pub outline: Option<f32>
}
