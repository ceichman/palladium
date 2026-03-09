//
//  Mesh.swift
//  Palladium
//
//  Created by Eichman, Charlotte on 11/4/24.
//

import Foundation
import Metal
import simd

// A single mesh obejct in the scene.
class Mesh {
    
    var triangles: [Triangle]!
    var vertices: [ApplicationVertex]!
    
    // Calculates the normal vectors for an array of triangles, updating values in-place.
    // Each triangle in self.triangles should be made up of elements of vertices: [Vertex].
    // Each vertex in each triangle should be a member of vertices.
    // Only needed upon loading new vertex data.
    func calculateNormals() {
        for i in self.triangles.indices {
            let vertA = self.vertices[self.triangles[i].a]
            let vertB = self.vertices[self.triangles[i].b]
            let vertC = self.vertices[self.triangles[i].c]
            let lineA = vertB.position - vertA.position
            let lineB = vertC.position - vertA.position
            let cross = normalize(cross(lineA, lineB))
            self.vertices[self.triangles[i].a].normal += cross
            self.vertices[self.triangles[i].b].normal += cross
            self.vertices[self.triangles[i].c].normal += cross
        }
        // normalize all vertices
        normalizeNormals()
    }
    
    // Initialize this instance using an array of triangles and an array of vertices.
    private init(triangles: [Triangle], vertices: [ApplicationVertex]) {
        self.triangles = triangles
        self.vertices = vertices
    }
    
    // Normalize this mesh's normals, in-place.
    func normalizeNormals() {
        for i in vertices.indices {
            if vertices[i].normal == simd_float3.zero { continue }
            vertices[i].normal = normalize(vertices[i].normal)
        }
    }
    
    // Returns the array of shader-ready vertices and the size of the resulting buffer.
    func vertexArray() -> ([Vertex], Int) {
        var result: [Vertex] = []
        for triangle in triangles {
            result.append(Vertex(vertices[triangle.a]))
            result.append(Vertex(vertices[triangle.b]))
            result.append(Vertex(vertices[triangle.c]))
        }
        return (result, result.count * MemoryLayout<Vertex>.stride)
    }
    
    func makeVertexBuffer(device: MTLDevice) -> MTLBuffer {
        var array = [Vertex]()
        for appVertex in self.vertices
        {
            // convert to value-type
            array.append(Vertex(appVertex))
        }
        return device.makeBuffer(bytes: array, length: array.count * MemoryLayout<Vertex>.stride, options: [])!
    }
    
    func makeIndexBuffer(device: MTLDevice) -> MTLBuffer {
        typealias IndexType = UInt16
        var array = [IndexType]()
        for triangle in self.triangles
        {
            array.append(IndexType(triangle.a))
            array.append(IndexType(triangle.b))
            array.append(IndexType(triangle.c))
        }
        return device.makeBuffer(bytes: array, length: array.count * MemoryLayout<IndexType>.stride, options: [])!
    }
    
    // Creates and returns a Mesh object by parsing a .obj text file.
    static func fromOBJ(url: URL, calculateOrigin: Bool = false) -> Mesh {
        
        let reader = LineReader(url: url)!
        let parser = OBJParser(source: reader)
        
        var vertices: [ApplicationVertex] = []
        var normals: [simd_float3] = []
        var uvs: [simd_float2] = []
        var triangles: [Triangle] = []
        
        var vertexAverage = simd_float3.zero
        
        parser.onVertex = { (x, y, z, w, r, g, b) in
            var color = simd_float4.one
            if r != nil {
                color = simd_float4(r!, g!, b!, 1.0)
            }
            vertices.append(ApplicationVertex(
                position: simd_float3(x: Float(x), y: Float(y), z: Float(z)),
                color: color
            ))
            vertexAverage += simd_float3(x, y, z)
        }
        
        parser.onVertexNormal = { (x, y, z) in
            normals.append(simd_float3(x: Float(x), y: Float(y), z: Float(z)))
        }
        
        parser.onTextureCoord = { (u, v, w) in
            uvs.append(simd_float2(x: Float(u), y: Float(v)))
        }
        
        parser.onFace = { (count, vertexIndices, vertexTextureCoordIndices, vertexNormalIndices ) in
            if count != 3 { return }
            for i in 0..<count {
                if vertexNormalIndices.count > i { vertices[vertexIndices[i]].normal += normals[vertexNormalIndices[i]] } // accumulate and normalize later
                if vertexTextureCoordIndices.count > i { vertices[vertexIndices[i]].uvs = uvs[vertexTextureCoordIndices[i]] }
            }
            triangles.append(Triangle(a: vertexIndices[0], b: vertexIndices[1], c: vertexIndices[2]))
        }
        
        parser.onUnknown = { (line) in } // do nothing
        
        parser.parse() // populate arrays
        
        let mesh = Mesh(triangles: triangles, vertices: vertices)
        if normals.isEmpty {
            mesh.calculateNormals()
        }
        mesh.normalizeNormals()
        
        vertexAverage /= Float(vertices.count)
        if calculateOrigin {
            for vertex in vertices {
                vertex.position -= vertexAverage
            }
        }
        
        return mesh
    }
    
}

