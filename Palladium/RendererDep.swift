//
//  Renderer.swift
//  Palladium
//
//  Created by Hao, Emily on 11/11/24.
//

import Foundation
import Metal
import QuartzCore
import simd
import UIKit

class RendererDep {
    // fragment shader params
    // TODO: ensure corresponding struct definition in the shader is identical
    struct FragmentParams
    {
        var color: (Float, Float, Float, Float)  // just like a float4
    }
    
    var device: MTLDevice!
    var metalLayer: CAMetalLayer!
    var vertexBuffer: MTLBuffer!
    var pipelineState: MTLRenderPipelineState!
    var commandQueue: MTLCommandQueue!
    var mesh: Mesh!
    
    var fragParams: FragmentParams
    var projectionParams: ProjectionParams
    var transformationParams: TransformationParams
    
    let outputPixelFormat: MTLPixelFormat = .bgra8Unorm
    
    init(view: UIView, mesh: Mesh) {
        self.device = MTLCreateSystemDefaultDevice()
        self.mesh = mesh
         // the 0001 is a temporary debug thing
        self.fragParams = FragmentParams(color: (0, 0, 0, 1))
        self.projectionParams = ProjectionParams(aspectRatio: 1,
                                                 fovRadians: 0,
                                                 nearZ: 0.3,
                                                 farZ: 1000,
                                                 time: 0)
                                                 // projectionMatrix: simd_float4x4(1))
        self.transformationParams = TransformationParams(origin: simd_float3(0, -2, 8), rotation: simd_float3(0, 0, 0), scale: simd_float3(1, 1, 1))
        
        setupMetalLayer(for: view)
        setupPipeline()
        setupVertexBuffer()
        self.commandQueue = device.makeCommandQueue()
    }
    
    // temp?
    func updateProjectionParameters() {
//        let aspectRatio = Float(metalLayer.drawableSize.width / metalLayer.drawableSize.height)
//        let fovRadians = Float(45 * (.pi / 180.0))  // 45 degrees field of view, adjust as needed
//        projectionParams.aspectRatio = aspectRatio
//        projectionParams.fovRadians = fovRadians
//        projectionParams.nearZ = 0.3
//        projectionParams.farZ = 1000
        
        let aspectRatio = Float(metalLayer.drawableSize.width / metalLayer.drawableSize.height)
            let fovRadians = Float(45 * (.pi / 180.0))  // 45 degrees field of view, adjust as needed
            let nearZ: Float = 0.3
            let farZ: Float = 1000.0
            
            // Perspective projection matrix
            let f = 1.0 / tan(fovRadians / 2.0)
            let projectionMatrix = simd_float4x4([
                simd_float4(f / aspectRatio, 0, 0, 0),
                simd_float4(0, f, 0, 0),
                simd_float4(0, 0, (farZ + nearZ) / (nearZ - farZ), -1),
                simd_float4(0, 0, (2 * farZ * nearZ) / (nearZ - farZ), 0)
            ])
            
            // Pass the projection matrix along with other parameters
            // projectionParams.projectionMatrix = projectionMatrix
            projectionParams.aspectRatio = aspectRatio
            projectionParams.fovRadians = fovRadians
            projectionParams.nearZ = nearZ
            projectionParams.farZ = farZ
        
    }

    
    private func setupMetalLayer(for view: UIView) {
        metalLayer = CAMetalLayer()
        metalLayer.device = device
        metalLayer.pixelFormat = outputPixelFormat
        metalLayer.framebufferOnly = true
        metalLayer.frame = view.layer.frame
        view.layer.addSublayer(metalLayer)
    }
    
    private func setupPipeline() {
        let defaultLibrary = device.makeDefaultLibrary()!
        let vertexShader = defaultLibrary.makeFunction(name: "project_vertex")
        let fragmentShader = defaultLibrary.makeFunction(name: "basic_fragment")
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexShader
        pipelineStateDescriptor.fragmentFunction = fragmentShader
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = outputPixelFormat
        
        pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    }
    
    private func setupVertexBuffer() {
        let (vertexArray, dataSize) = self.mesh.vertexArray()
        vertexBuffer = device.makeBuffer(bytes: vertexArray, length: dataSize, options: [])
    }
    
    func render() {
        
        guard let drawable = metalLayer.nextDrawable() else { return }
        updateProjectionParameters()
                
        /// Draw some pretty colors (should note that this gets called for every render() so it won't be ideal if we have multiple objects of different colors
        let time = Date().timeIntervalSince1970.magnitude
        fragParams.color = (
            Float(sin(1.0 * time) / 2.0 + 0.5),
            Float(sin(1.1 * time) / 2.0 + 0.5),
            Float(sin(1.2 * time) / 2.0 + 0.5),
            1.0
        )
        
        /// Update transformation and projection parameters only when needed
        transformationParams.rotation.y = Float(sin(time) * 2.5)
        
        /// Creates a command buffer
        let commandBuffer = commandQueue.makeCommandBuffer()
        
        /// Creates a render pass descriptor and sets up render target texture
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(
            red: 0.0,
            green: 104.0/255.0,
            blue: 55.0/255.0,
            alpha: 1.0
            ) // set the vertices untouched by shaders to this default value (i.e. "background")
        
        
        /// Configure render command
        guard let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        /// Passes the projection matrix and transformation matrix to the shader (renderer) here
        renderEncoder.setVertexBytes(&projectionParams, length: MemoryLayout.size(ofValue: projectionParams), index: 1)
        renderEncoder.setVertexBytes(&transformationParams, length: MemoryLayout.size(ofValue: transformationParams), index: 2)
        renderEncoder.setFragmentBytes(&fragParams, length: MemoryLayout.size(ofValue: fragParams), index: 0)
        // interpret vertexCount vertices as instanceCount instances of type .triangle
        // removed instance count to avoid multiplicative calls that slowed runtime
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: mesh.triangles.count * 3)
        renderEncoder.endEncoding()
        
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
}


//        // Set up render target texture
//        guard let drawable = metalLayer.nextDrawable() else { return }
//        let renderPassDescriptor = MTLRenderPassDescriptor()
//        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
//        renderPassDescriptor.colorAttachments[0].loadAction = .clear
//        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(
//            red: 0.0,
//            green: 104.0/255.0,
//            blue: 55.0/255.0,
//            alpha: 1.0
//            ) // set the vertices untouched by shaders to this default value (i.e. "background")
//
//        // Draw some pretty colors
//        let time = Date().timeIntervalSince1970.magnitude
//        let redValue   = Float(sin(1.0 * time) / 2.0 + 0.5)  // just a sin of the times i guess..
//        let greenValue = Float(sin(1.1 * time) / 2.0 + 0.5)
//        let blueValue  = Float(sin(1.2 * time) / 2.0 + 0.5)
//        // fragment shader params (make sure the corresponding struct definition in the shader is identical)
//        struct FragmentParams
//        {
//            let color: (Float, Float, Float, Float)  // just like a float4
//        }
//        var fragParams = FragmentParams(color: (redValue, greenValue, blueValue, 1.0))
//
//        let aspectRatio = metalLayer.drawableSize.height / metalLayer.drawableSize.width
//        let fovDegrees = 40.0
//        var projectionParams = ProjectionParams(aspectRatio: Float(aspectRatio),
//                                                fovRadians: Float(fovDegrees / 180.0 * Double.pi),
//                                                nearZ: 0.3,
//                                                farZ: 1000.0,
//                                                time: Float(fmod(time, Double.pi * 2.0)))
//        let xPosition = Float(cos(time) * 2.5) + 3.0
//        let yPosition = Float(sin(time) * 2.5)
//        var transformationParams = TransformationParams(origin: simd_float3(0.0, -2.0, 8.0), rotation: simd_float3(0, yPosition, 0), scale: simd_float3(1, 1, 1))
//        let commandBuffer = commandQueue.makeCommandBuffer() // holds one or more render commands
//        // configure render command
//        guard let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
//        renderEncoder.setTriangleFillMode(.fill)
//        renderEncoder.setCullMode(.back)
//        renderEncoder.setRenderPipelineState(pipelineState)
//        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
//        renderEncoder.setVertexBytes(&projectionParams, length: MemoryLayout.size(ofValue: projectionParams), index: 1)
//        renderEncoder.setVertexBytes(&transformationParams, length: MemoryLayout.size(ofValue: transformationParams), index: 2)
//        renderEncoder.setFragmentBytes(&fragParams, length: MemoryLayout.size(ofValue: fragParams), index: 0) // set*Bytes is convenient because you can pass a buffer to the shader without having to explicitly create it in Swift with device.makeBuffer(). probably saves system memory too
//        // interpret vertexCount vertices as instanceCount instances of type .triangle
//        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: mesh.triangles.count * 3, instanceCount: mesh.triangles.count)
//        renderEncoder.endEncoding()
//        commandBuffer?.present(drawable) // render to scene color (output)
//        commandBuffer?.commit()
