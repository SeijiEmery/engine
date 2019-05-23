extern crate glium;

pub struct Box2dPrimitive {
    vertex_buffer: glium::VertexBuffer<Vertex>,
    indices: glium::index::NoIndices,
    shader: glium::Program,
}
impl Box2dPrimitive {
    fn new (display: glium::Display) {
        let vertices = vec![
            Vertex { position: [-0.5, -0.5]},
            Vertex { position: [ 0.0, 0.5]},
            Vertex { position: [ 0.5, -0.25]}
        ];
        let vertex_buffer = glium::VertexBuffer::new(&display, &vertices);
        let indices = glium::index::NoIndices(glium::index::PrimitiveType::TrianglesList);
        let vertex_shader = r#"
            #version 410
            in vec2 position;
            uniform mat4 mvp_transform;
            void main () {
                gl_Position = mvp_transform * vec4(position, 0.0, 1.0);
            }
        "#;
        let fragment_shader = r#"
            #version 410
            out vec4 out_color;
            uniform vec4 color;
            void main () {
                out_color = color;
            }
        "#;
        let program = glium::Program::from_source(&display, vertex_shader, fragment_shader, None).unwrap();
        return Box2dPrimitive {
            vertex_buffer: vertex_buffer.unwrap(),
            indices: indices,
            shader: program
        }
    }
}
impl Renderable for Box2dPrimitive {
    fn draw (&self, target: &mut glium::Frame) {

    }
}








