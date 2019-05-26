use specs;
use glium;
use crate::render_backends::{Renderer, RendererBackend, make_glium_renderer};
use crate::engine_core::time::{GameTime, Time};

pub trait GameDelegate {
    fn register_components (&mut self, world: &mut specs::World);
    fn register_systems (&mut self, dispatcher: &mut specs::DispatcherBuilder, renderer: &mut RendererBackend);
    fn handle_event (&mut self, event: &glutin::Event, game_state: &mut GameLoopState);
    fn on_begin_frame (&mut self);
    fn on_end_frame (&mut self);
    fn teardown (&mut self);
}
impl GameDelegate {
    pub fn run (&mut self) {
        GameLoop::new(self).run(self);
    }
    pub fn launch <T>() where T: 'static, T: GameDelegate, T: Default {
        let mut game : T = Default::default();
        let game_delegate : &mut GameDelegate = &mut game;
        game_delegate.run();
    }
}
#[macro_export]
macro_rules! run_game {
    ( $GameDg:ident ) => {
        fn main () { GameDelegate::launch::<$GameDg>(); }
    }
}

pub struct GameLoopState {
    pub running: bool,
    pub time: GameTime,
}
pub struct GameLoop<'a, 'b> {
    ecs: specs::World,
    dispatcher: specs::Dispatcher<'a, 'b>,
    renderer: RendererBackend,
    events_loop: glium::glutin::EventsLoop,
    state: GameLoopState,
}
impl<'a, 'b> GameLoop <'a, 'b> {
    fn new (game_delegate: &mut GameDelegate) -> GameLoop<'a, 'b> {
        let time = GameTime::new();
        let events_loop = glutin::EventsLoop::new();
        let wb = glutin::WindowBuilder::new();
        let cb = glutin::ContextBuilder::new();
        let display = glium::Display::new(wb, cb, &events_loop).unwrap();
        let mut ecs = specs::World::new();
        let mut dispatcher = specs::DispatcherBuilder::new();
        let mut renderer = make_glium_renderer(display);

        ecs.add_resource(Time::new());
        game_delegate.register_components(&mut ecs);
        game_delegate.register_systems(&mut dispatcher, &mut renderer);
        let dispatcher = dispatcher.build();
        return GameLoop {
            ecs,
            renderer,
            dispatcher,
            events_loop,
            state: GameLoopState {
                running: true,
                time
            }
        }
    }
    fn run (&mut self, game_delegate: &mut GameDelegate) {
        self.state.running = true;
        while self.state.running {
            // Calculate / update framerate, delta time, and simulation stuff
            let mut state = &mut self.state;
            state.time.begin_frame();
            state.time.update(&mut *self.ecs.write_resource::<Time>());

//            let now = state.time.absolute_time_since_started();
//            state.time.current_fps().map(|fps| println!("time = {:?}, dt = {:?}, avg dt = {:?}, framerate = {:?}",
//                                                        now, state.time.delta_time(), state.time.avg_delta_time(), fps));

            // Run on_begin_frame() user code (after updating time info)
            game_delegate.on_begin_frame();

            // Acquire frame context to begin rendering
            self.renderer.begin_frame();

            // Update all systems (the bulk of the work happens here)
            self.dispatcher.dispatch(&mut self.ecs.res);

            // Run event handlers
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

            // End the frame update
            game_delegate.on_end_frame();
            state.time.end_frame();
            self.renderer.end_frame();
        }
        // Run teardown() event for user code before exiting
        game_delegate.teardown();
    }
}
