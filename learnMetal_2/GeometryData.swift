//
//  GeometryData.swift
//  learnMetal_2
//
//  Created by Hyeok Cho on 9/8/25.
//

import Foundation

class Plane {
    let planeVertices: [Vertex] = [
        Vertex(position: SIMD3<Float>(-1, -1, 0),
               color: SIMD4<Float>(0, 0, 1, 1),
               texture: SIMD2<Float>(0, 0)),
        Vertex(position: SIMD3<Float>(-1, 1, 0),
               color: SIMD4<Float>(1, 0, 0, 1),
               texture: SIMD2<Float>(0, 1)),
        Vertex(position: SIMD3<Float>(1, -1, 0),
               color: SIMD4<Float>(0, 0, 1, 1),
               texture: SIMD2<Float>(1, 0)),
        Vertex(position: SIMD3<Float>(1, 1, 0),
               color: SIMD4<Float>(0, 1, 0, 1),
               texture: SIMD2<Float>(1, 1)),
    ]
     
    let planeIndices: [UInt16] = [
        0, 1, 2,    1, 2, 3
    ]
}

class Cube {
    let cubeVertices: [Vertex] = [
        Vertex(position: SIMD3<Float>(-1, 1, -1),
               color: SIMD4<Float>(0, 0, 1, 1),
               texture: SIMD2<Float>(0, 0)),
        Vertex(position: SIMD3<Float>(-1, -1, -1),
               color: SIMD4<Float>(0, 1, 0, 1),
               texture: SIMD2<Float>(0, 0)),
        Vertex(position: SIMD3<Float>(1, -1, -1),
               color: SIMD4<Float>(1, 0, 0, 1),
               texture: SIMD2<Float>(0, 0)),
        Vertex(position: SIMD3<Float>(1, 1, -1),
               color: SIMD4<Float>(1, 0, 0, 1),
               texture: SIMD2<Float>(0, 0)),
        
        Vertex(position: SIMD3<Float>(-1, 1, 1),
               color: SIMD4<Float>(0, 0, 1, 1),
               texture: SIMD2<Float>(0, 0)),
        Vertex(position: SIMD3<Float>(-1, -1, 1),
               color: SIMD4<Float>(1, 0, 0, 1),
               texture: SIMD2<Float>(0, 0)),
        Vertex(position: SIMD3<Float>(1, -1, 1),
               color: SIMD4<Float>(1, 0.5, 0, 1),
               texture: SIMD2<Float>(0, 0)),
        Vertex(position: SIMD3<Float>(1, 1, 1),
               color: SIMD4<Float>(1, 0, 0, 1),
               texture: SIMD2<Float>(0, 0))
    ]
    
    let cubeIndices: [UInt16] = [
        0, 1 ,2,    2, 3, 0,
        1, 5, 6,    1, 6, 2,
        3, 2, 6,    3, 6, 7,
        4, 0, 3,    4, 3, 7,
        4, 5, 7,    4, 1, 0,
        7, 6, 5,    7, 5, 4
    ]
}
