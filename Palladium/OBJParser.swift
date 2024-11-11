//
//  OBJParser.swift
//  Palladium
//
//  Modified from: https://github.com/jaz303/JFOBJParser.swift/blob/master/Sources/JFOBJParser.swift

import Foundation

// https://en.wikipedia.org/wiki/Wavefront_.obj_file


public struct JFOBJParserStats {
    public var numberOfVertices: Int = 0
    public var numberOfTextureCoords: Int = 0
    public var numberOfVertexNormals: Int = 0
    public var numberOfParameterSpaceVertices: Int = 0
    public var numberOfFaces: Int = 0
}

public class JFOBJParser<T: Sequence> where T.Iterator.Element == String {
    
    private let vertexRegex = try! NSRegularExpression(pattern: "^v\\s+([-+]?[0-9]*\\.?[0-9]+)\\s+([-+]?[0-9]*\\.?[0-9]+)\\s+([-+]?[0-9]*\\.?[0-9]+)(\\s+([-+]?[0-9]*\\.?[0-9]+))?(\\s+([-+]?[0-9]*\\.?[0-9]+))?(\\s+([-+]?[0-9]*\\.?[0-9]+))?$", options: [])
    private let textureRegex = try! NSRegularExpression(pattern: "^vt\\s+([-+]?[0-9]*\\.?[0-9]+)\\s+([-+]?[0-9]*\\.?[0-9]+)$", options: [])
    private let normalRegex = try! NSRegularExpression(pattern: "^vn\\s+([-+]?[0-9]*\\.?[0-9]+)\\s+([-+]?[0-9]*\\.?[0-9]+)\\s+([-+]?[0-9]*\\.?[0-9]+)$", options: [])
    private let faceRegex = try! NSRegularExpression(pattern: "^f\\s+(.*)$", options: [])
    // private let faceRegex = try! NSRegularExpression(pattern: "^f\\s+(\\d+)(//(\\d+))?(?:\\s+(\\d+)(//(\\d+))?)*$", options: [])
    // private let faceRegex = try! NSRegularExpression(pattern: "^f\\s+((\\d+)(//(\\d+))?)(?:\\s+((\\d+)(//(\\d+))?))*$", options: [])

    
    public init(source: T) {
        self.source = source
        self.onVertex = { (x, y, z, w, r, g, b) in }
        self.onTextureCoord = { (u, v, w) in }
        self.onVertexNormal = { (x, y, z) in }
        self.onParameterSpaceVertex = { (u, v, w) in }
        self.onFace = { (count, vs, vtcs, vns) in }
        self.onUnknown = { (line) in }
    }
    
    public func count() -> JFOBJParserStats {
        var stats = JFOBJParserStats()
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
                let y = Float(normalMatch[0]!) ?? 0.0
                let z = Float(normalMatch[0]!) ?? 0.0
                
                onVertexNormal(x, y, z)
            }
            
            // # Polygonal face element: f v1/vt1/vn1 v2/vt2/vn2 ...
            // f 1 2 3
            // f 3/1 4/2 5/3
            // f 6/4/1 3/5/3 7/6/5
            // f 7//1 8//2 9//3
            else if let faceMatch = match(line, regex: faceRegex) {
                let faceData = faceMatch[0]!
                var vertexIndices = [Int]()
                var texCoordIndices = [Int]()
                var normalIndices = [Int]()
                let faceElements: [String] = faceData.split(separator: " ").map { String($0) }
                var count = 0
                for element in faceElements {
                    count += 1
                    let components = element.split(separator: "/").map { String($0) }
                    // subtract one because OBJ indices start from 1 for some reason
                    vertexIndices.append(Int(components[0])! - 1)
                    if components.count > 1 { texCoordIndices.append(Int(components[1])! - 1) }
                    if components.count > 2 { normalIndices.append(Int(components[2])! - 1) }
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
