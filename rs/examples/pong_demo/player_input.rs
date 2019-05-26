use engine_rs::{Time};
use glutin;

#[derive(Default)]
pub struct PlayerInput {
    left_pressed: bool,
    right_pressed: bool,
    velocity: f64
}
impl PlayerInput {
    pub fn new () -> PlayerInput { Default::default() }
    pub fn dir (&self) -> f32 { self.velocity as f32 }
    pub fn update (&mut self, time: &Time) {
        let mut dir = 0.0;
        if self.left_pressed { dir -= 1.0 }
        if self.right_pressed { dir += 1.0 }
        self.velocity -= self.velocity * 5.0 * time.dt;
        self.velocity += dir * 10.0 * time.dt;
        if self.velocity > 1.0 { self.velocity = 1.0 }
        if self.velocity < -1.0 { self.velocity = -1.0 }
    }
    pub fn on_event (&mut self, ev: &glutin::Event) {
        match ev {
            glutin::Event::WindowEvent {
                event: glutin::WindowEvent::KeyboardInput {
                    input: glutin::KeyboardInput {
                        virtual_keycode: Some(key),
                        state, ..
                    }, ..
                }, ..
            } => {
                match key {
                    glutin::VirtualKeyCode::Left | glutin::VirtualKeyCode::A => {
                        self.left_pressed = match state {
                            glutin::ElementState::Pressed => true,
                            glutin::ElementState::Released => false
                        }
                    }
                    glutin::VirtualKeyCode::Right | glutin::VirtualKeyCode::D => {
                        self.right_pressed = match state {
                            glutin::ElementState::Pressed => true,
                            glutin::ElementState::Released => false
                        }
                    }, _ => ()
                }
            },
            _ => ()
        }
    }
}