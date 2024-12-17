//
//  OptionsProvider.swift
//  Palladium
//
//  Created by Eichman, Charlotte on 12/17/24.
//

import Foundation

typealias RendererOptions = [String:OptionType]

extension RendererOptions {
    static let defaults: RendererOptions = [
        "boxBlur": .bool(false),
        "gaussianBlur": .bool(false),
        "invertColors": .bool(false),
        "texturing": .bool(true),
        "wireframe": .bool(false),
        "specularHighlights": .bool(true),
        "floatOption": .float(0.5),
    ]
    
    func getBool(_ index: String) -> Bool {
        return self[index]!.asBool()!
    }
    
    func getFloat(_ index: String) -> Float {
        return self[index]!.asFloat()!
    }
}

protocol OptionsProvider {
    func getOptions() -> RendererOptions
}

enum OptionType {
    case bool(Bool)
    case float(Float)
    
    func asBool() -> Bool? {
        switch self {
        case .bool(let bool):
            return bool
        default:
            return nil
        }
    }
    
    func asFloat() -> Float? {
        switch self {
        case .float(let float):
            return float
        default:
            return nil
        }
    }
    
}
