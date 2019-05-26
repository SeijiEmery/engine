use std::{time, thread};
use glium::Frame;
use spin_sleep;

const TARGET_FRAMERATE : f64 = 60.0;
const FRAMERATE_DYNAMIC_TARGET_SWITCHING_RATE : f64 = 0.9;
const FRAMERATE_OVERSHOOT_FACTOR : f64 = 1.03;
//const TARGET_FRAMERATE : f64 = 100.0;

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
pub struct FrameRateLimiter {
    target_frame_interval: time::Duration,
    dynamic_target: time::Duration,
}
impl FrameRateLimiter {
    pub fn new (target_fps: f64) -> FrameRateLimiter {
        let mut limiter = FrameRateLimiter {
            target_frame_interval: time::Duration::from_secs(0),
            dynamic_target: time::Duration::from_secs(0),
        };
        limiter.set_target_fps(target_fps);
        limiter
    }
    pub fn target_fps (&self) -> f64 {
        1.0 / to_f64(self.target_frame_interval)
    }
    pub fn set_target_fps (&mut self, target_fps: f64) {
        self.target_frame_interval = time::Duration::from_nanos((1.0e9 / target_fps) as u64);
        self.dynamic_target = self.target_frame_interval;
    }
    pub fn update (&mut self, last_frame_interval: time::Duration) {
        let target_hard_adjust = to_f64(self.target_frame_interval)
            / to_f64(last_frame_interval) / FRAMERATE_OVERSHOOT_FACTOR;
        let target_soft_adjust = 1.0 - (1.0 - target_hard_adjust) * FRAMERATE_DYNAMIC_TARGET_SWITCHING_RATE;
        let new_target = multiply_f64(self.dynamic_target, target_soft_adjust);
        println!("adjusting dynamic target from {:?} -> {:?} ({:?} / {:?} = {:?} hard => {:?} soft",
                 self.dynamic_target, new_target,
                self.target_frame_interval, last_frame_interval,
                target_hard_adjust, target_soft_adjust);
        self.dynamic_target = new_target;
    }
    pub fn maybe_sleep_to_hit_framerate_target (&mut self, time_elapsed: time::Duration) {
        if self.target_frame_interval > time_elapsed && self.dynamic_target > time_elapsed {
            let dur = self.dynamic_target - time_elapsed;
            spin_sleep::sleep(dur);
        }
    }
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
            framerate_limiter: FrameRateLimiter::new(TARGET_FRAMERATE),
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
        let last_frame_interval = self.instant_last_frame_ended.map(|t0| now - t0);
        let current_time_elapsed = self.instant_this_frame_started.map(|t0| now - t0).unwrap();
        self.instant_last_frame_ended = Some(now);

        if last_frame_interval.is_some() {
            self.framerate_limiter.update(last_frame_interval.unwrap());
        }
        self.framerate_limiter.maybe_sleep_to_hit_framerate_target(current_time_elapsed);
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
