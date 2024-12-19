//
//  OptionsProvider.swift
//  Palladium
//
//  Created by Eichman, Charlotte on 12/17/24.
//

import Foundation

typealias RendererOptions = [OptionKey:OptionType]
typealias KernelRenderPassCount = Int

enum OptionKey: String {
    case boxBlur = "Box Blur"
    case gaussianBlur = "Gaussian Blur"
    case invertColors = "Invert Colors"
    case texturing = "Texturing"
    case wireframe = "Wireframe"
    case specularHighlights = "Specular Highlights"
    case blurSize = "Blur Size"
    case sharpen = "Sharpen"
    case none = "none"
}

extension RendererOptions {
    static let defaults: RendererOptions = [
        .boxBlur: .bool(false),
        .gaussianBlur: .bool(false),
        .invertColors: .bool(false),
        .texturing: .bool(true),
        .wireframe: .bool(false),
        .specularHighlights: .bool(true),
        .blurSize: .float(0.5),
        .sharpen: .float(0)
    ]
    
    func getBool(_ index: OptionKey) -> Bool {
        return self[index]!.asBool()!
    }
    
    func getFloat(_ index: OptionKey) -> Float {
        return self[index]!.asFloat()!
    }
    
}

// makes it easier to sort keys when indexing for table view
extension Dictionary<OptionKey, OptionType>.Keys {
    func sortedOptions() -> [OptionKey] {
        return self.sorted(by: {(a, b) in a.rawValue < b.rawValue })
    }
}

protocol OptionsProvider {
    func getOptions() -> (RendererOptions, KernelRenderPassCount)
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
