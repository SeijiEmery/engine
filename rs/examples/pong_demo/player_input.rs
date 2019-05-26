use engine_rs::{Time};
use glutin;
use std::collections::HashMap;

pub enum PlayerKeyBindings { None, Arrows, WASD }
impl Default for PlayerKeyBindings { fn default() -> PlayerKeyBindings { PlayerKeyBindings::None } }
fn pressed_left (keybindings: &PlayerKeyBindings, key: &glutin::VirtualKeyCode) -> bool {
    match keybindings {
        PlayerKeyBindings::None => false,
        PlayerKeyBindings::Arrows => match key { glutin::VirtualKeyCode::Left => true, _ => false },
        PlayerKeyBindings::WASD => match key { glutin::VirtualKeyCode::A => true, _ => false },
    }
}
fn pressed_right (keybindings: &PlayerKeyBindings, key: &glutin::VirtualKeyCode) -> bool {
    match keybindings {
        PlayerKeyBindings::None => false,
        PlayerKeyBindings::Arrows => match key { glutin::VirtualKeyCode::Right => true, _ => false },
        PlayerKeyBindings::WASD => match key { glutin::VirtualKeyCode::D => true, _ => false },
    }
}

#[derive(Default)]
pub struct PlayerInputState {
    left_pressed: bool, right_pressed: bool,
    velocity: f64,
    keybindings: PlayerKeyBindings,
}
impl PlayerInputState {
    pub fn new (keybindings: PlayerKeyBindings) -> PlayerInputState {
        PlayerInputState { left_pressed: false, right_pressed: false, velocity: 0.0, keybindings }
    }
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
                if pressed_left(&self.keybindings, key) {
                    self.left_pressed = match state {
                        glutin::ElementState::Pressed => true,
                        glutin::ElementState::Released => false
                    };
                }
                if pressed_right(&self.keybindings, key) {
                    self.right_pressed = match state {
                        glutin::ElementState::Pressed => true,
                        glutin::ElementState::Released => false
                    };
                }
            },
            _ => ()
        }
    }
}

#[derive(Default)]
pub struct MultiplayerInput {
    pub player1: PlayerInputState,
    pub player2: PlayerInputState,
}
impl MultiplayerInput {
    pub fn update (&mut self, time: &Time) {
        self.player1.update(time);
        self.player2.update(time);
    }
    pub fn on_event (&mut self, event: &glutin::Event) {
        self.player1.on_event(event);
        self.player2.on_event(event);
    }
    pub fn get (&self, player: i32) -> Option<&PlayerInputState> {
        match player {
            1 => Some(&self.player1),
            2 => Some(&self.player2),
            _ => None
        }
    }
}
