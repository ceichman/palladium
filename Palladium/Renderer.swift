import Metal
import MetalKit
import simd

/// This class focuses solely on rendering logic.

class Renderer: NSObject {
    var device: MTLDevice!                      // GPU device
    var vertexBuffer: MTLBuffer!                // buffer used to store vertex data
    var pipelineState: MTLRenderPipelineState!  // how to process vertex and fragment shaders during rendering
    var commandQueue: MTLCommandQueue!          // commands for the GPU
    var mesh: Mesh!
    let outputPixelFormat: MTLPixelFormat = .bgra8Unorm

    /// Initializes the Renderer object (should be created in ViewController as Renderer(device: [ __ ] mesh: [ __ ]) and calls setup()
    init(device: MTLDevice, mesh: Mesh) {
        super.init()
        self.device = device
        self.mesh = mesh
        setup()
    }
    
    /// Sets up shaders with which to configure the pipeline descriptor; also initializes command queue to tell GPU what to do
    private func setup() {
        /// Set up render pipeline
        let defaultLibrary = device.makeDefaultLibrary()!
        let fragmentShader = defaultLibrary.makeFunction(name: "basic_fragment")
        let vertexShader = defaultLibrary.makeFunction(name: "project_vertex")
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexShader
        pipelineStateDescriptor.fragmentFunction = fragmentShader
        pipelineStateDescriptor.depthAttachmentPixelFormat = .depth32Float
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        
        commandQueue = device.makeCommandQueue()

        /// Create vertex buffer
        let (vertexArray, dataSize) = mesh.vertexArray()
        vertexBuffer = device.makeBuffer(bytes: vertexArray, length: dataSize, options: [])
    }
    
    func render(in view: MTKView) {
        autoreleasepool { // ensures efficient memory management
            guard let drawable = view.currentDrawable else { return } // retrieves current frame of the mesh
            
            /// Render pass descriptor defines how rendering should occur (textures, color, etc.)
            guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
            renderPassDescriptor.colorAttachments[0].texture = drawable.texture
            renderPassDescriptor.colorAttachments[0].loadAction = .clear
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(
                red: 0.0,
                green: 104.0 / 255.0,
                blue: 55.0 / 255.0,
                alpha: 1.0
            )
            
            /// Color management; sin ensures smooth transition between colors
            let time = Date().timeIntervalSince1970.magnitude
            let redValue = Float(sin(1.0 * time) / 2.0 + 0.5)  // just a sin of the times i guess..
            let greenValue = Float(sin(1.1 * time) / 2.0 + 0.5)
            let blueValue = Float(sin(1.2 * time) / 2.0 + 0.5)
            
            //  fragment shader params TODO: make sure the corresponding struct definition in the shader is identical
            struct FragmentParams {
                let color: (Float, Float, Float, Float)
            }
            
            var fragParams = FragmentParams(color: (redValue, greenValue, blueValue, 1.0))
            
            /// Projection and transformation parameters
            let aspectRatio = Float(view.bounds.height / view.bounds.width)
            let fovDegrees = 40.0 // converted to radians later
            var projectionParams = ProjectionParams(
                aspectRatio: aspectRatio,
                fovRadians: Float(fovDegrees / 180.0 * Double.pi),
                nearZ: 0.3,
                farZ: 1000.0,
                time: Float(fmod(time, Double.pi * 2.0))
            )
            
            let xPosition = Float(cos(time) * 2.5) + 4.0
            let yPosition = Float(sin(time) * 2.5)
            var transformationParams = TransformationParams(
                origin: simd_float3(0.0, -2.0, 6.0),
                rotation: simd_float3(0, yPosition, 0),
                scale: simd_float3(1, 1, 1)
            )
            
            
            /// Command buffer and encoding (encoded rendering instructions for the GPU)
            let commandBuffer = commandQueue.makeCommandBuffer()
            /// Configure render command
            guard let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
            renderEncoder.label = "Immediate render pass"
            renderEncoder.setTriangleFillMode(.fill)
            renderEncoder.setCullMode(.back)
            renderEncoder.setRenderPipelineState(pipelineState)
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderEncoder.setVertexBytes(&projectionParams, length: MemoryLayout.size(ofValue: projectionParams), index: 1)
            renderEncoder.setVertexBytes(&transformationParams, length: MemoryLayout.size(ofValue: transformationParams), index: 2)
            // set*Bytes is convenient because you can pass a buffer to the shader without having to explicitly create it in Swift with device.makeBuffer(). probably saves system memory too
            renderEncoder.setFragmentBytes(&fragParams, length: MemoryLayout.size(ofValue: fragParams), index: 0)
            // interpret vertexCount vertices as instanceCount instances of type .triangle
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: mesh.triangles.count * 3)
            renderEncoder.endEncoding()
            
            commandBuffer?.present(drawable) // render to scene color (output)
            commandBuffer?.commit()
        }
    }
}
