//#[macro_use]
//use specs_derive;
use specs::prelude::*;
use crate::engine_utils::color::{Color};

#[derive(Component)]
#[storage(VecStorage)]
pub struct MaterialComponent {
    pub color: Color
}
pub struct BoxShape { w: f32, h: f32 }
pub struct CircleShape { r: f32 }

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
