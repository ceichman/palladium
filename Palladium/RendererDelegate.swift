//
//  RendererDelegate.swift
//  Palladium
//
//  Created by Eichman, Charlotte on 11/20/24.
//

import Foundation

protocol RendererDelegate {
    
    /**
     @method preRenderUpdate
     @abstract Called whenever the renderer is about to draw a new frame.
     @discussion Delegate can change mesh properties before rendering is started. Performance-sensitive since it's called on the render thread.
     @param deltaTime Time in seconds since last frame
     */
    // TODO: move this function off of the render thread
    var preRenderUpdate: (CFTimeInterval) -> Void { get }
    
}
