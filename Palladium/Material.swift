//
//  Material.swift
//  Palladium
//
//  Created by Eichman, Charlotte on 12/10/24.
//

import Foundation
import Metal
import MetalKit

class Material {
    // TODO: Get the device from the renderer's MTKView and store it somewhere everyone can access it instead of calling CreateSystemDefaultDevice.
    private static let device = MTLCreateSystemDefaultDevice()!
    public static let textureLoader = MTKTextureLoader(device: device)
    private static let mainBundle = Bundle.main
    
    var colorTexture: MTLTexture?
    var specularCoefficient: Float = 1.0
    var normalMapTexture: MTLTexture?
    var specularMapTexture: MTLTexture?
    
    init() { }  // we can have a nil color texture
    
    init(colorTextureName: String) {
        self.colorTexture = try! Self.textureLoader.newTexture(name: colorTextureName, scaleFactor: 1.0, bundle: Self.mainBundle)
    }
    
    convenience init(colorTextureName: String, specularCoefficient: Float) {
        self.init(colorTextureName: colorTextureName)
        self.specularCoefficient = specularCoefficient
    }
}
