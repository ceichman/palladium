//
//  Object.swift
//  Palladium
//
//  Created by Eichman, Charlotte on 11/27/24.
//

import Foundation
import Metal
import MetalKit
import simd

class ObjectTemplate {
    
    private static var nextId = 0
    private static let device = MTLCreateSystemDefaultDevice()!
    private static let mainBundle = Bundle.main
    
    let id: Int!
    lazy var name = String(self.id)
    var mesh: Mesh
    var material: Material
    
    lazy var vertexBuffer: MTLBuffer = {
        let (vertexArray, dataSize) = mesh.vertexArray()
        return Self.device.makeBuffer(bytes: vertexArray, length: dataSize, options: [])!
    }()

    convenience init(meshName: String, textureName: String) {
        self.init(meshName: meshName)
        self.material = Material(colorTextureName: textureName)
    }
    
    convenience init(meshName: String) {
        let meshURL = Self.mainBundle.url(forResource: meshName, withExtension: "obj", subdirectory: "meshes")!
        self.init(mesh: Mesh.fromOBJ(url: meshURL, calculateOrigin: true))
    }

    init(mesh: Mesh) {
        self.mesh = mesh
        self.material = Material()
        id = Self.nextId
        Self.nextId += 1
    }
    
    convenience init(mesh: Mesh, material: Material) {
        self.init(mesh: mesh)
        self.material = material
    }
    
}

extension ObjectTemplate: Hashable {
    
    static func == (lhs: ObjectTemplate, rhs: ObjectTemplate) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
