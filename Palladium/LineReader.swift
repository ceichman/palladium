//
//  JFLineReader.swift
//  Palladium
//
//  Source: https://github.com/jaz303/JFLineReader.swift/blob/master/Sources/JFLineReader.swift
//

import Foundation

public class JFLineReader: Sequence, IteratorProtocol {
    
    var lines: [String] = []
    var index = 0
    
    public init?(url: URL, maxLength: Int = 8192, encoding: String.Encoding = String.Encoding.utf8) {
        guard let file = try? String(contentsOf: url, encoding: encoding) else { return nil }
        self.lines = file.components(separatedBy: .newlines)
    }

    public func next() -> String? {
        let res = lines[index]
        index = index + 1
        return res
    }

    public func rewind() {
        index = 0
    }

}
