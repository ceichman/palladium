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

class Object: Hashable {
    
    private static var nextId = 0
    
    private static let device = MTLCreateSystemDefaultDevice()!
    private static let textureLoader = MTKTextureLoader(device: device)
    private static let mainBundle = Bundle.main
    
    let id: Int!
    var mesh: Mesh
    var texture: MTLTexture?
    lazy var name = String(self.id)
    
    lazy var vertexBuffer: MTLBuffer = {
        let (vertexArray, dataSize) = mesh.vertexArray()
        return Self.device.makeBuffer(bytes: vertexArray, length: dataSize, options: [])!
    }()

    var position = simd_float3(0, 0, 1)   // World-space position of the mesh
    var rotation = simd_float3.zero       // 3D rotation (subject to gimbal lock)
    var scale = simd_float3.one           // Per-axis scaling

    convenience init(meshName: String, textureName: String) {
        self.init(meshName: meshName)
        self.texture = try! Self.textureLoader.newTexture(name: textureName, scaleFactor: 1.0, bundle: Self.mainBundle)
        // self.texture = try! Self.textureLoader.newTexture(URL: textureURL)
    }
    
    convenience init(meshName: String) {
        let meshURL = Self.mainBundle.url(forResource: meshName, withExtension: "obj", subdirectory: "meshes")!
        self.init(mesh: Mesh.fromOBJ(url: meshURL, calculateOrigin: true))
    }

    init(mesh: Mesh) {
        self.mesh = mesh
        id = Object.nextId
        Object.nextId += 1
    }
    
    convenience init(mesh: Mesh, texture: MTLTexture) {
        self.init(mesh: mesh)
        self.texture = texture
    }
    
    func modelTransformation() -> ModelTransformation {
        let translation = translation_matrix(t: position)
        let rotation = rotation_matrix(axis: PITCHAXIS, theta: rotation.x) *
                       rotation_matrix(axis: YAWAXIS, theta: rotation.y) *
                       rotation_matrix(axis: ROLLAXIS, theta: rotation.z)
        let scaling = scaling_matrix(scale: scale)
        return ModelTransformation(translation: translation, rotation: rotation, scaling: scaling)
    }
    
    static func == (lhs: Object, rhs: Object) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

}
