use crate::renderer;
pub use renderer::*;
use crate::engine_utils::color::{Color};
use glium::{Surface};
use cgmath::conv::{array4x4};
use crate::glium;

/// Renderer interface for the glium backend renderer
/// (this implements a simple 2d renderer)
pub struct GliumRenderer {
    display: glium::Display,    // owns the glium display (and this is all opaque so GL if you want to access the display's window...)
    frame: glium::Frame,        // current frame that is being rendered. Renderer exists so we can abstract this
    renderer: GLSLRenderer,     // the -actual- renderer that draws RenderItems
    render_list: Vec<RenderItem>,   // render list (lets us store, then sort all drawcalls to handle transparency, depth, etc)
}
impl Renderer for GliumRenderer {
    /// Called at the start of our frame by GameLoop code
    /// - clears the screen
    /// - tells glium to start a new frame
    /// - clears our render list
    fn begin_frame (&mut self) {
        let mut frame = self.display.draw();
        frame.clear_all((0.0, 0.0, 0.0, 0.0),0.0, 0);
        self.render_list.clear();
        self.frame = frame;
    }
    /// Called anytime between begin_frame() and end_frame() by rendering systems
    fn draw (&mut self, item: RenderItem) {
        // just pushes the draw call info to deal with later
        self.render_list.push(item);
    }
    /// Called at the end of our frame by GameLoop code
    /// - sorts and executes all draw calls
    /// - tells glium to end this frame
    /// if vsync is turned on this will probably block
    fn end_frame (&mut self) {
        // actually draw everything
        self.draw_items();
        self.frame.set_finish().unwrap();
    }
}
impl GliumRenderer {
    /// Constructs a new renderer from a glium display
    /// called from render_backends::make_glium_renderer()
    pub fn new (display: glium::Display) -> GliumRenderer {
        let mut frame = display.draw(); frame.set_finish().unwrap();
        let renderer = GLSLRenderer::new(&display);
        let render_list = Vec::<RenderItem>::new();
        return GliumRenderer { display, renderer, frame, render_list }
    }
    /// Sorts and runs all queued drawcalls
    fn draw_items (&mut self) {
        // sort by depth
        use std::cmp::Ord;
        self.render_list.sort_by(|a, b| a.depth.partial_cmp(&b.depth).unwrap());

        // draw opaque items first, then transparent
        // note: f***ed a lot around with drain_filter (requires nightly, this f***s up a lot of
        // things, partition (inefficient b/c doesn't reuse memory; also a PITA to use))
        // this is stupid but it works
        for item in &self.render_list {
            if !item.transparent {
                self.renderer.draw(&mut self.frame, &item);
            }
        }
        for item in &self.render_list {
            if item.transparent {
                self.renderer.draw(&mut self.frame, &item);
            }
        }
    }
}

/// opengl vertex layout for the 2d renderer glium backend
#[derive(Copy, Clone)]
struct Vertex {
    position: [f32; 2],
}
implement_vertex!(Vertex, position);

/// Backend glium renderer: encapsultes rendering details used to draw any RenderPrimitive
/// Uses just one vertex + fragment shader (and opengl shader subroutines)
/// requires opengl 4.1 (for gl subroutines, among other things)
/// can't use anything more modern than 4.1 (ie. 4.5) b/c mac support...
struct GLSLRenderer {
    quad_vertices: glium::VertexBuffer<Vertex>,
    quad_indices: glium::index::NoIndices,
    shape_shader: glium::Program,
    render_items: Vec<RenderItem>,
}
impl GLSLRenderer {
    fn new (display: &glium::Display) -> GLSLRenderer {
        // Note: we're effectively using one quad to render everything.
        // The coordinates are (-0.5, -0.5) to (0.5, 0.5)
        // This is important; it simplifies rendering 2d primitives quite a bit
        let vertices = vec![
            Vertex { position: [ -0.5,  0.5 ] },
            Vertex { position: [ -0.5, -0.5 ] },
            Vertex { position: [  0.5, -0.5 ] },
            Vertex { position: [ -0.5,  0.5 ] },
            Vertex { position: [  0.5, -0.5 ] },
            Vertex { position: [  0.5,  0.5 ] },
        ];
        let display = display.clone();
        let quad_vertices = glium::VertexBuffer::new(&display, &vertices).unwrap();
        let quad_indices = glium::index::NoIndices(glium::index::PrimitiveType::TrianglesList);

        // Vertex shader notes:
        // - we use a standard 4x4 matrix for vertex transforms
        // - ALL translation / rotation / scaling is done via this matrix
        // note: coordinates are 2d, sort of. z is used for depth, but the transform does not apply
        // scaling on the z axis, and we only (officially) support 1 DOF rotating around the z axis.
        // obviously, this is still a full 3d renderer internally though, so you could still do full
        // 3d perspective rendering by passing in an appropriate MVP transform.
        // - local_coords is the original passed in vertex coords (-0.5,-0.5) to (0.5,0.5), see
        // above, but scaled by 2 => (-1.0, -1.0), (1.0, 1.0).
        // This will be interpolated when it's passed to the fragment shader.
        let shape_vertex_shader = r#"
            #version 410
            in vec2 position;
            out vec2 local_coords;
            uniform mat4 transform;
            void main () {
                gl_Position = transform * vec4(position, 0.0, 1.0);
                local_coords = position * 2;
            }
        "#;
        // Fragment shader notes:
        // - local_coords is (-1.0, -1.0) to (1.0, 1.0), and tells us where in a 2d primitive
        // (ie. 2d quad) we are. This is used for:
        //      - circle (ellipse) rendering
        //      - outline rendering (with circles and boxes)
        // - outline_width is provided for outline rendering, and is in camera space. May need
        // to improve / change this to support rendering fixed-pixel outlines, and other stuff
        // (ie. aspect ratio...?)
        // - color is provided to render solid / outlined 2d shapes (boxes, ellipses / circles)
        // - sprite rendering is currently TBD
        // - we ONLY render a 1 x 1 box (or a 1 x 1 circle), which is centered at (0, 0) and thus
        //  has coords (-0.5, -0.5) to (+0.5, +0.5). But with the 4x4 transform (see above)
        //  we can obviously render ANY quad or ellipse w/ the appropriate transformations.
        // - an opengl subroutine is used to implement all of the above in a single fragment shader.
        let shape_fragment_shader = r#"
            #version 410
            out vec4        out_color;
            in vec2         local_coords;
            uniform vec4    color;
            uniform float   outline_width;

            subroutine void draw_function();
            subroutine uniform draw_function draw_primitive;

            subroutine(draw_function) void draw_solid_box () {
                out_color = vec4(color.rgb * color.a, color.a);
            }
            subroutine(draw_function) void draw_solid_circle () {
                if (dot(local_coords, local_coords) < 1.0) {
                    out_color = vec4(color.rgb * color.a, color.a);
                } else {
                    discard;
                }
            }
            subroutine(draw_function) void draw_outline_box () {
                vec2 from_center = abs(local_coords);
                if (max(from_center.x, from_center.y) >= 1.0 - outline_width) {
                    out_color = vec4(color.rgb * color.a, color.a);
                } else {
                    discard;
                }
            }
            subroutine(draw_function) void draw_outline_circle () {
                float from_center = dot(local_coords, local_coords);
                if (from_center <= 1.0 && from_center >= 1.0 - outline_width) {
                    out_color = vec4(color.rgb * color.a, color.a);
                } else {
                    discard;
                }
            }
            void main () {
                draw_primitive();
            }
        "#;
        let shape_shader = glium::Program::from_source(
            &display, shape_vertex_shader, shape_fragment_shader, None,
        ).unwrap();
        let render_items = Vec::<RenderItem>::new();
        return GLSLRenderer { quad_vertices, quad_indices, shape_shader, render_items };
    }
    /// internal drawing function for drawing outlined / solid 2d shapes
    /// draw_function is the shader subroutine that we're executing (in the fragment shader)
    fn draw_shape (&self, frame: &mut glium::Frame, transform: &Mat4, draw_function: &str, outline: f32, color: Color, transparent: bool) {
        let uniforms = uniform! [
            transform: array4x4(*transform),
            draw_primitive: (draw_function, glium::program::ShaderStage::Fragment),
            outline_width: outline,
            color: color
        ];
        use glium::draw_parameters::{DrawParameters, Depth, DepthTest, DepthClamp, Blend};

        // note: these should be consts, but I was getting errors on rust nightly b/c Default::default() is
        // not a const function...?
        let DP_OPAQUE : DrawParameters = DrawParameters {
            depth: Depth { test: DepthTest::IfMoreOrEqual, write: true, .. Default::default() },
            .. Default::default()
        };
        let DP_TRANSPARENT : DrawParameters = DrawParameters {
            depth: Depth { test: DepthTest::IfMoreOrEqual, write: false, .. Default::default() },
            blend: Blend::alpha_blending(),
            .. Default::default()
        };
        let dp = if transparent { &DP_TRANSPARENT } else { &DP_OPAQUE };
        frame.draw(
            &self.quad_vertices,
            self.quad_indices,
            &self.shape_shader, &uniforms,
            &dp).unwrap();
    }
    /// Draws any RenderItem primitive.
    /// Solid / outlined shape rendering is implemented; sprites TBD.
    fn draw (&self, frame: &mut glium::Frame, item: &RenderItem) {
//        println!("Drawing {:?}", item);   // uncomment this to debug draw calls (item has all draw call info)
        match item.primitive {
            RenderPrimitive::SolidBox(color) => self.draw_shape(frame, &item.transform, "draw_solid_box", 0.0, color, item.transparent),
            RenderPrimitive::SolidCircle(color) => self.draw_shape(frame, &item.transform, "draw_solid_circle", 0.0, color, item.transparent),
            RenderPrimitive::OutlineBox(width, color) => self.draw_shape(frame, &item.transform, "draw_outline_box", width, color, item.transparent),
            RenderPrimitive::OutlineCircle(width, color) => self.draw_shape(frame, &item.transform, "draw_outline_circle", width, color, item.transparent),
            RenderPrimitive::Sprite(_) => println!("unimplemented: render sprite!"),
            RenderPrimitive::Text(_) => println!("unimplemented: render text!"),
        }
    }
}
