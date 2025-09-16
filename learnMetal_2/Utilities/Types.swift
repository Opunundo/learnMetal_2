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

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1
        return state
    }
    mutating func next(upperBound: UInt32) -> UInt32 {
        return UInt32(next() % UInt64(upperBound))
    }
}

struct Light {
    var color = SIMD3<Float>(repeating: 1)
    var ambientIntensity: Float = 1.0
}
