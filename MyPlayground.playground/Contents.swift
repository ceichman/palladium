import UIKit

var greeting = "Hello, playground"

private let faceRegex = try! NSRegularExpression(pattern: "^f\\s+(\\d+)(?:/(\\d*)/(\\d*))?$", options: [])


let faceLines = [
    "f 1//3",    // Should match vertex 1, no texture, normal 3
    "f 1/2/3",   // Should match vertex 1, texture 2, normal 3
    "f 1",       // Should match vertex 1, no texture, no normal
    "f 1/2",     // Should match vertex 1, texture 2, no normal
    "f 1//",     // Should match vertex 1, no texture, no normal
]

for line in faceLines {
    let matches = faceRegex.matches(in: line, options: [], range: NSRange(location: 0, length: line.utf16.count))
    if !matches.isEmpty {
        let match = matches[0]
        let vertex = (line as NSString).substring(with: match.range(at: 1))
        let texture = (line as NSString).substring(with: match.range(at: 2))
        let normal = (line as NSString).substring(with: match.range(at: 3))
        print("Vertex: \(vertex), Texture: \(texture), Normal: \(normal)")
    } else {
        print("No match for line: \(line)")
    }
}

