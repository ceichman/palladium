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
    var specularHighlights: Bool
}

/// This class focuses solely on rendering logic.

class Renderer: NSObject, MTKViewDelegate {
    
    var view: MTKView
    var scene: Scene
    var options: RendererOptions
    private var vertexBuffer: MTLBuffer!                // buffer used to store vertex data
    private var pipelineState: MTLRenderPipelineState!  // how to process vertex and fragment shaders during rendering
    private var depthStencilState: MTLDepthStencilState!
    private var commandQueue: MTLCommandQueue!          // commands for the GPU
    private var defaultLibrary: MTLLibrary!

    // has to be a var (not static let) because setupComputePipelineState requires access to view.device
    lazy private var invertColorPipelineState = setupComputePipelineState(shader: "invert_color")
    lazy private var gaussianBlurPipelineState = setupComputePipelineState(shader: "gaussian_blur")
    lazy private var boxBlurPipelineState = setupComputePipelineState(shader: "box_blur")
    lazy private var convolutionKernelShader = setupComputePipelineState(shader: "convolve_kernel")

    private var currentFrameTime = CACurrentMediaTime()

    /// Initializes the Renderer object and calls setup() routine
    init(view: MTKView, scene: Scene = Scene.defaultScene) {
        self.view = view
        self.options = RendererOptions(fovDegrees: 40.0, boxBlur: false, gaussianBlur: false, invertColors: false, texturing: true, wireframe: false, specularHighlights: true)
        self.scene = scene
        super.init()
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

        view.depthStencilPixelFormat = .depth32Float
        view.clearDepth = 1.0

    /// Initialize depth stencil state
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)
    }
    
    func draw(in view: MTKView) {
        autoreleasepool { [self] in // ensures efficient memory management
            let now = CACurrentMediaTime()
            let deltaTime = now - currentFrameTime
            currentFrameTime = now
            
            scene.preRenderUpdate(deltaTime)
            guard let drawable = view.currentDrawable else { return }
            
            /// Render pass descriptor defines how rendering should occur (textures, color, etc.)
            guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
            renderPassDescriptor.colorAttachments[0].texture = drawable.texture
            renderPassDescriptor.colorAttachments[0].loadAction = .clear
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(
                red: 0,
                green: 0,
                blue: 0,
                alpha: 0
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
            var viewProjection = scene.camera.viewProjection(projectionParams)
            
            guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
            /// Common render encoder configuration
            renderEncoder.label = "Geometry pass"
            renderEncoder.setTriangleFillMode(options.wireframe ? .lines : .fill)
            renderEncoder.setCullMode(.back)
            renderEncoder.setFrontFacing(.clockwise)
            renderEncoder.setRenderPipelineState(pipelineState)
            renderEncoder.setDepthStencilState(depthStencilState)
            
            for template in scene.objects {
                let instances = template.instances
                guard instances.count > 0 else { continue }
                
                var models = [ModelTransformation]()
                for instance in instances {
                    models.append(instance.modelTransformation())
                }
                
                var fragParams = FragmentParams(
                    cameraPosition: scene.camera.position,
                    specularCoefficient: options.specularHighlights ? template.material.specularCoefficient : 0.0,
                    numDirectionalLights: CInt(scene.directionalLights.count),
                    numPointLights: CInt(scene.pointLights.count)
                )

                renderEncoder.setVertexBuffer(template.vertexBuffer, offset: 0, index: 0)
                renderEncoder.setVertexBytes(&viewProjection, length: MemoryLayout.size(ofValue: viewProjection), index: 1)
                renderEncoder.setVertexBytes(models, length: MemoryLayout<ModelTransformation>.stride * models.count, index: 2)
                renderEncoder.setFragmentTexture(options.texturing ? template.material.colorTexture : nil, index: 0)
                renderEncoder.setFragmentBytes(&fragParams, length: MemoryLayout<FragmentParams>.stride, index: 0)
                renderEncoder.setFragmentBytes(scene.directionalLights, length: MemoryLayout<DirectionalLight>.stride * Int(fragParams.numDirectionalLights), index: 1)
                renderEncoder.setFragmentBytes(scene.pointLights, length: MemoryLayout<PointLight>.stride * Int(fragParams.numPointLights), index: 2)
                renderEncoder.setFragmentBytes(&scene.camera.position, length: MemoryLayout.size(ofValue: scene.camera.position), index: 3)
                // interpret vertexCount vertices as instanceCount instances of type .triangle
                renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: template.mesh.triangles.count * 3, instanceCount: instances.count)

            }
            renderEncoder.endEncoding()
            
            if options.boxBlur {
                let kernel = ConvolutionKernels.boxBlur(size: 7, device: view.device!)
                addConvolutionKernelPass(kernel: kernel, commandBuffer: commandBuffer, inTexture: drawable.texture, outTexture: drawable.texture)
            }
            
            if options.gaussianBlur {
                let kernel = ConvolutionKernels.gaussianBlur(size: 7, device: view.device!)
                addConvolutionKernelPass(kernel: kernel, commandBuffer: commandBuffer, inTexture: drawable.texture, outTexture: drawable.texture)
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
    
    func addPostProcessPass(pipeline: MTLComputePipelineState, commandBuffer: MTLCommandBuffer, inTexture: MTLTexture, outTexture: MTLTexture, kernel: MTLTexture? = nil) {
        
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
    
    func addConvolutionKernelPass(kernel: MTLTexture, commandBuffer: MTLCommandBuffer, inTexture: MTLTexture, outTexture: MTLTexture) {
        
        guard let encoder = commandBuffer.makeComputeCommandEncoder() else { return }
        encoder.label = "Convolution kernel post-processing pass"
        encoder.setComputePipelineState(convolutionKernelShader)
        encoder.setTexture(inTexture, index: 0)
        encoder.setTexture(outTexture, index: 1)
        encoder.setTexture(kernel, index: 2)
        
        let threadsPerGrid = MTLSize(width: inTexture.width,
                                     height: inTexture.height,
                                     depth: 1)
        
        let w = convolutionKernelShader.threadExecutionWidth
        let h = convolutionKernelShader.maxTotalThreadsPerThreadgroup / w
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
