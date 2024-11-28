import Metal
import MetalKit
import simd

/// A struct used to expose configurable renderer parameters.
struct RendererOptions {
    var fovDegrees: Double
    var boxBlur: Bool
    var gaussianBlur: Bool
    var invertColors: Bool
    var texturing: Bool
    var wireframe: Bool
}

/// This class focuses solely on rendering logic.

class Renderer: NSObject, MTKViewDelegate {
    
    var view: MTKView
    var objects: [Object]!
    var camera: Camera!
    var delegate: RendererDelegate?
    var options: RendererOptions
    private var vertexBuffer: MTLBuffer!                // buffer used to store vertex data
    private var pipelineState: MTLRenderPipelineState!  // how to process vertex and fragment shaders during rendering
    private var depthStencilState: MTLDepthStencilState!
    private var commandQueue: MTLCommandQueue!          // commands for the GPU
    private var defaultLibrary: MTLLibrary!

    lazy private var invertColorPipelineState = setupComputePipelineState(shader: "invert_color")
    lazy private var gaussianBlurPipelineState = setupComputePipelineState(shader: "gaussian_blur")
    lazy private var boxBlurPipelineState = setupComputePipelineState(shader: "box_blur")

    private var currentFrameTime = CACurrentMediaTime()

    /// Initializes the Renderer object and calls setup() routine
    init(view: MTKView, objects: [Object], camera: Camera) {
        self.view = view
        self.options = RendererOptions(fovDegrees: 40.0, boxBlur: false, gaussianBlur: false, invertColors: false, texturing: true, wireframe: false)
        super.init()
        self.objects = objects
        self.camera = camera
        setup()
    }
    
    /// Sets up shaders with which to configure the pipeline descriptor; also initializes command queue to tell GPU what to do
    private func setup() {
        view.framebufferOnly = false
        guard let device = view.device else { return }
        /// Set up render pipeline
        defaultLibrary = device.makeDefaultLibrary()
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
        
        view.depthStencilPixelFormat = .depth32Float
        view.clearDepth = 1.0

    /// Initialize depth stencil state
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
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
            guard let drawable = view.currentDrawable else { return }
            
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
            let commandBuffer = commandQueue.makeCommandBuffer()!
            
            /// Projection and transformation parameters
            let aspectRatio: Float = Float(view.bounds.height / view.bounds.width)
            let projectionParams = ProjectionParams(
                aspectRatio: aspectRatio,
                fovRadians: Float(options.fovDegrees / 180.0 * Double.pi),
                nearZ: 0.3,
                farZ: 1000.0
            )
            var viewProjection = camera.viewProjection(projectionParams)
 
            guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
            /// Common render encoder configuration
            renderEncoder.label = "Geometry pass"
            renderEncoder.setTriangleFillMode(options.wireframe ? .lines : .fill)
            renderEncoder.setCullMode(.back)
            renderEncoder.setFrontFacing(.clockwise)
            renderEncoder.setRenderPipelineState(pipelineState)
            renderEncoder.setDepthStencilState(depthStencilState)

            for object in objects {
                renderObject(object, renderEncoder: renderEncoder, viewProjection: &viewProjection)
            }
            renderEncoder.endEncoding()
            
            if options.boxBlur {
                addPostProcessPass(pipeline: boxBlurPipelineState, commandBuffer: commandBuffer, inTexture: drawable.texture, outTexture: drawable.texture)
            }
            
            if options.gaussianBlur {
                addPostProcessPass(pipeline: gaussianBlurPipelineState, commandBuffer: commandBuffer, inTexture: drawable.texture, outTexture: drawable.texture)
            }
            if options.invertColors {
                addPostProcessPass(pipeline: invertColorPipelineState, commandBuffer: commandBuffer, inTexture: drawable.texture, outTexture: drawable.texture)
            }
            
            commandBuffer.present(drawable) // render to scene color (output)
            commandBuffer.commit()
        }
    }
    
    // placeholder for now, come back and add dynamic buffer resizing
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        //
    }
    
    func renderObject(_ object: Object, renderEncoder: MTLRenderCommandEncoder, viewProjection: inout ViewProjection) {
                    
        var modelTransformation = object.modelTransformation()

        renderEncoder.setVertexBuffer(object.vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBytes(&viewProjection, length: MemoryLayout.size(ofValue: viewProjection), index: 1)
        renderEncoder.setVertexBytes(&modelTransformation, length: MemoryLayout.size(ofValue: modelTransformation), index: 2)
        renderEncoder.setFragmentTexture(options.texturing ? object.texture : nil, index: 0)
        // interpret vertexCount vertices as instanceCount instances of type .triangle
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: object.mesh.triangles.count * 3)

    }
    
    func addPostProcessPass(pipeline: MTLComputePipelineState, commandBuffer: MTLCommandBuffer, inTexture: MTLTexture, outTexture: MTLTexture) {
        
        guard let encoder = commandBuffer.makeComputeCommandEncoder() else { return }
        encoder.label = "Post-processing pass: \(pipeline.description)"
        encoder.setComputePipelineState(pipeline)
        encoder.setTexture(inTexture, index: 0)
        encoder.setTexture(outTexture, index: 1)
        
        
        let threadsPerGrid = MTLSize(width: inTexture.width,
                                     height: inTexture.height,
                                     depth: 1)
        
        let w = pipeline.threadExecutionWidth
        let h = pipeline.maxTotalThreadsPerThreadgroup / w
        let threadsPerThreadgroup = MTLSizeMake(w, h, 1)
        
        let threadgroupsPerGrid = MTLSizeMake(threadsPerGrid.width / threadsPerThreadgroup.width,
                                              threadsPerGrid.height / threadsPerThreadgroup.height,
                                              1)

        encoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        encoder.endEncoding()
    }
    
    private func setupComputePipelineState(shader: String) -> MTLComputePipelineState {
        let shaderFunction = defaultLibrary.makeFunction(name: shader)!
        return try! view.device!.makeComputePipelineState(function: shaderFunction)
    }

    
}
