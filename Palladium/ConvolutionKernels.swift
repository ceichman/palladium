//
//  ConvolutionKernels.swift
//  Palladium
//
//  Created by Eichman, Charlotte on 12/13/24.
//

import Foundation
import Metal

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
    
    // Returns a kernel size based on a normalized float value (0..<1).
    static func scaleKernelSize(_ value: Float) -> Int {
        let maxKernelSize = 19
        let maxEvenKernelSize = Float(maxKernelSize - 1)
        let remainderAfterScale = (value * maxEvenKernelSize).truncatingRemainder(dividingBy: 2)
        let kernelSize = Int((value * maxEvenKernelSize) - remainderAfterScale) + 1
        return kernelSize
    }
    
}
