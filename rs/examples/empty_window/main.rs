//#[macro_use]
extern crate engine_rs;
use engine_rs::{GameDelegate, GameLoopState, RendererBackend};
use engine_rs::*;

#[derive(Default)]
struct EmptyWindow {}
impl GameDelegate for EmptyWindow {
    fn register_components (&mut self, _world: &mut specs::World) {}
    fn register_systems (&mut self, _dispatcher: &mut specs::DispatcherBuilder, _renderer: &mut RendererBackend) {}
    fn handle_event (&mut self, event: &glium::glutin::Event, _game_state: &mut GameLoopState) {
        println!("Got event {:?}", event);
    }
    fn on_begin_frame (&mut self, _game_state: &mut GameLoopState) {}
    fn on_end_frame (&mut self, _game_state: &mut GameLoopState) {}
    fn teardown (&mut self, _game_state: &mut GameLoopState) {
        println!("terminating...");
    }
}
run_game!(EmptyWindow);
