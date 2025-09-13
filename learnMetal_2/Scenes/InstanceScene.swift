//
//  CrowdScene.swift
//  learnMetal_2
//
//  Created by Hyeok Cho on 9/13/25.
//
import SwiftUI
import MetalKit

class InstanceScene: Renderer {
    let device: MTLDevice
    let view: MTKView
    
    var objShader: MTLRenderPipelineState?
    
    var ttouchTexture: MTLTexture?
    var texture: MTLTexture?
    
    var meshes: ([MDLMesh], [MTKMesh])?
    
    init(device: MTLDevice, view: MTKView) {
        self.device = device
        self.view = view
        
        objShader = buildOBJPipelineState(frag: "defaultTexture")
        if let ttouchTexture = setTexture(device: device, imageName: "Texture_01.png") {
            self.ttouchTexture = ttouchTexture
        }
        self.meshes = loadModel(device: device, modelName: "Ttouch")
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
        guard let objShader = self.objShader else { return }
        commandEncoder.setRenderPipelineState(objShader)
        
        var sceneConstants = SceneConstants()
        let sceneProjectionMatrix = matrix_float4x4(fovY: radians(degrees:65), aspect: 1, near: 0.1, far: 100)
        let sceneTranslationMatrix = matrix_float4x4(translationX: 0, y: -1, z: -5)
        
        let sceneViewMatrix = matrix_multiply(sceneProjectionMatrix, sceneTranslationMatrix)
        sceneConstants.sceneViewMatrix = sceneViewMatrix
        
        commandEncoder.setVertexBytes(&sceneConstants, length: MemoryLayout<SceneConstants>.stride,
                                      index: 2)
        
        //MARK: 40 Ttouches
        for _ in 0..<40 {
                               
            var sourceModelConstants = ModelConstants()
                               
            let ttouchScaleMatrix = matrix_float4x4(scaleX: Float(arc4random_uniform(5)), y: Float(arc4random_uniform(5)), z: Float(arc4random_uniform(5)))
            let ttouchTranslationMatrix = matrix_float4x4(translationX: Float(arc4random_uniform(5))-2, y: Float(arc4random_uniform(5))-3, z: -5)
            sourceModelConstants.modelViewMatrix = matrix_multiply(ttouchTranslationMatrix, ttouchScaleMatrix)
            
            commandEncoder.setVertexBytes(&sourceModelConstants, length: MemoryLayout<ModelConstants>.stride, index: 1)
            
            commandEncoder.setFragmentTexture(ttouchTexture, index: 0)
            
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
            
}



#Preview {
    ContentView()
}
