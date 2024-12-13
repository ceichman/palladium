//
//  ShaderTypes.swift
//  Palladium
//
//  Created by Eichman, Charlotte on 12/13/24.
//

import Foundation
import simd
import Metal

struct ViewProjection {
    var view: simd_float4x4
    var projection: simd_float4x4
}

struct ModelTransformation {
    var translation: simd_float4x4
    var rotation: simd_float4x4
    var scaling: simd_float4x4
}

struct DirectionalLight {
    var direction: simd_float3
    var color: simd_float3 = .one
    var intensity: Float = 1.0
    
    init(direction: simd_float3) {
        self.direction = direction
    }
}

struct PointLight {
    var position: simd_float3 = .zero
    var color: simd_float3 = .one
    var intensity: Float = 1.0
    var radius: Float = 1.0
}

struct FragmentParams {
    var cameraPosition: simd_float3
    var specularCoefficient: Float
    var numDirectionalLights: CInt
    var numPointLights: CInt
}

class ConvolutionKernels {
    
    static func boxBlur(size: Int, device: MTLDevice) -> MTLTexture {
        let weights = [Float](repeating: 1, count: size * size)
        return makeTexture(weights: weights, size: size, device: device)
    }
    
    static func gaussianBlur(size: Int, device: MTLDevice) -> MTLTexture {
        // expect size is odd
        var weights = [Float]()
        let sigma = Float(size) / 2.0
        // normalization happens in shader, so no coefficient needed :)
        for row in (0..<size) {
            for col in (0..<size) {
                let numerator: Float = -1 * Float(row * row + col * col)
                let denominator: Float = (2 * sigma * sigma)
                weights.append(exp(numerator / denominator))
            }
        }
        return makeTexture(weights: weights, size: size, device: device)
    }
    
    private static func makeTexture(weights: [Float], size: Int, device: MTLDevice) -> MTLTexture {
        // size should be sqrt(weights.count)
        let descriptor = MTLTextureDescriptor()
        descriptor.pixelFormat = .r32Float  // only need one value
        descriptor.width = Int(sqrt(Double(weights.count)))
        descriptor.height = descriptor.width
        descriptor.usage = .shaderRead
        descriptor.textureType = .type2D
        let kernelTexture = device.makeTexture(descriptor: descriptor)!
        let region = MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0),
                               size: MTLSize(width: descriptor.width, height: descriptor.height, depth: 1))
        let bytesPerRow = 4 * descriptor.width
        kernelTexture.replace(region: region, mipmapLevel: 0, withBytes: weights, bytesPerRow: bytesPerRow)
        return kernelTexture
    }
    
}
