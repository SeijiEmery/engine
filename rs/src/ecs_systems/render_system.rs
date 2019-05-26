//use crate::ecs_components::*;
//use crate::render_backends::*;
//use crate::engine_utils::*;
use crate::render_backends::{RendererBackend, Renderer, RenderItem, RenderPrimitive};
use crate::engine_utils::{ActiveCamera, Camera};
use crate::ecs_components::{TransformComponent, ShapeComponent, MaterialComponent, ShapeRendererComponent};
use specs::{System, SystemData, Read, ReadStorage};
use specs::*;

pub struct ShapeRendererSystem {
    renderer: RendererBackend
}
impl ShapeRendererSystem {
    pub fn new (renderer: &RendererBackend) -> ShapeRendererSystem {
        let renderer = renderer.clone();
        return ShapeRendererSystem { renderer };
    }
}
impl<'a> System<'a> for ShapeRendererSystem {
    type SystemData = (
//        Read<'a, ActiveCamera>,
        ReadStorage<'a, TransformComponent>,
        ReadStorage<'a, ShapeComponent>,
        ReadStorage<'a, MaterialComponent>,
        ReadStorage<'a, ShapeRendererComponent>,
    );
    fn run (&mut self, (transform, shape, material, render_info): Self::SystemData) {
//    fn run (&mut self, (camera, transform, shape, material, render_info): Self::SystemData) {
        let renderer : &mut Renderer = &mut *self.renderer.borrow_mut();
//        let camera = &*camera;
        let _camera = Camera::new();
        let camera = &_camera;
        for (transform, shape, material, render_info) in (&transform, &shape, &material, &render_info).join() {
            if render_info.visible {
                match shape {
                    ShapeComponent::Box(_shape) => {
                        match render_info.outline {
                            Some(outline) => renderer.draw(RenderItem {
                                primitive: RenderPrimitive::OutlineBox(outline, material.color),
                                transform: transform.local_to_camera_space_matrix(camera),
                                depth: transform.depth()
                            }),
                            None => renderer.draw(RenderItem {
                                primitive: RenderPrimitive::SolidBox(material.color),
                                transform: transform.local_to_camera_space_matrix(camera),
                                depth: transform.depth()
                            })
                        }
                    },
                    ShapeComponent::Circle(_shape) => {
                        match render_info.outline {
                            Some(outline) => renderer.draw(RenderItem {
                                primitive: RenderPrimitive::OutlineCircle(outline, material.color),
                                transform: transform.local_to_camera_space_matrix(camera),
                                depth: transform.depth()
                            }),
                            None => renderer.draw(RenderItem {
                                primitive: RenderPrimitive::SolidCircle(material.color),
                                transform: transform.local_to_camera_space_matrix(camera),
                                depth: transform.depth()
                            })
                        }
                    }
                }
            }
        }
    }
}
