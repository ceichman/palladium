import Metal
import MetalKit
import simd

/// A struct used to expose configurable renderer parameters.
struct RendererOptions {
    var fovDegrees: Double
    var shouldBlur: Bool
    var invertColors: Bool
}

/// This class focuses solely on rendering logic.

class Renderer: NSObject, MTKViewDelegate {
    
    var view: MTKView
    var mesh: Mesh!
    var camera: Camera!
    var delegate: RendererDelegate?
    var options: RendererOptions
    private var vertexBuffer: MTLBuffer!                // buffer used to store vertex data
    private var pipelineState: MTLRenderPipelineState!  // how to process vertex and fragment shaders during rendering
    private var depthStencilState: MTLDepthStencilState!
    private var postProcessPipelineState: MTLComputePipelineState!
    private var commandQueue: MTLCommandQueue!          // commands for the GPU
    
    private var currentFrameTime = CACurrentMediaTime()

    /// Initializes the Renderer object and calls setup() routine
    init(view: MTKView, mesh: Mesh, camera: Camera) {
        self.view = view
        self.options = RendererOptions(fovDegrees: 40.0, shouldBlur: true, invertColors: false)
        super.init()
        self.mesh = mesh
        self.camera = camera
        setup()
    }
    
    /// Sets up shaders with which to configure the pipeline descriptor; also initializes command queue to tell GPU what to do
    private func setup() {
        view.framebufferOnly = false
        guard let device = view.device else { return }
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
        
        let blurEffectShader = defaultLibrary.makeFunction(name: "invert_color")!
        
        self.postProcessPipelineState = try! device.makeComputePipelineState(function: blurEffectShader)
        

        commandQueue = device.makeCommandQueue()

        /// Create vertex buffer
        let (vertexArray, dataSize) = mesh.vertexArray()
        vertexBuffer = device.makeBuffer(bytes: vertexArray, length: dataSize, options: [])
        
        /// Initialize depth stencil state
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .greater
        depthStencilDescriptor.isDepthWriteEnabled = true
        depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)
    }
    
    func draw(in view: MTKView) {
        autoreleasepool { // ensures efficient memory management
            let now = CACurrentMediaTime()
            let deltaTime = now - currentFrameTime
            currentFrameTime = now
            
            if let delegate = self.delegate {
                delegate.preRenderUpdate(deltaTime: deltaTime)
            }
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
            
            /// Projection and transformation parameters
            let aspectRatio: Float = Float(view.bounds.height / view.bounds.width)
            var projectionParams = ProjectionParams(
                aspectRatio: aspectRatio,
                fovRadians: Float(options.fovDegrees / 180.0 * Double.pi),
                nearZ: 0.3,
                farZ: 1000.0
            )
            
            var transformationParams = TransformationParams(
                origin: mesh.origin,
                position: mesh.position,
                rotation: mesh.rotation,
                scale: mesh.scale
            )
            
            var viewMatrix = camera.getViewMatrix()
            
            /// Command buffer and encoding (encoded rendering instructions for the GPU)
            let commandBuffer = commandQueue.makeCommandBuffer()!
            /// Configure render command
            guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
            renderEncoder.label = "Immediate render pass"
            renderEncoder.setTriangleFillMode(.fill)
            renderEncoder.setCullMode(.back)
            renderEncoder.setFrontFacing(.clockwise)
            renderEncoder.setRenderPipelineState(pipelineState)
            renderEncoder.setDepthStencilState(self.depthStencilState)
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderEncoder.setVertexBytes(&projectionParams, length: MemoryLayout.size(ofValue: projectionParams), index: 1)
            renderEncoder.setVertexBytes(&transformationParams, length: MemoryLayout.size(ofValue: transformationParams), index: 2)
            renderEncoder.setVertexBytes(&viewMatrix, length: MemoryLayout<float4x4>.size, index: 3) // new set for the camera view
            // set*Bytes is convenient because you can pass a buffer to the shader without having to explicitly create it in Swift with device.makeBuffer(). probably saves system memory too
            // interpret vertexCount vertices as instanceCount instances of type .triangle
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: mesh.triangles.count * 3)
            renderEncoder.endEncoding()
            
            if options.shouldBlur {
                postProcess(commandBuffer: commandBuffer, inTexture: drawable.texture, outTexture: drawable.texture)
            }
            
            commandBuffer.present(drawable) // render to scene color (output)
            commandBuffer.commit()
        }
    }
    
    // placeholder for now, come back and add dynamic buffer resizing
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        //
    }
    
    func postProcess(commandBuffer: MTLCommandBuffer, inTexture: MTLTexture, outTexture: MTLTexture) {
        
        guard let encoder = commandBuffer.makeComputeCommandEncoder() else { return }
        encoder.label = "Post-processing pass"
        encoder.setComputePipelineState(self.postProcessPipelineState)
        encoder.setTexture(inTexture, index: 0)
        encoder.setTexture(outTexture, index: 1)
        
        
        let threadsPerGrid = MTLSize(width: inTexture.width,
                                     height: inTexture.height,
                                     depth: 1)

        let w = postProcessPipelineState.threadExecutionWidth
        let h = postProcessPipelineState.maxTotalThreadsPerThreadgroup / w
        let threadsPerThreadgroup = MTLSizeMake(w, h, 1)

        encoder.dispatchThreadgroups(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        encoder.endEncoding()
    }

    
}
