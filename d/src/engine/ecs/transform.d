module engine.ecs.transform;
import engine.core.ecs;
import engine.utils.math;

@component struct Position { vec3 pos = vec3(0, 0, 0); }
@component struct Rotation { float angle = 0.0; }
@component struct Scale    { vec2 scale = vec2(1, 1); }
@component struct WorldTransform { mat4 matrix; }

class TransformSystem : System {
    override void run (EntityManager entities, EventManager events, Duration dt) {
        foreach (entity, worldTransform, position, rot, scale; 
                entities.entitiesWith!(WorldTransform, Position, Rotation, Scale)
        ) {
            auto cos_theta = rot.angle.cos;
            auto sin_theta = rot.angle.sin;
            auto s = scale.scale;
            auto pos = position.pos;
            worldTransform.matrix = mat4(
                s.x * cos_theta, s.x * -sin_theta, 0.0, 0.0,
                s.y * sin_theta, s.y * cos_theta, 0.0, 0.0,
                0.0, 0.0, 1.0, 0.0,
                pos.x, pos.y, pos.z, 1.0
            );
        }
    }
}
