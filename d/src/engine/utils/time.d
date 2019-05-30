module engine.utils.time;
import engine.utils.maybe;
import std.datetime: StopWatch;
import std.exception: enforce;
import core.time;

/// Frame-specific time information useful for gameplay elements
struct Time {
    double totalGameTime = 0.0;
    double totalSimulationTime = 0.0;
    double deltaTime = 0.0;
    double avgDeltaTime = 0.0;
    double simDeltaTime = 0.0;
}

immutable double DT_AVERAGE_CARRY_FACTOR = 0.9;
immutable double TARGET_FRAME_RATE = 60.0;
immutable Duration TARGET_FRAME_INTERVAL = (cast(long)(1e9 / TARGET_FRAME_RATE)).nsecs;

double toFloatSecs (Duration duration) { return cast(double)duration.total!"hnsecs" * 1e-7; }
Duration fromFloatSecs (double secs) { return (cast(long)(1e7 * secs)).hnsecs; }
unittest {
    assert(5.secs.toFloatSecs == 5.0);
    assert(5.0.fromFloatSecs == 5.secs);
}

/// Internal time tracker
struct TimeTracker {
    private MonoTime       gameStartTime;
    private Maybe!MonoTime gameInitFinishTime;
    private Maybe!MonoTime frameStartTime;
    private Maybe!MonoTime frameEndTime;
    private Maybe!Duration currentDeltaTime;
    private Maybe!double   currentAvgDeltaTime;
    private Duration       accumulatedRealTime = Duration.zero;
    private Duration       accumulatedSimTime = Duration.zero;
    private double         currentSimTimeRate = 1.0;

    this (this) {
        gameStartTime = MonoTime.currTime;
    }

    Duration absoluteTime () { return (MonoTime.currTime - gameStartTime); }
    Duration timeAtFrameStart () { return (frameStartTime.unwrap - gameStartTime); }
    Duration simTime () { return accumulatedSimTime; }
    Maybe!Duration deltaTime () { return currentDeltaTime; }
    Maybe!Duration avgDeltaTime () { return currentAvgDeltaTime.map((double dt) => dt.fromFloatSecs); }
    Maybe!Duration simDeltaTime () { 
        return deltaTime.map((Duration dt) => (dt.toFloatSecs * currentSimTimeRate).fromFloatSecs);
    }
    Duration startupTime () { return (gameStartTime - gameInitFinishTime.unwrap); }

    void initFinished () {
        gameInitFinishTime = just(MonoTime.currTime);
    }
    void beginFrame () {
        auto now = MonoTime.currTime;
        frameStartTime.map((MonoTime t0) {
            auto dt = now - t0;
            currentDeltaTime = just(dt);
            if (currentAvgDeltaTime.isSome) {
                currentAvgDeltaTime = just(currentAvgDeltaTime.unwrap * DT_AVERAGE_CARRY_FACTOR +
                    dt.toFloatSecs * (1 - DT_AVERAGE_CARRY_FACTOR));
            } else {
                currentAvgDeltaTime = just(dt.toFloatSecs);
            }
            accumulatedRealTime += dt;
            accumulatedSimTime += (dt.toFloatSecs * currentSimTimeRate).fromFloatSecs;
        });
        frameStartTime = just(now);
    }
    void endFrame () {
        auto now = MonoTime.currTime;
        frameEndTime.map((MonoTime t0) {});
        frameEndTime = just(now);
    }
    void update (ref Time time) {
        enforce(frameStartTime.isSome, "must call beginFrame() before update()!");
        time.totalGameTime = timeAtFrameStart.toFloatSecs;
        time.totalSimulationTime = simTime.toFloatSecs;
        time.deltaTime = deltaTime.withDefault(TARGET_FRAME_INTERVAL).toFloatSecs;
        time.avgDeltaTime = avgDeltaTime.withDefault(TARGET_FRAME_INTERVAL).toFloatSecs;
        time.simDeltaTime = simDeltaTime.map((Duration dt) => dt.toFloatSecs).withDefault(time.deltaTime);
    }
}
