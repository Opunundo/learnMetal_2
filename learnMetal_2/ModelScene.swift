//
//  ModelScene.swift
//  learnMetal_2
//
//  Created by Hyeok Cho on 9/13/25.
//

import MetalKit

class ModelScene {
    let device: MTLDevice
    let view: MTKView
    
    let plane = Plane()
    let cube = Cube()
    
    var defaultShader: MTLRenderPipelineState?
    var texturedShader: MTLRenderPipelineState?
    var objShader: MTLRenderPipelineState?
    
    var planeIndexBuffer: MTLBuffer?
    var cubeIndexBuffer: MTLBuffer?
    
    var planeVertexBuffer: MTLBuffer?
    var cubeVertexBuffer: MTLBuffer?
    
    var texture: MTLTexture?
    var frameTexture: MTLTexture?
    var ttouchTexture: MTLTexture?
    
    var meshes: ([MDLMesh], [MTKMesh])?
    
    var time: Float
    
    init(device: MTLDevice, view: MTKView, time: Float) {
        self.device = device
        self.view = view
        self.time = time
        
        buildBuffers()
        defaultShader = buildPipelineState(frag: "fragment_shader")
        texturedShader = buildPipelineState(frag: "defaultTexture")
        objShader = buildOBJPipelineState(frag: "defaultTexture")
        self.meshes = loadModel(device: device, modelName: "Ttouch")
        if let texture = setTexture(device: device, imageName: "image.png") {
            self.texture = texture
        }
        if let ttouchTexture = setTexture(device: device, imageName: "Texture_01") {
            self.ttouchTexture = ttouchTexture
        }
    }

    private func setTexture(device: MTLDevice, imageName: String) -> MTLTexture? {
        let textureLoader = MTKTextureLoader(device:device)
        var texture: MTLTexture? = nil
        
        let textureLoaderOptions: [MTKTextureLoader.Option: Any] = [.origin: MTKTextureLoader.Origin.bottomLeft]
        if let textureURL = Bundle.main.url(forResource: imageName, withExtension: nil) {
            do {
                texture = try textureLoader.newTexture(URL: textureURL, options: textureLoaderOptions)
            } catch {
                print("texture not created")
            }
        }
        
        return texture
    }
    
    private func buildPipelineState(frag: String) -> MTLRenderPipelineState? {
        guard let library = device.makeDefaultLibrary(),
              let vertexFunction = library.makeFunction(name: "vertex_shader"),
              let fragmentFunction = library.makeFunction(name: frag)
        else { return nil }
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        let vertexDescriptor = MTLVertexDescriptor()
        
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        vertexDescriptor.attributes[1].format = .float4
        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        vertexDescriptor.attributes[2].format = .float2
        vertexDescriptor.attributes[2].offset = MemoryLayout<SIMD3<Float>>.stride + MemoryLayout<SIMD4<Float>>.stride
        vertexDescriptor.attributes[2].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
        
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        do {
            let pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            return pipelineState
        } catch let error as NSError {
            print("error: \(error.localizedDescription)")
            return nil
        }
    }
    private func buildOBJPipelineState(frag: String) -> MTLRenderPipelineState? {
        guard let library = device.makeDefaultLibrary(),
              let vertexFunction = library.makeFunction(name: "vertex_shader"),
              let fragmentFunction = library.makeFunction(name: frag)
        else { return nil }
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        let vertexDescriptor = buildVertexDescriptor()
        
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        
        do {
            let pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            return pipelineState
        } catch let error as NSError {
            print("error: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func buildVertexDescriptor() -> MTLVertexDescriptor {
        let vertexDescriptor = MTLVertexDescriptor()
        
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        vertexDescriptor.attributes[1].format = .float4
        vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.stride * 3
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        vertexDescriptor.attributes[2].format = .float2
        vertexDescriptor.attributes[2].offset = MemoryLayout<Float>.stride * 7
        vertexDescriptor.attributes[2].bufferIndex = 0
        
        vertexDescriptor.attributes[3].format = .float3
        vertexDescriptor.attributes[3].offset = MemoryLayout<Float>.stride * 9
        vertexDescriptor.attributes[3].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.stride * 12
        
        return vertexDescriptor
    }
    
    private func buildBuffers() {
        planeVertexBuffer = device.makeBuffer(bytes: plane.planeVertices, length: plane.planeVertices.count * MemoryLayout<Vertex>.stride,//struct를 타입으로 쓰는 경우 .size 대신 .stride 사용. padding이 생길 수도 있으므로
                                         options: [])
        planeIndexBuffer = device.makeBuffer(bytes: plane.planeIndices,
                                             length: plane.planeIndices.count * MemoryLayout<UInt16>.size,
                                        options: [])
        
        cubeVertexBuffer = device.makeBuffer(bytes: cube.cubeVertices, length: cube.cubeVertices.count * MemoryLayout<Vertex>.stride,
                                             options: [])
        cubeIndexBuffer = device.makeBuffer(bytes: cube.cubeIndices, length: cube.cubeIndices.count * MemoryLayout<UInt16>.size,
                                            options: [])
    }
    
    private func loadModel(device: MTLDevice, modelName: String) -> ([MDLMesh], [MTKMesh])? {
        guard let assetURL = Bundle.main.url(forResource: modelName, withExtension: "obj") else {
            fatalError("Asset \(modelName) dose not exist.")
        }
        
        let vertexDescriptor = buildVertexDescriptor()
        let descriptor = MTKModelIOVertexDescriptorFromMetal(vertexDescriptor)
        
        let attributePosition = descriptor.attributes[0] as! MDLVertexAttribute
        attributePosition.name = MDLVertexAttributePosition
        descriptor.attributes[0] = attributePosition
        
        let attributeColor = descriptor.attributes[1] as! MDLVertexAttribute
        attributeColor.name = MDLVertexAttributeColor
        descriptor.attributes[1] = attributeColor
        
        let attributeTexture = descriptor.attributes[2] as! MDLVertexAttribute
        attributeTexture.name = MDLVertexAttributeTextureCoordinate
        descriptor.attributes[2] = attributeTexture
        
        let attributeNormal = descriptor.attributes[3] as! MDLVertexAttribute
        attributeNormal.name = MDLVertexAttributeNormal
        descriptor.attributes[3] = attributeNormal
        
        let bufferAllocator = MTKMeshBufferAllocator(device: device)
        let asset = MDLAsset(url: assetURL, vertexDescriptor: descriptor, bufferAllocator: bufferAllocator)
        
        do {
            let meshes = try MTKMesh.newMeshes(asset: asset, device: device)
            return meshes
        } catch {
            print("mesh error")
            return nil
        }
    }
    
    func render(commandEncoder: MTLRenderCommandEncoder) {
        
        guard let defaultShader = self.defaultShader,
              let texturedShader = self.texturedShader,
              let planeIndexBuffer = self.planeIndexBuffer,
              let cubeIndexBuffer = self.cubeIndexBuffer else { return }
        
        //MARK: Camera
        
        var sceneConstants = SceneConstants()
        let sceneProjectionMatrix = matrix_float4x4(fovY: radians(degrees:65), aspect: 1, near: 0.1, far: 100)
        let sceneRotationMatrix = matrix_float4x4(rotationAngle: 0, x: radians(degrees: -45), y: radians(degrees: -45), z: 0)
        let sceneTranslationMatrix = matrix_float4x4(translationX: 2, y: -2, z: -5)
        
        let sceneViewMatrix = matrix_multiply(sceneProjectionMatrix, sceneTranslationMatrix)
        sceneConstants.sceneViewMatrix = sceneViewMatrix
        
        commandEncoder.setVertexBytes(&sceneConstants, length: MemoryLayout<SceneConstants>.stride,
                                      index: 2)
        
        
        //MARK: Cube
        var cubeModelConstants = ModelConstants()
        
        let cubeRotationMatrix = matrix_float4x4(rotationAngle: time, x:1, y: 0, z: 1)
        let cubeTranslationMatrix = matrix_float4x4(translationX: 0, y: 0, z: -5)
        let cubeScaleMatrix = matrix_float4x4(scaleX: 1.5, y: 1.5, z: 1.5)
        
        let aMatrix = matrix_multiply(cubeScaleMatrix, cubeRotationMatrix)
        let bMatrix = matrix_multiply(cubeTranslationMatrix, aMatrix)
        let cubeModelMatrix = bMatrix
        cubeModelConstants.modelViewMatrix = cubeModelMatrix
        
        commandEncoder.setRenderPipelineState(defaultShader)
        commandEncoder.setVertexBuffer(cubeVertexBuffer, offset: 0, index: 0)
        commandEncoder.setVertexBytes(&cubeModelConstants,
                                      length: MemoryLayout<ModelConstants>.stride,
                                      index: 1)
        commandEncoder.setFragmentTexture(texture, index: 0)

        
        commandEncoder.drawIndexedPrimitives(type: .triangle,
                                             indexCount: cube.cubeIndices.count,
                                      indexType: .uint16,
                                      indexBuffer: cubeIndexBuffer,
                                      indexBufferOffset: 0)
        
        //MARK: Plane
        var planeModelConstants = ModelConstants()
        
        let planeScaleMatrix = matrix_float4x4(scaleX: 4, y: 4, z: 4)
        let planeRotationMatrixX = matrix_float4x4(rotationAngle: radians(degrees: -45), x:1, y: 0, z: 0)
        let planeRotationMatrixY = matrix_float4x4(rotationAngle: radians(degrees: -45), x:0, y: 1, z: 0)
        let planeTranslationMatrix = matrix_float4x4(translationX: -3.5, y: 2, z: -5)
        let calcA = matrix_multiply(planeRotationMatrixX,planeRotationMatrixY)
        let calcB = matrix_multiply(calcA, planeScaleMatrix)
        
        
        planeModelConstants.modelViewMatrix = matrix_multiply( planeTranslationMatrix, calcB)
        
        commandEncoder.setRenderPipelineState(texturedShader)
        commandEncoder.setVertexBuffer(planeVertexBuffer, offset: 0, index: 0)
        commandEncoder.setVertexBytes(&planeModelConstants,
                                      length: MemoryLayout<ModelConstants>.stride,
                                      index: 1)
        commandEncoder.setFragmentTexture(texture, index: 0)

   
        
        commandEncoder.drawIndexedPrimitives(type: .triangle,
                                             indexCount: plane.planeIndices.count,
                                      indexType: .uint16,
                                      indexBuffer: planeIndexBuffer,
                                      indexBufferOffset: 0)

    //MARK: OBJ Model
        
        var sourceModelConstants = ModelConstants()
        let ttouchScaleMatrix = matrix_float4x4(scaleX: 4, y: 4, z: 4)
        let ttouchTranslationMatrix = matrix_float4x4(translationX: -1, y: 1, z: 0)
        sourceModelConstants.modelViewMatrix = matrix_multiply(ttouchTranslationMatrix, ttouchScaleMatrix)
        
        commandEncoder.setRenderPipelineState(objShader!)
        commandEncoder.setVertexBytes(&sourceModelConstants, length: MemoryLayout<ModelConstants>.stride, index: 1)
        
        guard let meshes = self.meshes?.1 as? [MTKMesh], meshes.count > 0 else { return }

        for mesh in meshes {
            let vertexBuffer = mesh.vertexBuffers[0]
            commandEncoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: 0)
            for submesh in mesh.submeshes {
                commandEncoder.drawIndexedPrimitives(type: submesh.primitiveType,
                                                     indexCount: submesh.indexCount,
                                                     indexType: submesh.indexType,
                                                     indexBuffer: submesh.indexBuffer.buffer,
                                                     indexBufferOffset: submesh.indexBuffer.offset)
            }
        }
    }
    
}
