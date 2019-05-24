extern crate engine_rs;
use engine_rs::engine_core::game_loop::{GameDelegate, GameLoopState};
use engine_rs::make_glium_renderer;
use engine_rs::Renderer;
use std::rc::Rc;
use specs;

struct RenderTest {
    renderer: Rc<Renderer>,
}
impl GameDelegate for RenderTest {
    fn setup_renderer (&mut self, display: glium::Display, dispatcher: &mut specs::DispatcherBuilder) {
        self.renderer = Rc::new(make_glium_renderer(display));
    }
    fn register_components (&mut self, world: &mut specs::World) {



    }
    fn register_systems (&mut self, dispatcher: &mut specs::DispatcherBuilder) {}
    fn handle_event (&mut self, event: &glium::glutin::Event, game_state: &mut GameLoopState) {
        println!("Got event {:?}", event);
    }
    fn on_begin_frame (&mut self) {}
    fn on_end_frame (&mut self) {}
    fn teardown (&mut self) {
        println!("terminating...");
    }
}

fn main () {
    let mut game = RenderTest { renderer: None };
    let game_ref : &mut GameDelegate = &mut game;
    game_ref.run();
}
