//
//  ViewDelegate.swift
//  learnMetal_2
//
//  Created by Hyeok Cho on 9/6/25.
//
import SwiftUI
import MetalKit

class MetalViewDelegate : NSObject, MTKViewDelegate {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    
    let plane = Plane()
    let cube = Cube()
    
    var samplerState: MTLSamplerState?
    var depthStencilState: MTLDepthStencilState?
    
    var defaultShader: MTLRenderPipelineState?
    var texturedShader: MTLRenderPipelineState?
    
    var planeVertexBuffer: MTLBuffer?
    var planeIndexBuffer: MTLBuffer?
    
    var cubeVertexBuffer: MTLBuffer?
    var cubeIndexBuffer: MTLBuffer?
    
    var cubeModelConstants = ModelConstants()
    var time: Float = 0.0
    
    var texture: MTLTexture?
    var frameTexture: MTLTexture?
    
    init?(metalView: MTKView){
        self.device = metalView.device ?? MTLCreateSystemDefaultDevice()!
        self.commandQueue = self.device.makeCommandQueue()!
        super.init()
        
        if let texture = setTexture(device: device, imageName: "image.png") {
            self.texture = texture
        }
        
        buildSamplerState()
        buildBuffers()
        buildDepthStencilState()
        defaultShader = buildPipelineState(frag: "fragment_shader")
        texturedShader = buildPipelineState(frag: "defaultTexture")
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
    
    private func buildSamplerState() {
        let descriptor = MTLSamplerDescriptor()
        descriptor.minFilter = .linear
        descriptor.magFilter = .linear
        self.samplerState = device.makeSamplerState(descriptor: descriptor)
    }
    
    private func buildDepthStencilState() {
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)
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
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor,
              let defaultShader = self.defaultShader,
              let texturedShader = self.texturedShader,
              let planeIndexBuffer = self.planeIndexBuffer,
              let cubeIndexBuffer = self.cubeIndexBuffer,
              let drawable = view.currentDrawable else
        { return }
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        guard let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        
        commandEncoder.setDepthStencilState(depthStencilState)
        commandEncoder.setFrontFacing(.counterClockwise)
        commandEncoder.setCullMode(.back)
        
        let aspect = Float(1206.0/2622.0)
    
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
        time += 1 / Float(view.preferredFramesPerSecond)
        
        let animatedBy = time
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

        commandEncoder.setFragmentSamplerState(samplerState, index: 0)
        
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

        commandEncoder.setFragmentSamplerState(samplerState, index: 0)
        
        commandEncoder.drawIndexedPrimitives(type: .triangle,
                                             indexCount: plane.planeIndices.count,
                                      indexType: .uint16,
                                      indexBuffer: planeIndexBuffer,
                                      indexBufferOffset: 0)

        
        commandEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

#Preview {
    ContentView()
}
