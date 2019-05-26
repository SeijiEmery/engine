use std::{time, thread};
use glium::Frame;

const SLEEP_THRESHOLD : time::Duration = time::Duration::from_millis(3);
const SLEEP_OVERHEAD : time::Duration = time::Duration::from_millis(3);
const SPINLOCK_THRESHOLD : time::Duration = time::Duration::from_millis(1);

#[derive(Default, Debug)]
pub struct Time {   // all values in seconds
    total_game_time:        f64,    // total time (accumulated), realtime
    total_simulation_time:  f64,    // simulation time spent (varies according to simulation rate)
    dt:                     f64,    // current delta time (realtime)
    avg_dt:                 f64,    // current delta time (realtime, averaged)
    sim_dt:                 f64,    // current delta time in the simulation
}
// duration_float isn't standard yet -_-
fn to_f64 (duration: time::Duration) -> f64 {
    return ((duration.as_micros() as u64) as i64) as f64 * (1e-6 as f64)
}
fn multiply_f64 (duration: time::Duration, value: f64) -> time::Duration {
    return time::Duration::from_micros(
        (((duration.as_micros() as u64) as i64) as f64 * value) as u64
    );
}
#[derive(Debug, Clone)]
pub enum FrameRateLimiter {
    None,
    SpinLockAt(time::Duration),
    SleepAt(time::Duration),
}
pub struct GameTime {
    instant_game_started:       time::Instant,
    instant_this_frame_started: Option<time::Instant>,
    instant_last_frame_ended:   Option<time::Instant>,
    total_game_time:            time::Duration,
    total_simulation_time:      time::Duration,
    current_delta_time:         Option<time::Duration>,
    avg_delta_time:             Option<time::Duration>,
    current_sim_delta_time:     Option<time::Duration>,
    avg_carry_factor:           f64,
    simulation_speed:           f64,
    framerate_limiter:          FrameRateLimiter,
}
impl GameTime {
    pub fn new () -> GameTime {
        return GameTime {
            instant_game_started: time::Instant::now(),
            instant_this_frame_started: None,
            instant_last_frame_ended: None,
            total_game_time: time::Duration::from_secs(0),
            total_simulation_time: time::Duration::from_secs(0),
            current_delta_time: None,
            current_sim_delta_time: None,
            avg_delta_time: None,
            avg_carry_factor: 0.9,
            simulation_speed: 1.0,
            framerate_limiter: FrameRateLimiter::SleepAt(time::Duration::from_nanos((1e9 / 60.0) as u64)),
        }
    }
    pub fn begin_frame (&mut self) {
        let now = time::Instant::now();
        self.instant_this_frame_started.map(|t0| {
            let dt = now - t0;
            let sim_dt = multiply_f64(dt, self.simulation_speed);
            self.current_delta_time = Some(dt);
            self.current_sim_delta_time = Some(sim_dt);
            self.avg_delta_time = Some(match self.avg_delta_time {
                Some(avg) =>
                    multiply_f64(avg, self.avg_carry_factor) +
                        multiply_f64(dt, 1.0 - self.avg_carry_factor),
                None => dt
            });
            self.total_game_time += dt;
            self.total_simulation_time += sim_dt;
        });
        self.instant_this_frame_started = Some(now);
    }
    pub fn end_frame (&mut self) {
        let now = time::Instant::now();
        self.instant_last_frame_ended = Some(now);
        let time_elapsed = now - self.instant_this_frame_started.unwrap();
        match self.framerate_limiter {
            FrameRateLimiter::None => (),
            FrameRateLimiter::SpinLockAt(target_frame_time) => {
                if (target_frame_time > time_elapsed + SPINLOCK_THRESHOLD) {
                    
                }
            },
            FrameRateLimiter::SleepAt(target_frame_time) => {
                if (target_frame_time > time_elapsed + SLEEP_THRESHOLD) {
                    let dur : time::Duration = target_frame_time - time_elapsed - SLEEP_OVERHEAD;
                    println!("sleeping for {:?} ({:?} - {:?} - {:?})",
                             dur, target_frame_time, time_elapsed, SLEEP_OVERHEAD);
                    let t0 = time::Instant::now();
                    thread::sleep(dur);
                    let t1 = time::Instant::now();
                    println!("actually slept for {:?}", t1 - t0);
                }
            }
        }
    }
    pub fn delta_time (&self) -> time::Duration {
        return match self.current_delta_time {
            Some(dt) => dt,
            None => time::Duration::from_millis(0),
        }
    }
    pub fn sim_delta_time (&self) -> time::Duration {
        return match self.current_sim_delta_time {
            Some(dt) => dt,
            None => time::Duration::from_millis(0)
        }
    }
    pub fn avg_delta_time (&self) -> time::Duration {
        return match self.avg_delta_time {
            Some(dt) => dt,
            None => time::Duration::from_millis(0),
        }
    }
    pub fn absolute_time_since_started (&self) -> time::Duration {
        return time::Instant::now() - self.instant_game_started;
    }
    pub fn accumulated_time_since_started (&self) -> time::Duration {
        return self.total_game_time;
    }
    pub fn accumulated_simulation_time (&self) -> time::Duration {
        return self.total_simulation_time;
    }
    pub fn current_fps (&self) -> Option<f64> {
        return self.avg_delta_time.map(|dt| 1.0 / to_f64(dt));
    }
    pub fn update (&self, time: &mut Time) {
        time.total_game_time = to_f64(self.accumulated_time_since_started());
        time.total_simulation_time = to_f64(self.accumulated_simulation_time());
        time.dt = to_f64(self.delta_time());
        time.avg_dt = to_f64(self.avg_delta_time());
        time.sim_dt = to_f64(self.sim_delta_time());
    }
    pub fn set_simulation_speed (&mut self, speed: f64) {
        self.simulation_speed = speed;
    }
    pub fn get_simulation_speed (&self) -> f64 {
        return self.simulation_speed;
    }
    pub fn set_framerate_limit (&mut self, limiter: FrameRateLimiter) {
        self.framerate_limiter = limiter;
    }
    pub fn get_framerate_limit (&self) -> FrameRateLimiter {
        return self.framerate_limiter.clone();
    }
}
