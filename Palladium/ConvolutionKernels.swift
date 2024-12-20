//
//  ConvolutionKernels.swift
//  Palladium
//
//  Created by Eichman, Charlotte on 12/13/24.
//

import Foundation
import Metal

typealias KernelSize = Int
typealias ConvolutionKernel = (KernelSize, [Float])

class ConvolutionKernels {
    
    // Should be used to create normalized convolution kernels for consumption by MPSImageConvolution.
    
    static func boxBlur(size: Int) -> ConvolutionKernel {
        let weights = [Float](repeating: 1 / Float(size * size), count: size * size)
        return (size, weights)
    }
    
    // broken
    static func gaussianBlur(sigma: Float) -> ConvolutionKernel {
        var weights = [Float]()
        var size = Int(sigma * 3)
        size = size & 2 == 0 ? size + 1 : size
        let coeff = 1.0 / (2 * Float.pi * sigma * sigma)
        for row in (0..<size) {
            for col in (0..<size) {
                let numerator: Float = -1 * Float(row * row + col * col)
                let denominator: Float = (2 * sigma * sigma)
                weights.append(coeff * exp(numerator / denominator))
            }
        }
        return (size, weights)
    }
    
    static func sharpen() -> ConvolutionKernel {
        let weights: [Float] = [
            0, -1,  0,
            -1, 5, -1,
            0, -1,  0
        ]
        return (3, weights)
    }
    
    // Returns a kernel size based on a normalized float value (0..<1).
    static func scaleKernelSize(_ value: Float, maxKernelSize: Int) -> Int {
        let maxEvenKernelSize = Float(maxKernelSize - 1)
        let remainderAfterScale = (value * maxEvenKernelSize).truncatingRemainder(dividingBy: 2)
        let kernelSize = Int((value * maxEvenKernelSize) - remainderAfterScale) + 1
        return kernelSize
    }
    
}

