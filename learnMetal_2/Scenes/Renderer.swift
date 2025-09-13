//
//  Renderer.swift
//  learnMetal_2
//
//  Created by Hyeok Cho on 9/13/25.
//

import MetalKit

protocol Renderer {
    func render(commandEncoder: MTLRenderCommandEncoder) 
}
