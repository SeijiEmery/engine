//#[macro_use]
extern crate engine_rs;
use engine_rs::{GameDelegate, RendererBackend, GameLoopState};
use engine_rs::*;
use specs;

#[derive(Default)]
struct RenderTest {}
impl GameDelegate for RenderTest {
    fn register_components (&mut self, _world: &mut specs::World) {}
    fn register_systems (&mut self, _dispatcher: &mut specs::DispatcherBuilder, _renderer: &mut RendererBackend) {}
    fn handle_event (&mut self, _event: &glium::glutin::Event, _game_state: &mut GameLoopState) {}
    fn on_begin_frame (&mut self) {}
    fn on_end_frame (&mut self) {}
    fn teardown (&mut self) {
        println!("terminating...");
    }
}
run_game!(RenderTest);
