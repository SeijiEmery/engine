module engine.ecs.transform;
import engine.core.ecs;
import engine.utils.math;

@component struct Position { vec3 pos = vec3(0, 0, 0); }
@component struct Rotation { float angle = 0.0; }
@component struct Scale    { vec2 scale = vec2(1, 1); }
@component struct WorldTransform { mat4 matrix; }

class TransformSystem : System {
    override void run (EntityManager entities, EventManager events, Duration dt) {
        foreach (ref worldTransform, pos, rot, scale; 
                entities.entitiesWith!(WorldTransform, Position, Rotation, Scale)
        ) {

            auto cos_theta = rot.angle.cos;
            auto sin_theta = rot.angle.sin;
            auto scale = scale.scale;

            worldTransform.matrix = mat4(
                scale.x * cos_theta, scale.x * -sin_theta, 0.0, 0.0,
                scale.y * sin_theta, scale.y * cos_theta, 0.0, 0.0,
                0.0, 0.0, 1.0, 0.0,
                pos.x, pos.y, pos.z, 1.0
            );
        }
    }
}
