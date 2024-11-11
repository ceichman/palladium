import Metal
import MetalKit
import simd

class Render: NSObject {
    var device: MTLDevice!
    var vertexBuffer: MTLBuffer!
    var pipelineState: MTLRenderPipelineState!
    var commandQueue: MTLCommandQueue!
    var mesh: Mesh!
    let outputPixelFormat: MTLPixelFormat = .bgra8Unorm

    init(device: MTLDevice, mesh: Mesh) {
        super.init()
        
        self.device = device
        self.mesh = mesh
        setup()
    }
    
    private func setup() {
        // Set up render pipeline
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

        // Create vertex buffer
        let (vertexArray, dataSize) = mesh.vertexArray()
        vertexBuffer = device.makeBuffer(bytes: vertexArray, length: dataSize, options: [])
    }
    
    func render(in view: MTKView) {
        autoreleasepool {
            guard let drawable = view.currentDrawable else { return }
            guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
            renderPassDescriptor.colorAttachments[0].texture = drawable.texture
            renderPassDescriptor.colorAttachments[0].loadAction = .clear
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(
                red: 0.0,
                green: 104.0 / 255.0,
                blue: 55.0 / 255.0,
                alpha: 1.0
            )
            
            // Set fragment parameters
            let time = Date().timeIntervalSince1970.magnitude
            let redValue = Float(sin(1.0 * time) / 2.0 + 0.5)
            let greenValue = Float(sin(1.1 * time) / 2.0 + 0.5)
            let blueValue = Float(sin(1.2 * time) / 2.0 + 0.5)
            struct FragmentParams {
                let color: (Float, Float, Float, Float)
            }
            var fragParams = FragmentParams(color: (redValue, greenValue, blueValue, 1.0))
            
            let aspectRatio = Float(view.bounds.height / view.bounds.width)
            let fovDegrees = 40.0
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
            
            let commandBuffer = commandQueue.makeCommandBuffer()
            guard let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
            renderEncoder.label = "Immediate render pass"
            renderEncoder.setTriangleFillMode(.fill)
            renderEncoder.setCullMode(.back)
            renderEncoder.setRenderPipelineState(pipelineState)
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderEncoder.setVertexBytes(&projectionParams, length: MemoryLayout.size(ofValue: projectionParams), index: 1)
            renderEncoder.setVertexBytes(&transformationParams, length: MemoryLayout.size(ofValue: transformationParams), index: 2)
            renderEncoder.setFragmentBytes(&fragParams, length: MemoryLayout.size(ofValue: fragParams), index: 0)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: mesh.triangles.count * 3)
            renderEncoder.endEncoding()
            
            commandBuffer?.present(drawable)
            commandBuffer?.commit()
        }
    }
}
