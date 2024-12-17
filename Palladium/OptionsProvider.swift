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

protocol OptionsProvider {
    func getOptions() -> RendererOptions
}
