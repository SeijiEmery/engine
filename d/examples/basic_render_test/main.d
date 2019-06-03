import engine: runGame, WindowEvent, EntityManager, SystemManager;
import engine.renderer;
import engine.utils.math;
import engine.utils.color;
import std.stdio;
import engine.ecs.transform;


//mixin describeGame!((ref GameInstance game) {
//    writefln("initializing...");
//    auto box = game.createEntity()
//        .with!Position(vec2(0.0, 0.0))
//        .with!Transform
//        .with!Renderable;

//    scope(exit) {
//        writefln("terminating...");
//    }
//    onEvent!((GameEvent event) {
//        event.tryVisit!(
//            (WindowEvent event) => event.tryVisit!(
//                (KeyInputEvent event) { writefln("got key event %s", event); },
//            ),
//        );
//    });
//    eachFrame!((ref Frame frame){
//        writefln("frame %d at %s, %s fps (%s)", frame.id, frame.time, frame.fps, frame.dt);
//        frame.renderer.drawBox(mat4.identity, color("red"));
//    });
//    runGame();
//});

//void runRenderTest (ref GameInstance game) {
//    void onExit () { writefln("terminating..."); }
//    void onFrame (ref GameFrame frame) { }
//    void onEvent (GameEvent event) {

//    }
//    game.withMethods!(onExit, onFrame, onEvent);
//    game.start();
//}
//mixin runGame!runRenderTest;

struct BasicRenderTest {
    void registerComponents (ref EntityManager entities) {}
    void registerSystems (ref SystemManager) {}
    void handleEvent (WindowEvent event) {}
    void render (Renderer)(ref Renderer renderer) {
        renderer.drawBox(mat4.identity, color("#ff0000"));
        renderer.drawBoxOutline(mat4.identity, color("#00ff00"), 0.1);
        renderer.drawCircle(mat4.identity, color("#0000ff"));
        renderer.drawCircleOutline(mat4.identity, color("#ffff00"), 0.1);
    }
    void onBeginFrame () {}
    void onEndFrame () {}
    void teardown () {
        writefln("terminating...");
    }
}
mixin runGame!BasicRenderTest;

//mixin launchGame!((ref GameInstance game) {
    
//});
