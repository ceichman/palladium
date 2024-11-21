//
//  OBJParser.swift
//  Palladium
//
//  Modified from: https://github.com/jaz303/JFOBJParser.swift/blob/master/Sources/JFOBJParser.swift

import Foundation

// https://en.wikipedia.org/wiki/Wavefront_.obj_file


public struct OBJParserStats {
    public var numberOfVertices: Int = 0
    public var numberOfTextureCoords: Int = 0
    public var numberOfVertexNormals: Int = 0
    public var numberOfParameterSpaceVertices: Int = 0
    public var numberOfFaces: Int = 0
}

public class OBJParser<T: Sequence> where T.Iterator.Element == String {
    
    private let vertexRegex = try! NSRegularExpression(pattern: "^v\\s+(-?\\d*\\.?\\d+)\\s+(-?\\d*\\.?\\d+)\\s+(-?\\d*\\.?\\d+)(\\s+(-?\\d*\\.?\\d+))?(\\s+(-?\\d*\\.?\\d+))?(\\s+(-?\\d*\\.?\\d+))?$")
    private let textureRegex = try! NSRegularExpression(pattern: "^vt\\s+(-?\\d*\\.?\\d+)\\s+(-?\\d*\\.?\\d+)\\s+(-?\\d*\\.?\\d+)*$")
    private let normalRegex = try! NSRegularExpression(pattern: "^vn\\s+(-?\\d*\\.?\\d+)\\s+(-?\\d*\\.?\\d+)\\s+(-?\\d*\\.?\\d+)$")
    private let faceRegexVertexOnly = try! NSRegularExpression(pattern: "^f\\s(\\d+)\\s(\\d+)\\s(\\d+)$")
    private let faceRegexVertexTexture = try! NSRegularExpression(pattern: "^f\\s+(\\d+)/(\\d+)\\s+(\\d+)/(\\d+)\\s+(\\d+)/(\\d+)\\s*$")
    private let faceRegexVertexNormal = try! NSRegularExpression(pattern: "^f\\s+(\\d+)//(\\d+)\\s+(\\d+)//(\\d+)\\s+(\\d+)//(\\d+)\\s*$")
    private let faceRegexVertexTextureNormal = try! NSRegularExpression(pattern: "^f\\s+(\\d+)/(\\d+)/(\\d+)\\s+(\\d+)/(\\d+)/(\\d+)\\s+(\\d+)/(\\d+)/(\\d+)\\s*$")


    public init(source: T) {
        self.source = source
        self.onVertex = { (x, y, z, w, r, g, b) in }
        self.onTextureCoord = { (u, v, w) in }
        self.onVertexNormal = { (x, y, z) in }
        self.onParameterSpaceVertex = { (u, v, w) in }
        self.onFace = { (count, vs, vtcs, vns) in }
        self.onUnknown = { (line) in }
    }
    
    public func count() -> OBJParserStats {
        var stats = OBJParserStats()
        for line in source {
            if line.hasPrefix("v ") {
                stats.numberOfVertices += 1
            } else if line.hasPrefix("vt ") {
                stats.numberOfTextureCoords += 1
            } else if line.hasPrefix("vn ") {
                stats.numberOfVertexNormals += 1
            } else if line.hasPrefix("vp ") {
                stats.numberOfParameterSpaceVertices += 1
            } else if line.hasPrefix("f ") {
                stats.numberOfFaces += 1
            }
        }
        return stats
    }
    
    private func match(_ line: String, regex: NSRegularExpression) -> [String?]? {
        let nsRange = NSRange(line.startIndex..<line.endIndex, in: line)
        guard let match = regex.firstMatch(in: String(line), options: [], range: nsRange)
        else { return nil }
        var result: [String?] = []
        for i in 1..<match.numberOfRanges {
            let range = match.range(at: i)
            if let range = Range(range, in: line) {
                result.append(String(line[range]))
            }
        }
        return result
    }
    
    public func parse() {
        for line in source {
            // # List of geometric vertices, with (x,y,z[,w]) coordinates, w is optional and defaults to 1.0.
            // also supports trailing r,g,b vertex colours
            // v 0.123 0.234 0.345 1.0
            if let vertexMatch = match(line, regex: vertexRegex) {
                let x = Float(vertexMatch[0]!) ?? 0.0
                let y = Float(vertexMatch[1]!) ?? 0.0
                let z = Float(vertexMatch[2]!) ?? 0.0
                // optional params
                let w = vertexMatch.count > 3 ? Float(vertexMatch[3] ?? "1.0")! : 1.0
                let r = vertexMatch.count > 4 ? Float(vertexMatch[4] ?? "1.0")! : 1.0
                let g = vertexMatch.count > 5 ? Float(vertexMatch[5] ?? "1.0")! : 1.0
                let b = vertexMatch.count > 6 ? Float(vertexMatch[6] ?? "1.0")! : 1.0
                
                onVertex(x, y, z, w, r, g, b)
            }
            
            // # List of texture coordinates, in (u, v [,w]) coordinates, these will vary between 0 and 1, w is optional and defaults to 0.
            // vt 0.500 1
            else if let textureMatch = match(line, regex: textureRegex) {
                let u = Float(textureMatch[0]!) ?? 0.0
                let v = Float(textureMatch[1]!) ?? 0.0
                // optional params
                let w = textureMatch.count > 2 ? Float(textureMatch[2] ?? "0.0")! : 0.0
                
                onTextureCoord(u, v, w)
            }
                
            // # List of vertex normals in (x,y,z) form; normals might not be unit vectors.
            // vn 0.707 0.000 0.707
            else if let normalMatch = match(line, regex: normalRegex) {
                let x = Float(normalMatch[0]!) ?? 0.0
                let y = Float(normalMatch[1]!) ?? 0.0
                let z = Float(normalMatch[2]!) ?? 0.0
                
                onVertexNormal(x, y, z)
            }
            
            // # Polygonal face element: f v1/vt1/vn1 v2/vt2/vn2 ...
            // f 1 2 3
            // f 3/1 4/2 5/3
            // f 6/4/1 3/5/3 7/6/5
            // f 7//1 8//2 9//3
            
            else if let faceVertexMatch = match(line, regex: faceRegexVertexOnly) {
                var vertexIndices = [Int]()
                for vertexIndex in faceVertexMatch {
                    vertexIndices.append(Int(vertexIndex!)! - 1)
                }
                onFace(faceVertexMatch.count, vertexIndices, [], [])
            }
            
            else if let faceVertexTextureMatch = match(line, regex: faceRegexVertexTexture) {
                let count = faceVertexTextureMatch.count / 2  // matches one v and one vn for each vertex in the face
                var vertexIndices = [Int]()
                var texCoordIndices = [Int]()
                for i in 0..<count {
                    vertexIndices.append(Int(faceVertexTextureMatch[2 * i]!)! - 1)
                    texCoordIndices.append(Int(faceVertexTextureMatch[(2 * i) + 1]!)! - 1)
                }
                onFace(count, vertexIndices, texCoordIndices, [])
            }
            
            else if let faceVertexNormalMatch = match(line, regex: faceRegexVertexNormal) {
                let count = faceVertexNormalMatch.count / 2
                var vertexIndices = [Int]()
                var normalIndices = [Int]()
                for i in 0..<count {
                    vertexIndices.append(Int(faceVertexNormalMatch[2 * i]!)! - 1)
                    normalIndices.append(Int(faceVertexNormalMatch[(2 * i) + 1]!)! - 1)
                }
                onFace(count, vertexIndices, [], normalIndices)
            }
            
            else if let faceVertexTextureNormalMatch = match(line, regex: faceRegexVertexTextureNormal) {
                let count = faceVertexTextureNormalMatch.count / 3
                var vertexIndices = [Int]()
                var texCoordIndices = [Int]()
                var normalIndices = [Int]()
                for i in 0..<count {
                    vertexIndices.append(Int(faceVertexTextureNormalMatch[3 * i]!)! - 1)
                    texCoordIndices.append(Int(faceVertexTextureNormalMatch[(3 * i) + 1]!)! - 1)
                    normalIndices.append(Int(faceVertexTextureNormalMatch[(3 * i) + 2]!)! - 1)
                }
                onFace(count, vertexIndices, texCoordIndices, normalIndices)
            }
            
        }
    }

    public var onVertex: (Float, Float, Float, Float, Float, Float, Float) -> Void
    public var onTextureCoord: (Float, Float, Float) -> Void
    public var onParameterSpaceVertex: (Float, Float, Float) -> Void
    public var onVertexNormal: (Float, Float, Float) -> Void
    public var onFace: (Int, [Int], [Int], [Int]) -> Void
    public var onUnknown: (String) -> Void

    private let source: T
}
