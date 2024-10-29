//
//  ViewController.swift
//  Palladium
//
//  Created by Eichman, Charlotte on 10/29/24.
//

import UIKit
import Metal

class ViewController: UIViewController {
    
    var device: MTLDevice!
    var metalLayer: CAMetalLayer! // CALayers exist on all views
    var vertexBuffer: MTLBuffer!
    var pipelineState: MTLRenderPipelineState!
    var commandQueue: MTLCommandQueue!
    var timer: CADisplayLink! // synchronize render call with display refresh rate
    
    let outputPixelFormat: MTLPixelFormat = .bgra8Unorm

    // In Metal, the default coordinate system is the normalized coordinate system, which means that by default you’re looking at a 2x2x1 cube centered at (0, 0, 0.5).
    // If you consider the Z=0 plane, then (-1, -1, 0) is the lower left, (0, 0, 0) is the center, and (1, 1, 0) is the upper right.
    // Placeholder triangle:
    let vertexData: [Float] = [
       0.0,  1.0, 0.0,
      -1.0, -1.0, 0.0,
       1.0, -1.0, 0.0
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set up device and metalLayer
        device = MTLCreateSystemDefaultDevice()
        metalLayer = CAMetalLayer()
        metalLayer.device = device
        metalLayer.pixelFormat = outputPixelFormat
        metalLayer.framebufferOnly = true // set true unless you need to sample intermediate textures for this layer (performance reasons)
        metalLayer.frame = view.layer.frame
        view.layer.addSublayer(metalLayer)
        
        let dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0]) // size of entire vertex data buffer
        vertexBuffer = device.makeBuffer(bytes: vertexData, length: dataSize, options: []) // options have to do with buffer storage and lifetime
        
        // set up render pipeline
        let defaultLibrary = device.makeDefaultLibrary()!  // gets all shaders from Metal files included in project
        let fragmentShader = defaultLibrary.makeFunction(name: "basic_fragment")
        let vertexShader = defaultLibrary.makeFunction(name: "basic_vertex")
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexShader
        pipelineStateDescriptor.fragmentFunction = fragmentShader
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = outputPixelFormat
        
        pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptor) // compile pipeline state
        
        commandQueue = device.makeCommandQueue()
        
        // set up display sync
        timer = CADisplayLink(target: self, selector: #selector(mainLoop))
        timer.add(to: RunLoop.main, forMode: .default)
        
        
    }
    
    func render() {
        guard let drawable = metalLayer.nextDrawable() else { return } // get the scene color texture
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(
            red: 0.0,
            green: 104.0/255.0,
            blue: 55.0/255.0,
            alpha: 1.0
            ) // set the vertices untouched by shaders to this default value (i.e. "background")
        
        let time = Date().timeIntervalSince1970.magnitude
        let redValue   = Float(sin(1.0 * time) / 2.0 + 0.5)  // just a sin of the times i guess..
        let greenValue = Float(sin(1.1 * time) / 2.0 + 0.5)
        let blueValue  = Float(sin(1.2 * time) / 2.0 + 0.5)
        // fragment shader params (make sure the corresponding struct definition in the shader is identical)
        struct FragmentParams
        {
            let color: (Float, Float, Float, Float)  // just like a float4
        }
        var params = FragmentParams(color: (redValue, greenValue, blueValue, 1.0))
        
        let commandBuffer = commandQueue.makeCommandBuffer() // holds one or more render commands
        // configure render command
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderEncoder?.setRenderPipelineState(pipelineState)
        renderEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder?.setFragmentBytes(&params, length: MemoryLayout.size(ofValue: params), index: 0) // set*Bytes is convenient because you can pass a buffer to the shader without having to explicitly create it in Swift with device.makeBuffer(). probably saves system memory too
        renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1) // interpret as one instance of a .triangle with three vertices each (make a vertex object to abstract away magic numbers?)
        renderEncoder?.endEncoding()
        commandBuffer?.present(drawable) // render to scene color (output)
        commandBuffer?.commit()
    }
    
    @objc func mainLoop() {
        autoreleasepool { // make sure render call doesn't leak memory
            self.render()
        }
    }
    


}

