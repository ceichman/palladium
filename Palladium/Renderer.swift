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
    private var motionVectorTexture: MTLTexture!
    private var previousModelTransformations: [ObjectInstance] = []  // instances only hold their position data
    private var previousViewProjection: ViewProjection?
    
    // has to be a var (not static let) because setupComputePipelineState requires access to view.device
    lazy private var invertColorPipelineState = setupComputePipelineState(shader: "invert_color")
    lazy private var copyPipelineState = setupComputePipelineState(shader: "copy")
    lazy private var clearPipelineState = setupComputePipelineState(shader: "clear")
    lazy private var compositePipelineState = setupComputePipelineState(shader: "composite_unweighted")
    lazy private var motionBlurPipelineState = setupComputePipelineState(shader: "motion_blur")
    
    private var currentFrameTime = CACurrentMediaTime()
    static private let maxBlurKernelSize = 35
    static private let maxBlurSigma = Float(maxBlurKernelSize) / 3.0  // pretty sure MPS uses a kernel size three times the given sigma
    
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
        pipelineStateDescriptor.colorAttachments[1].pixelFormat = .bgra8Unorm

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
        
        let motionVectorTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rg16Float,  // only use bg channels
                width: Int(view.drawableSize.width),
                height: Int(view.drawableSize.height),
                mipmapped: false)
        motionVectorTextureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
        motionVectorTextureDescriptor.textureType = .type2D
        motionVectorTexture = device.makeTexture(descriptor: motionVectorTextureDescriptor)
        
    }
    
    func draw(in view: MTKView) {
        
        autoreleasepool { [self] in // ensures efficient memory management
            let now = CACurrentMediaTime()
            let deltaTime = now - currentFrameTime
            currentFrameTime = now
            
            // let the scene update what it wants before things are drawn
            // should be moved off the render thread eventually
            scene.preRenderUpdate(deltaTime)
            let options = optionsProvider.getOptions()
            guard let drawable = view.currentDrawable else { return }
            var renderTarget = drawable.texture  // "var" used so &renderTarget can be passed as inout
            
            // setup geometry pass
            let black = MTLClearColor( red: 0, green: 0, blue: 0, alpha: 0 )

            guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
            // two color attachments (FragmentOut), one for scene color (renderTarget)
            // and one for bloom mask (intermediateRT)
            renderPassDescriptor.colorAttachments[0].texture = renderTarget
            renderPassDescriptor.colorAttachments[0].loadAction = .clear
            renderPassDescriptor.colorAttachments[0].clearColor = black
            
            renderPassDescriptor.colorAttachments[1].texture = intermediateRenderTarget
            renderPassDescriptor.colorAttachments[1].loadAction = .clear
            renderPassDescriptor.colorAttachments[1].clearColor = black
            
            let commandBuffer = commandQueue.makeCommandBuffer()!
            
            /// Projection and transformation parameters
            let aspectRatio: Float = Float(view.bounds.height / view.bounds.width)
            var viewProjection = scene.camera.viewProjection(aspectRatio: aspectRatio)
            if (previousViewProjection == nil) {
                previousViewProjection = viewProjection
            }
            
            guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
            /// Common render encoder configuration
            renderEncoder.label = "Geometry pass"
            let shouldWireframe = options.getBool(.wireframe)
            renderEncoder.setTriangleFillMode(shouldWireframe ? .lines : .fill)
            renderEncoder.setCullMode(.back)
            renderEncoder.setFrontFacing(.clockwise)
            renderEncoder.setRenderPipelineState(pipelineState)
            renderEncoder.setDepthStencilState(depthStencilState)
            
            let shouldMotionBlur = options.getBool(.motionBlur)
            
            for template in scene.objects {
                let instances = template.instances
                guard instances.count > 0 else { continue }
                
                var models = [ModelTransformation]()
                var previousModels = [ModelTransformation]()
                for instance in instances {
                    models.append(instance.modelTransformation())
                    previousModels.append(instance.previousModelTransformation())
                }
                
                let shouldSpecular = options.getBool(.specularHighlights)
                var fragParams = FragmentParams(
                    cameraPosition: scene.camera.position,
                    specularCoefficient: shouldSpecular ? template.material.specularCoefficient : 0.0,
                    bloomThreshold: 1.0 - options.getFloat(.bloomStrength),
                    numDirectionalLights: CInt(scene.directionalLights.count),
                    numPointLights: CInt(scene.pointLights.count)
                )

                renderEncoder.setVertexBuffer(template.vertexBuffer, offset: 0, index: 0)
                renderEncoder.setVertexBytes(&viewProjection, length: MemoryLayout.size(ofValue: viewProjection), index: 1)
                renderEncoder.setVertexBytes(models, length: MemoryLayout<ModelTransformation>.stride * models.count, index: 2)
                renderEncoder.setVertexBytes(&previousViewProjection, length: MemoryLayout.size(ofValue: previousViewProjection), index: 3)
                renderEncoder.setVertexBytes(previousModels, length: MemoryLayout<ModelTransformation>.stride * previousModels.count, index: 4)
                let shouldTexture = options.getBool(.texturing)
                renderEncoder.setFragmentTexture(shouldTexture ? template.material.colorTexture : nil, index: 0)
                renderEncoder.setFragmentTexture(shouldMotionBlur ? motionVectorTexture : nil, index: 1)
                renderEncoder.setFragmentBytes(&fragParams, length: MemoryLayout<FragmentParams>.stride, index: 0)
                renderEncoder.setFragmentBytes(scene.directionalLights, length: MemoryLayout<DirectionalLight>.stride * Int(fragParams.numDirectionalLights), index: 1)
                renderEncoder.setFragmentBytes(scene.pointLights, length: MemoryLayout<PointLight>.stride * Int(fragParams.numPointLights), index: 2)
                // interpret vertexCount vertices as instanceCount instances of type .triangle
                renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: template.mesh.triangles.count * 3, instanceCount: instances.count)

            }
            renderEncoder.endEncoding()
            
            // must come first so mask texture in intermediateRT isn't overwritten
            if options.getBool(.bloom) {
                // remap bloom radius slider [0.0, 20.0]
                let sigma = options.getFloat(.bloomRadius) * 20.0
                // first blur the hpf texture
                let blur = MPSImageGaussianBlur(device: view.device!, sigma: sigma) // play with sigma?
                blur.encode(commandBuffer: commandBuffer, inPlaceTexture: &intermediateRenderTarget)
                // then composite it onto frame
                addCompositePass(commandBuffer: commandBuffer, inA: renderTarget, inB: intermediateRenderTarget, out: renderTarget)
            }
            
            if options.getBool(.boxBlur) {
                let sliderValue = options.getFloat(.blurSize)  // [0, 1)
                let blurSize = ConvolutionKernels.scaleKernelSize(sliderValue, maxKernelSize: Self.maxBlurKernelSize)
                let filter = MPSImageBox(device: view.device!, kernelWidth: blurSize, kernelHeight: blurSize)
                filter.encode(commandBuffer: commandBuffer, inPlaceTexture: &renderTarget)
            }
            
            if options.getBool(.gaussianBlur) {
                let sliderValue = options.getFloat(.blurSize)  // [0, 1)
                let filter = MPSImageGaussianBlur(device: view.device!, sigma: sliderValue * Self.maxBlurSigma)
                filter.encode(commandBuffer: commandBuffer, inPlaceTexture: &renderTarget)
            }
            
            if options.getBool(.sharpen) {
                let (size, weights) = ConvolutionKernels.sharpen()
                let filter = MPSImageConvolution(
                    device: view.device!,
                    kernelWidth: size,
                    kernelHeight: size,
                    weights: weights
                )
                filter.encode(commandBuffer: commandBuffer, sourceTexture: renderTarget, destinationTexture: intermediateRenderTarget)
                addCopyPass(commandBuffer: commandBuffer, from: intermediateRenderTarget, to: renderTarget)
            }
            
            if shouldMotionBlur {
                addMotionBlurPass(pipeline: motionBlurPipelineState , commandBuffer: commandBuffer, inTexture: renderTarget, outTexture: intermediateRenderTarget, velocityTexture: motionVectorTexture)
                addCopyPass(commandBuffer: commandBuffer, from: intermediateRenderTarget, to: renderTarget)
            }

            if options.getBool(.invertColors) {
                addPostProcessPass(pipeline: invertColorPipelineState, commandBuffer: commandBuffer, renderTarget: renderTarget)
            }
            
            commandBuffer.present(drawable) // render to scene color (output)
            commandBuffer.commit()
            
            // reset previous scene and view projection for next frame
            previousViewProjection = viewProjection
            scene.snapshotPrevious()
            
        }
    }
    
    // placeholder for now, come back and add dynamic buffer resizing
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        //
    }
    
    // should only be used for one-to-one post-process effects (don't read pixels other than gid)
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
        
        // add one for rounding error
        let threadgroupsPerGrid = MTLSizeMake(threadsPerGrid.width / threadsPerThreadgroup.width + 1,
                                              threadsPerGrid.height / threadsPerThreadgroup.height + 1,
                                              1)

        encoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        encoder.endEncoding()
    }
    
    func addPostProcessPass(pipeline: MTLComputePipelineState, commandBuffer: MTLCommandBuffer, renderTarget: MTLTexture) {
        addPostProcessPass(pipeline: pipeline, commandBuffer: commandBuffer, inTexture: renderTarget, outTexture: renderTarget)
    }
    
    func addMotionBlurPass(pipeline: MTLComputePipelineState, commandBuffer: MTLCommandBuffer, inTexture: MTLTexture, outTexture: MTLTexture, velocityTexture: MTLTexture) {
        
        guard let encoder = commandBuffer.makeComputeCommandEncoder() else { return }
        encoder.label = "Motion blur pass"
        encoder.setComputePipelineState(pipeline)
        encoder.setTexture(inTexture, index: 0)
        encoder.setTexture(outTexture, index: 1)
        encoder.setTexture(velocityTexture, index: 2)

        let threadsPerGrid = MTLSize(width: inTexture.width,
                                     height: inTexture.height,
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
        
        // clear out motion vectors
        addClearPass(commandBuffer: commandBuffer, target: velocityTexture)
    }
    
    func addCopyPass(commandBuffer: MTLCommandBuffer, from: MTLTexture, to: MTLTexture) {
        addPostProcessPass(pipeline: copyPipelineState, commandBuffer: commandBuffer, inTexture: from, outTexture: to)
    }
    
    func addClearPass(commandBuffer: MTLCommandBuffer, target: MTLTexture) {
        addPostProcessPass(pipeline: clearPipelineState, commandBuffer: commandBuffer, renderTarget: target)
    }
    
    func addCompositePass(commandBuffer: MTLCommandBuffer, inA: MTLTexture, inB: MTLTexture, out: MTLTexture) {
        
        guard let encoder = commandBuffer.makeComputeCommandEncoder() else { return }
        encoder.label = "Motion blur pass"
        encoder.setComputePipelineState(compositePipelineState)
        encoder.setTexture(inA, index: 0)
        encoder.setTexture(inB, index: 1)
        encoder.setTexture(out, index: 2)

        let threadsPerGrid = MTLSize(width: inA.width,
                                     height: inA.height,
                                     depth: 1)
        
        let w = compositePipelineState.threadExecutionWidth
        let h = compositePipelineState.maxTotalThreadsPerThreadgroup / w
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

}
