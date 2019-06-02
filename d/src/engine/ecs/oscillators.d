module engine.ecs.oscillators;
import engine.ecs.transform;
import engine.ecs.color;
import engine.core.ecs;
import engine.utils.math;

@component struct Rotater             { float speed = 1.0; }
@component struct TranslateOscillator { vec2 a, b; float speed = 1.0; }
@component struct ScaleOscillator     { vec2 a, b; float speed = 1.0; }
@component struct DepthOscillator     { vec2 a, b; float speed = 1.0; }
@component struct ColorOscillator     { vec4 a, b; float speed = 1.0; }
