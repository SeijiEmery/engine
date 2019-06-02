module engine.ecs.shape;
import engine.core.ecs;
import engine.utils.math;

@component struct CircleShape { double radius; }
@component struct BoxShape    { vec2i size; }
