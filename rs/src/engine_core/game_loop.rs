use specs;
use glium;

pub trait GameDelegate {
    fn setup_renderer (&mut self, display: glium::Display, dispatcher: &mut specs::DispatcherBuilder);
    fn register_components (&mut self, world: &mut specs::World);
    fn register_systems (&mut self, dispatcher: &mut specs::DispatcherBuilder);
    fn handle_event (&mut self, event: &glutin::Event, game_state: &mut GameLoopState);
    fn on_begin_frame (&mut self);
    fn on_end_frame (&mut self);
    fn teardown (&mut self);
}
impl GameDelegate {
    pub fn run (&mut self) {
        GameLoop::new(self).run(self);
    }
}

pub struct GameLoopState { pub running: bool }
struct GameLoop<'a, 'b> {
    ecs: specs::World,
    dispatcher: specs::Dispatcher<'a, 'b>,
    events_loop: glium::glutin::EventsLoop,
    state: GameLoopState,
}
impl<'a, 'b> GameLoop <'a, 'b> {
    fn new (game_delegate: &mut GameDelegate) -> GameLoop<'a, 'b> {
        use glium::glutin;
        let events_loop = glutin::EventsLoop::new();
        let wb = glutin::WindowBuilder::new();
        let cb = glutin::ContextBuilder::new();
        let display = glium::Display::new(wb, cb, &events_loop).unwrap();
        let mut ecs = specs::World::new();
        let mut dispatcher = specs::DispatcherBuilder::new();
        game_delegate.setup_renderer(display, &mut dispatcher);
        game_delegate.register_components(&mut ecs);
        game_delegate.register_systems(&mut dispatcher);
        let dispatcher = dispatcher.build();
        return GameLoop {
            ecs,
            dispatcher,
            events_loop,
            state: GameLoopState { running: true }
        }
    }
    fn run (&mut self, game_delegate: &mut GameDelegate) {
        self.state.running = true;
        while self.state.running {
            game_delegate.on_begin_frame();
            self.dispatcher.dispatch(&mut self.ecs.res);
            let mut state = &mut self.state;
            self.events_loop.poll_events(|ev| {
                game_delegate.handle_event(&ev, &mut state);
                match ev {
                    glutin::Event::WindowEvent { event, .. } => match event {
                        glutin::WindowEvent::CloseRequested => state.running = false,
                        _ => ()
                    },
                    _ => ()
                }
            });
            game_delegate.on_end_frame();
        }
        game_delegate.teardown();
    }
}
