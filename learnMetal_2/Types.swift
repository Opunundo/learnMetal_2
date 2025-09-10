//
//  Types.swift
//  learnMetal_2
//
//  Created by Hyeok Cho on 9/6/25.
//

import simd
import MetalKit

enum Colors {
    static let wenderlichGreen = MTLClearColor(red: 0.0, green: 0.4, blue: 0.21, alpha: 1.0)
}

struct ModelConstants {
    var modelViewMatrix = matrix_identity_float4x4
}

struct SceneConstants {
    var sceneViewMatrix = matrix_identity_float4x4
}

struct Vertex {
    var position: SIMD3<Float>
    var color: SIMD4<Float>
    var texture: SIMD2<Float>
}

struct Primitive {
    
}
