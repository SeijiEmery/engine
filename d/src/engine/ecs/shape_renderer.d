module engine.ecs.shape_renderer;
import engine.core.ecs;
import engine.renderer;
import engine.utils.math;
import engine.utils.color;
import engine.utils.maybe;
import engine.ecs.transform;
import engine.ecs.shape;

@component struct ShapeRenderer { vec4 color; Maybe!float outline; }
