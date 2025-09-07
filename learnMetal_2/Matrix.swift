//
//  Matrix.swift
//  learnMetal_2
//
//  Created by Hyeok Cho on 9/7/25.
//

import Foundation
import simd

// 공식 상수: Double.pi, Float.pi, CGFloat.pi 사용 가능

func radians(degrees: Float) -> Float {
    return (degrees / 180) * Float.pi
}

func degrees(radians: Float) -> Float {
    return (radians / Float.pi ) * 180
}

extension Float {
    var radiansToDegrees : Float {
        return (self / Float.pi) * 180
    }
    
    var degreesToRadians : Float {
        return (self / 180) * Float.pi
    }
}

extension matrix_float4x4 {
    init(translationX x: Float, y: Float, z: Float) {
        self.init()
        columns = (
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(x, y, z, 1)
        )
    }
    
    func translatedBy(x:Float, y: Float, z: Float) -> matrix_float4x4 {
        let translateMatrix = matrix_float4x4(translationX: x, y: y, z: z)
        return matrix_multiply(self, translateMatrix)
    }
    
    init(scaleX x: Float, y: Float, z: Float) {
        self.init()
        columns = (
            SIMD4<Float>(x, 0, 0, 0),
            SIMD4<Float>(0, y, 0, 0),
            SIMD4<Float>(0, 0, z, 0),
            SIMD4<Float>(0, 0, 0, 1)
        )
    }

    func scaledBy(x: Float, y: Float, z: Float) -> matrix_float4x4 {
        let scaleMatrix = matrix_float4x4(scaleX: x, y: y, z: z)
        return matrix_multiply(self, scaleMatrix)
    }

    init(rotationAngle angle: Float, x: Float, y: Float, z: Float) {
        let a = normalize(SIMD3<Float>(x, y, z))
        let x = a.x, y = a.y, z = a.z
        let c = cos(angle)
        let s = sin(angle)
        let t = 1 - c
        self.init()
        columns = (
            SIMD4<Float>(t*x*x + c,   t*x*y - s*z, t*x*z + s*y, 0),
            SIMD4<Float>(t*x*y + s*z, t*y*y + c,   t*y*z - s*x, 0),
            SIMD4<Float>(t*x*z - s*y, t*y*z + s*x, t*z*z + c,   0),
            SIMD4<Float>(0, 0, 0, 1)
        )
    }

    func rotatedBy(angle: Float, x: Float, y: Float, z: Float) -> matrix_float4x4 {
        let rotateMatrix = matrix_float4x4(rotationAngle: angle, x: x, y: y, z: z)
        return matrix_multiply(self, rotateMatrix)
    }
    
    init(fovY: Float, aspect: Float, near: Float, far: Float) {
        let yScale = 1 / tan(fovY * 0.5)
        let xScale = yScale / aspect
        let zRange = far - near
        let zScale = -(far + near) / zRange
        let wzScale = -2 * far * near / zRange
        self.init()
        columns = (
            SIMD4<Float>(xScale, 0, 0, 0),
            SIMD4<Float>(0, yScale, 0, 0),
            SIMD4<Float>(0, 0, zScale, -1),
            SIMD4<Float>(0, 0, wzScale, 0)
        )
    }
    
    func projectedFov(fovY: Float, aspect: Float, near: Float, far: Float) -> matrix_float4x4 {
        let proj = matrix_float4x4(fovY: fovY, aspect: aspect, near: near, far: far)
        return matrix_multiply(self, proj)
    }
    
}
