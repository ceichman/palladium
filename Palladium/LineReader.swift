//
//  LineReader.swift
//  Palladium
//

import Foundation

public class LineReader: Sequence, IteratorProtocol {
    
    var lines: [String] = []
    var index = 0
    
    public init?(url: URL, encoding: String.Encoding = String.Encoding.utf8) {
        guard let file = try? String(contentsOf: url, encoding: encoding) else { return nil }
        self.lines = file.components(separatedBy: .newlines)
    }

    public func next() -> String? {
        guard lines.count > index + 1 else { return nil }
        let res = lines[index]
        index = index + 1
        return res
    }

    public func rewind() {
        index = 0
    }

}
