//
//  ViewController.swift
//  Palladium
//
//  Created by Eichman, Charlotte on 10/29/24.
//

import UIKit
import Metal
import MetalKit
import simd

class ViewController: UIViewController, MTKViewDelegate {
    
    
    var device: MTLDevice!
    var vertexBuffer: MTLBuffer!
    var pipelineState: MTLRenderPipelineState!
    var commandQueue: MTLCommandQueue!
    var mesh: Mesh!
    
    let outputPixelFormat: MTLPixelFormat = .bgra8Unorm

    @IBOutlet weak var metalView: MTKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set up device and metalView
        device = MTLCreateSystemDefaultDevice()
        metalView.device = self.device
        metalView.delegate = self
        
        
        // load vertices
        // cubeMesh.calculateNormals()
        // self.mesh = cubeMesh
        
        let mainBundle = Bundle.main
        let fileURL = mainBundle.url(forResource: "teapot", withExtension: "obj")!
        let teapotMesh = Mesh.fromOBJ(url: fileURL)
        teapotMesh.calculateNormals()
        self.mesh = teapotMesh
        
        let (vertexArray, dataSize) = self.mesh.vertexArray()
        vertexBuffer = device.makeBuffer(bytes: vertexArray, length: dataSize, options: []) // options have to do with buffer storage and lifetime
        
        // set up render pipeline
        let defaultLibrary = device.makeDefaultLibrary()!  // gets all shaders from Metal files included in project
        let fragmentShader = defaultLibrary.makeFunction(name: "basic_fragment")
        let vertexShader = defaultLibrary.makeFunction(name: "project_vertex")
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexShader
        pipelineStateDescriptor.fragmentFunction = fragmentShader
        pipelineStateDescriptor.depthAttachmentPixelFormat = metalView.depthStencilPixelFormat
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        
        pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptor) // compile pipeline state
        
        commandQueue = device.makeCommandQueue()
        
        // set up display sync
        // timer = CADisplayLink(target: self, selector: #selector(mainLoop))
        // timer.add(to: RunLoop.main, forMode: .default)
        
        
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        //
    }
    
    func draw(in view: MTKView) {
        autoreleasepool {
            // Set up render target texture
            // guard let drawable = metalLayer.nextDrawable() else { return }
            // let renderPassDescriptor = MTLRenderPassDescriptor()
            guard let drawable = view.currentDrawable else { return }
            guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
            renderPassDescriptor.colorAttachments[0].texture = drawable.texture
            renderPassDescriptor.colorAttachments[0].loadAction = .clear
            
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(
                red: 0.0,
                green: 104.0/255.0,
                blue: 55.0/255.0,
                alpha: 1.0
                ) // set the vertices untouched by shaders to this default value (i.e. "background")
            
            // Draw some pretty colors
            let time = Date().timeIntervalSince1970.magnitude
            let redValue   = Float(sin(1.0 * time) / 2.0 + 0.5)  // just a sin of the times i guess..
            let greenValue = Float(sin(1.1 * time) / 2.0 + 0.5)
            let blueValue  = Float(sin(1.2 * time) / 2.0 + 0.5)
            // fragment shader params (make sure the corresponding struct definition in the shader is identical)
            struct FragmentParams
            {
                let color: (Float, Float, Float, Float)  // just like a float4
            }
            var fragParams = FragmentParams(color: (redValue, greenValue, blueValue, 1.0))
            
            let aspectRatio = drawable.layer.drawableSize.height / drawable.layer.drawableSize.width
            let fovDegrees = 40.0
            var projectionParams = ProjectionParams(aspectRatio: Float(aspectRatio),
                                                    fovRadians: Float(fovDegrees / 180.0 * Double.pi),
                                                    nearZ: 0.3,
                                                    farZ: 1000.0,
                                                    time: Float(fmod(time, Double.pi * 2.0)))
            let xPosition = Float(cos(time) * 2.5) + 4.0
            let yPosition = Float(sin(time) * 2.5)
            var transformationParams = TransformationParams(origin: simd_float3(0.0, -2.0, 6.0), rotation: simd_float3(0, yPosition, 0), scale: simd_float3(1, 1, 1))
            let commandBuffer = commandQueue.makeCommandBuffer() // holds one or more render commands
            // configure render command
            guard let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
            renderEncoder.label = "Immediate render pass"
            renderEncoder.setTriangleFillMode(.fill)
            renderEncoder.setCullMode(.back)
            renderEncoder.setRenderPipelineState(pipelineState)
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderEncoder.setVertexBytes(&projectionParams, length: MemoryLayout.size(ofValue: projectionParams), index: 1)
            renderEncoder.setVertexBytes(&transformationParams, length: MemoryLayout.size(ofValue: transformationParams), index: 2)
            renderEncoder.setFragmentBytes(&fragParams, length: MemoryLayout.size(ofValue: fragParams), index: 0) // set*Bytes is convenient because you can pass a buffer to the shader without having to explicitly create it in Swift with device.makeBuffer(). probably saves system memory too
            // interpret vertexCount vertices as instanceCount instances of type .triangle
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: self.mesh.triangles.count * 3) // triangles: 6319
            renderEncoder.endEncoding()
            commandBuffer?.present(drawable) // render to scene color (output)
            commandBuffer?.commit()
        }
    }
    

    
    @objc func mainLoop() {
        autoreleasepool { // make sure render call doesn't leak memory
            // self.render()
        }
    }
}


