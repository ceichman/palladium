//
//  LoadVertices.swift
//  Palladium
//
//  Created by Eichman, Charlotte on 11/4/24.
//

import Foundation
import Metal
import simd

// Eventually this file should contain routines to import data from .obj files
// and populate an ApplicationVertex array. Right now it's just a dumping ground for raw vertex data.

class Mesh {
    var triangles: [Triangle]!
    var vertices: [ApplicationVertex]!
    
    // Calculates the normal vectors for an array of triangles, updating values in-place.
    // Each triangle in self.triangles should be made up of elements of vertices: [Vertex].
    // Each vertex in each triangle should be a member of vertices.
    // Only needed upon loading new vertex data.
    func calculateNormals() {
        for i in self.triangles.indices {
            let lineA = self.triangles[i].b.position - self.triangles[i].a.position
            let lineB = self.triangles[i].c.position - self.triangles[i].a.position
            let cross = cross(lineA, lineB)
            self.triangles[i].a.normal += cross
            self.triangles[i].b.normal += cross
            self.triangles[i].c.normal += cross
        }
        // normalize all vertices
        normalizeNormals()
    }
    
    private init(triangles: [Triangle], vertices: [ApplicationVertex]) {
        self.triangles = triangles
        self.vertices = vertices
    }
    
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
            result.append(Vertex(triangle.a))
            result.append(Vertex(triangle.b))
            result.append(Vertex(triangle.c))
        }
        return (result, result.count * MemoryLayout<Vertex>.stride)
    }
    
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
            triangles.append(Triangle(a: vertices[vertexIndices[0]], b: vertices[vertexIndices[1]], c: vertices[vertexIndices[2]]))
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

