//
//  OptionsProvider.swift
//  Palladium
//
//  Created by Eichman, Charlotte on 12/17/24.
//

import Foundation


/// All options that a renderer needs.
class RendererOptions {
    var boxBlur: Bool = false
    var gaussianBlur: Bool = false
    var invertColors: Bool = false
    var texturing: Bool = true
    var wireframe: Bool = false
    var specularHighlights: Bool = true
    
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

protocol OptionsProvider {
    func getOptions() -> RendererOptions
}
