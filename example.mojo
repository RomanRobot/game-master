import wgpu.src as wgpu
from sdl.src import *
from sys.info import sizeof

from memory import Span, UnsafePointer
from collections import InlineArray
from math import pi

from mat import Mat4

alias Vec4 = SIMD[DType.float32, 4]

@value
struct MyColor:
    var r: Float32
    var g: Float32
    var b: Float32
    var a: Float32

@value
struct MyVertex:
    var pos: Vec4
    var color: MyColor

def main():
    alias window_width = 640
    alias window_height = 480

    # mix breaks on wsl
    var sdl = SDL(
        video=True,
        audio=True,
        timer=True,
        events=True,
        gfx=True,
        img=True,
        mix=False,
        ttf=True,
    )
    var window = Window(sdl, "Hello, Game Master", window_width, window_height)
    var clock = Clock(sdl, target_fps=60)
    var held_keys = SIMD[DType.bool, 512]()

    #var apple = Surface(sdl, sdl._img().load_image(('assets/apple.png').unsafe_cstr_ptr().bitcast[DType.uint8]()))
    #var rotated_apple = apple.rotozoomed(90, 1, True)
    #var font = ttf.Font(sdl, "assets/Beef'd.ttf", 24)
    #var hello = font.render_solid("Hello, World!", Color(255, 0, 255, 255))
    #hello.convert(window.get_surface())

    # var test_sound = mix.MixMusic(sdl.mix, 'assets/audio/error_003.ogg')

    instance = wgpu.Instance()
    surface = wgpu.Surface[__origin_of(window)](instance, window.get_native_window().bitcast[NoneType]())

    adapter = instance.request_adapter_sync()
    device = adapter.request_device()
    queue = device.get_queue()

    surface_capabilities = surface.get_capabilities(adapter)
    surface_format = surface_capabilities.formats()[0]
    surface.configure(
        width=window_width,
        height=window_height,
        usage=wgpu.TextureUsage.render_attachment,
        format=surface_format,
        device=device,
        alpha_mode=wgpu.CompositeAlphaMode.auto,
        present_mode=wgpu.PresentMode.fifo,
    )

    shader_code = """
        @group(0) @binding(0)
        var<uniform> mvp: mat4x4<f32>;

        struct VertexOutput {
            @builtin(position) position: vec4<f32>,
            @location(1) color: vec4<f32>,
        };

        @vertex
        fn vs_main(@location(0) in_pos: vec4<f32>, @location(1) in_color: vec4<f32>) -> VertexOutput {
            var output: VertexOutput;
            output.position = in_pos * mvp;
            output.color = in_color;
            return output;
        }

        @fragment
        fn fs_main(@location(1) in_color: vec4<f32>) -> @location(0) vec4<f32> {
            return in_color;
        }
        """
    shader_module = device.create_shader_module(code=shader_code)

    vertex_attributes = List[wgpu.VertexAttribute](
        wgpu.VertexAttribute(format=wgpu.VertexFormat.float32x4, offset=0, shader_location=0),
        wgpu.VertexAttribute(format=wgpu.VertexFormat.float32x4, offset=sizeof[Vec4](), shader_location=1)
    )
    vertex_buffer_layout = wgpu.VertexBufferLayout[StaticConstantOrigin](
        array_stride=sizeof[MyVertex](),
        step_mode=wgpu.VertexStepMode.vertex,
        attributes=Span[wgpu.VertexAttribute, StaticConstantOrigin](ptr=vertex_attributes.unsafe_ptr(), length=len(vertex_attributes))
    )

    vertices = InlineArray[MyVertex, 3](
        MyVertex(Vec4(-0.5, -0.5, 0.0, 1.0), MyColor(1, 0, 0, 1)),
        MyVertex(Vec4(0.5, -0.5, 0.0, 1.0), MyColor(0, 1, 0, 1)),
        MyVertex(Vec4(0.0, 0.5, 0.0, 1.0), MyColor(0, 0, 1, 1))
    )
    vertex_buffer = device.create_buffer(
        label="vertex buffer", #StringLiteral
        usage=wgpu.BufferUsage.vertex, #BufferUsage
        size=len(vertices) * sizeof[MyVertex](), #UInt64
        mapped_at_creation=True #Bool
    )
    dst = vertex_buffer.get_mapped_range().bitcast[MyVertex]()
    for i in range(len(vertices)):
        dst[i] = vertices[i]
    vertex_buffer.unmap()

    model = Mat4.identity()
    view = Mat4.translation(0.0, 0.0, -1.0)
    projection = Mat4.perspective(fov=pi*0.5, aspect_width=window_height, aspect_height=window_height, near=0.1, far=1000.0)
    view_projection = view * projection
    mvp = model * view_projection
    uniform_buffer = device.create_buffer(
        label="uniform buffer", #StringLiteral
        usage=wgpu.BufferUsage.uniform | wgpu.BufferUsage.copy_dst, #BufferUsage
        size=sizeof[Mat4](), #UInt64
        mapped_at_creation=True #Bool
    )
    uniform_mapped = uniform_buffer.get_mapped_range(0, sizeof[Mat4]()).bitcast[Mat4]()
    uniform_mapped[] = mvp
    uniform_buffer.unmap()

    bind_groups, bind_group_layouts = device.create_bind_groups(List[wgpu.BindGroupDescriptor](wgpu.BindGroupDescriptor(
        label="bind group",
        layout=wgpu.BindGroupLayoutDescriptor(
            label="bind group layout",
            entries=List[wgpu.BindGroupLayoutEntry](wgpu.BindGroupLayoutEntry(
                binding=0, #UInt32
                visibility=wgpu.ShaderStage.vertex, #ShaderStage
                buffer=wgpu.BufferBindingLayout(
                    type=wgpu.BufferBindingType.uniform, #BufferBindingType
                    has_dynamic_offset=False, #Bool
                    min_binding_size=sizeof[Mat4](), #UInt64
                ), #BufferBindingLayout
            ))
        ), #BindGroupLayoutDescriptor
        entries=List[wgpu.BindGroupEntry](wgpu.BindGroupEntry(
            binding=0, #UInt32
            buffer=uniform_buffer._handle, #UnsafePointer[_BufferImpl]
            offset=0, #UInt64
            size=sizeof[Mat4](), #UInt64
        )), #List[BindGroupEntry]
    )))
    pipeline_layout = device.create_pipeline_layout(wgpu.PipelineLayoutDescriptor(
        label="pipeline layout", # StringLiteral
        bind_group_layouts=bind_group_layouts # List[ArcPointer[BindGroupLayout]]
    ))
    render_pipeline = device.create_render_pipeline(wgpu.RenderPipelineDescriptor(
        label="render pipeline",
        vertex=wgpu.VertexState(
            entry_point="vs_main",
            module=shader_module,
            buffers=List[wgpu.VertexBufferLayout[StaticConstantOrigin]](vertex_buffer_layout),
        ),
        fragment=wgpu.FragmentState(
            module=shader_module,
            entry_point="fs_main",
            targets=List[wgpu.ColorTargetState](
                wgpu.ColorTargetState(
                    blend=wgpu.BlendState(
                        color=wgpu.BlendComponent(
                            src_factor=wgpu.BlendFactor.src_alpha,
                            dst_factor=wgpu.BlendFactor.one_minus_src_alpha,
                            operation=wgpu.BlendOperation.add,
                        ),
                        alpha=wgpu.BlendComponent(
                            src_factor=wgpu.BlendFactor.zero,
                            dst_factor=wgpu.BlendFactor.one,
                            operation=wgpu.BlendOperation.add,
                        ),
                    ),
                    format=surface_format,
                    write_mask=wgpu.ColorWriteMask.all,
                )
            ),
        ),
        primitive=wgpu.PrimitiveState(
            topology=wgpu.PrimitiveTopology.triangle_list,
        ),
        multisample=wgpu.MultisampleState(),
        layout=pipeline_layout,
        depth_stencil=None,
    ))

    tri_angle = Float32(0)
    var playing = True
    while playing:
        for event in sdl.event_list():
            if event[].isa[QuitEvent]():
                playing = 0
            elif event[].isa[KeyDownEvent]():
                var e = event[][KeyDownEvent]
                held_keys[Int(e.key)] = True
                # if e.key == Keys.space:
                #     test_sound.play(1)
            elif event[].isa[KeyUpEvent]():
                var e = event[][KeyUpEvent]
                held_keys[Int(e.key)] = False

        angular_speed = 5
        if held_keys[Keys.a]:
            tri_angle -= clock.delta_time.cast[DType.float32]() * angular_speed
        if held_keys[Keys.d]:
            tri_angle += clock.delta_time.cast[DType.float32]() * angular_speed

        model = Mat4.rotation_y(tri_angle)
        mvp = model * view_projection
        queue.write_buffer(uniform_buffer, UnsafePointer.address_of(mvp).bitcast[UInt8]())
        
        surface_tex = surface.get_current_texture()
        if surface_tex.status != wgpu.SurfaceGetCurrentTextureStatus.success:
            raise Error("failed to get surface tex")
        color_attachment = wgpu.RenderPassColorAttachment(
            surface_texture=surface_tex,
            texture_view_descriptor=wgpu.TextureViewDescriptor(
                label="surface texture view",
                format=surface_format,#surface_tex.texture[].get_format(),
                dimension=wgpu.TextureViewDimension.d2,
                base_mip_level=0,
                mip_level_count=1,
                base_array_layer=0,
                array_layer_count=1,
                aspect=wgpu.TextureAspect.all,
            ),
            load_op=wgpu.LoadOp.clear,
            store_op=wgpu.StoreOp.store,
            clear_value=wgpu.Color(0.9, 0.1, 0.2, 1.0),
        )

        encoder = device.create_command_encoder()
        rp = encoder.begin_render_pass(color_attachment=color_attachment)
        rp.set_pipeline(render_pipeline)
        rp.set_vertex_buffer(0, vertex_buffer)
        rp.set_bind_group(0, 0, UnsafePointer[UInt32](), bind_groups[0])
        rp.draw(len(vertices), 1, 0, 0)
        rp.end()
        queue.submit(encoder.finish())

        surface.present()
