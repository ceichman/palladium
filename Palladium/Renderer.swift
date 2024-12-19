import Metal
import MetalKit
import MetalPerformanceShaders
import simd

/// This class focuses solely on rendering logic.

class Renderer: NSObject, MTKViewDelegate {
    
    var view: MTKView
    var scene: Scene
    var optionsProvider: OptionsProvider
    private var pipelineState: MTLRenderPipelineState!  // how to process vertex and fragment shaders during rendering
    private var depthStencilState: MTLDepthStencilState!
    private var commandQueue: MTLCommandQueue!          // commands for the GPU
    private var defaultLibrary: MTLLibrary!
    private var intermediateRenderTarget: MTLTexture!  // used for flip-flopping source/dest textures during conv. kernel passes
    
    private var sourceTexture: MTLTexture!
    private var destTexture: MTLTexture!
    
    // has to be a var (not static let) because setupComputePipelineState requires access to view.device
    lazy private var invertColorPipelineState = setupComputePipelineState(shader: "invert_color")
    lazy private var convolutionKernelShader = setupComputePipelineState(shader: "convolve_kernel")

    private var currentFrameTime = CACurrentMediaTime()

    /// Initializes the Renderer object and calls setup() routine
    init(view: MTKView, scene: Scene = Scene.defaultScene, optionsProvider: OptionsProvider) {
        self.view = view
        self.scene = scene
        self.optionsProvider = optionsProvider
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
        
        let intermediateTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: view.colorPixelFormat,
            width: Int(view.drawableSize.width),
            height: Int(view.drawableSize.height),
            mipmapped: false)
        intermediateTextureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
        intermediateTextureDescriptor.textureType = .type2D
        intermediateRenderTarget = device.makeTexture(descriptor: intermediateTextureDescriptor)
        
    }
    
    func draw(in view: MTKView) {
        
        autoreleasepool { [self] in // ensures efficient memory management
            let now = CACurrentMediaTime()
            let deltaTime = now - currentFrameTime
            currentFrameTime = now
            
            // let the scene update what it wants before things are drawn
            // should be moved off the render thread eventually
            scene.preRenderUpdate(deltaTime)
            let (options, numConvKernelPasses) = optionsProvider.getOptions()
            guard let drawable = view.currentDrawable else { return }
            
            // kernel passes can't have the same source and destination texture because of cross-threadgroup desync
            // final convolution kernel pass should write to the drawable (A), so we should find
            // out which texture to write to first using the total number of kernel passes
            // geometry -> A -> B -> A, or
            // geometry -> B -> A -> B -> A
            
            sourceTexture = numConvKernelPasses % 2 == 0 ? intermediateRenderTarget : drawable.texture
            destTexture = numConvKernelPasses % 2 == 0 ? drawable.texture : intermediateRenderTarget
            
            // setup geometry pass
            guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
            renderPassDescriptor.colorAttachments[0].texture = destTexture
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
            var viewProjection = scene.camera.viewProjection(aspectRatio: aspectRatio)
            
            guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
            /// Common render encoder configuration
            renderEncoder.label = "Geometry pass"
            let shouldWireframe = options.getBool(.wireframe)
            renderEncoder.setTriangleFillMode(shouldWireframe ? .lines : .fill)
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
                
                let shouldSpecular = options.getBool(.specularHighlights)
                var fragParams = FragmentParams(
                    cameraPosition: scene.camera.position,
                    specularCoefficient: shouldSpecular ? template.material.specularCoefficient : 0.0,
                    numDirectionalLights: CInt(scene.directionalLights.count),
                    numPointLights: CInt(scene.pointLights.count)
                )

                renderEncoder.setVertexBuffer(template.vertexBuffer, offset: 0, index: 0)
                renderEncoder.setVertexBytes(&viewProjection, length: MemoryLayout.size(ofValue: viewProjection), index: 1)
                renderEncoder.setVertexBytes(models, length: MemoryLayout<ModelTransformation>.stride * models.count, index: 2)
                let shouldTexture = options.getBool(.texturing)
                renderEncoder.setFragmentTexture(shouldTexture ? template.material.colorTexture : nil, index: 0)
                renderEncoder.setFragmentBytes(&fragParams, length: MemoryLayout<FragmentParams>.stride, index: 0)
                renderEncoder.setFragmentBytes(scene.directionalLights, length: MemoryLayout<DirectionalLight>.stride * Int(fragParams.numDirectionalLights), index: 1)
                renderEncoder.setFragmentBytes(scene.pointLights, length: MemoryLayout<PointLight>.stride * Int(fragParams.numPointLights), index: 2)
                renderEncoder.setFragmentBytes(&scene.camera.position, length: MemoryLayout.size(ofValue: scene.camera.position), index: 3)
                // interpret vertexCount vertices as instanceCount instances of type .triangle
                renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: template.mesh.triangles.count * 3, instanceCount: instances.count)

            }
            renderEncoder.endEncoding()
            
            if options.getBool(.boxBlur) {
                let sliderValue = options.getFloat(.blurSize)  // [0, 1)
                let blurSize = ConvolutionKernels.scaleKernelSize(sliderValue)
                // let kernel = ConvolutionKernels.boxBlur(size: blurSize, device: view.device!)
                // addConvolutionKernelPass(kernel: kernel, commandBuffer: commandBuffer)
                
                swapSourceDestTexture()
                let filter = MPSImageBox(device: view.device!, kernelWidth: blurSize, kernelHeight: blurSize)
                filter.encode(commandBuffer: commandBuffer, sourceTexture: sourceTexture, destinationTexture: destTexture)
            }
            
            if options.getBool(.gaussianBlur) {
                let sliderValue = options.getFloat(.blurSize)  // [0, 1)
                let maxSigma: Float = 6.0
                // let blurSize = ConvolutionKernels.scaleKernelSize(sliderValue)
                // let kernel = ConvolutionKernels.gaussianBlur(size: blurSize, device: view.device!)
                
                swapSourceDestTexture()
                let filter = MPSImageGaussianBlur(device: view.device!, sigma: sliderValue * maxSigma)
                filter.encode(commandBuffer: commandBuffer, sourceTexture: sourceTexture, destinationTexture: destTexture)
            }
            
            if options.getBool(.invertColors) {
                addPostProcessPass(pipeline: invertColorPipelineState, commandBuffer: commandBuffer)
            }
            
            commandBuffer.present(drawable) // render to scene color (output)
            commandBuffer.commit()
        }
    }
    
    // placeholder for now, come back and add dynamic buffer resizing
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        //
    }
    
    func addPostProcessPass(pipeline: MTLComputePipelineState, commandBuffer: MTLCommandBuffer) {
        
        swapSourceDestTexture()
        
        guard let encoder = commandBuffer.makeComputeCommandEncoder() else { return }
        encoder.label = "Post-processing pass: \(pipeline.description)"
        encoder.setComputePipelineState(pipeline)
        encoder.setTexture(sourceTexture, index: 0)
        encoder.setTexture(destTexture, index: 1)

        let threadsPerGrid = MTLSize(width: destTexture.width,
                                     height: destTexture.height,
                                     depth: 1)
        
        let w = pipeline.threadExecutionWidth
        let h = pipeline.maxTotalThreadsPerThreadgroup / w
        let threadsPerThreadgroup = MTLSizeMake(w, h, 1)
        
        // add one for rounding error
        let threadgroupsPerGrid = MTLSizeMake(threadsPerGrid.width / threadsPerThreadgroup.width + 1,
                                              threadsPerGrid.height / threadsPerThreadgroup.height + 1,
                                              1)

        encoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        encoder.endEncoding()
    }
    
    func addConvolutionKernelPass(kernel: MTLTexture, commandBuffer: MTLCommandBuffer) {
        
        swapSourceDestTexture()
        
        guard let encoder = commandBuffer.makeComputeCommandEncoder() else { return }
        encoder.label = "Convolution kernel post-processing pass"
        encoder.setComputePipelineState(convolutionKernelShader)
        encoder.setTexture(sourceTexture, index: 0)
        encoder.setTexture(destTexture, index: 1)
        encoder.setTexture(kernel, index: 2)
        
        let threadsPerGrid = MTLSize(width: sourceTexture.width,
                                     height: sourceTexture.height,
                                     depth: 1)
        
        let w = convolutionKernelShader.threadExecutionWidth
        let h = convolutionKernelShader.maxTotalThreadsPerThreadgroup / w
        let threadsPerThreadgroup = MTLSizeMake(w, h, 1)
        
        // add one for rounding error
        let threadgroupsPerGrid = MTLSizeMake(threadsPerGrid.width / threadsPerThreadgroup.width + 1,
                                              threadsPerGrid.height / threadsPerThreadgroup.height + 1,
                                              1)

        encoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        encoder.endEncoding()
    }
    
    private func setupComputePipelineState(shader: String) -> MTLComputePipelineState {
        let shaderFunction = defaultLibrary.makeFunction(name: shader)!
        return try! view.device!.makeComputePipelineState(function: shaderFunction)
    }

    private func swapSourceDestTexture() {
        let temp = sourceTexture
        sourceTexture = destTexture
        destTexture = temp
    }
    
}
