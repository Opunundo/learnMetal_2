//
//  ContentView.swift
//  learnMetal_2
//
//  Created by Hyeok Cho on 9/4/25.
//

import SwiftUI
import MetalKit

struct ContentView: View {
    var body: some View {
        metalView()
            .ignoresSafeArea()
    }
}

struct metalView: UIViewRepresentable {
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = TouchMTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.clearColor = Colors.wenderlichGreen

        let delegate = MetalViewDelegate(metalView: mtkView)
        mtkView.delegate = delegate
        mtkView.touchProxy = delegate
        
        context.coordinator.delegate = delegate
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        
    }
    
    class Coordinator {
        var delegate: MetalViewDelegate?
    }
}

class TouchMTKView: MTKView {
    weak var touchProxy: MetalViewDelegate?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchProxy?.handleTouchesBegan(touches, in: self)
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchProxy?.handleTouchesMoved(touches, in: self)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchProxy?.handleTouchesEnded(touches, in: self)
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchProxy?.handleTouchesCancelled(touches, in: self)
    }
}

class MetalViewDelegate : NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    
    private var samplerState: MTLSamplerState?
    private var depthStencilState: MTLDepthStencilState?
    
    private var time: Float = 0.0
    
    
    //화면 회전
    private var yaw: Float = 0
    private var pitch: Float = 0
    private var previousTouch: CGPoint = .zero
    private let sensitivity: Float = 0.01
    
    init?(metalView: MTKView){
        self.device = metalView.device ?? MTLCreateSystemDefaultDevice()!
        self.commandQueue = self.device.makeCommandQueue()!
        super.init()
    
        metalView.depthStencilPixelFormat = .depth32Float
        
        buildSamplerState()
        buildDepthStencilState()
    }
    
    func handleTouchesBegan(_ touches: Set<UITouch>, in view: UIView) {
        guard let t = touches.first else { return }
        previousTouch = t.location(in: view)
    }
    func handleTouchesMoved(_ touches: Set<UITouch>, in view: UIView) {
        guard let t = touches.first else { return }
        let loc = t.location(in: view)
        let dx = Float(previousTouch.x - loc.x)
        let dy = Float(previousTouch.y - loc.y)
        
        pitch += dy * sensitivity
        yaw += dx * sensitivity
        
        previousTouch = loc
    }
    func handleTouchesEnded(_ touches: Set<UITouch>, in view: UIView) {}
    func handleTouchesCancelled(_ touches: Set<UITouch>, in view: UIView) {}
    
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
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable else
        { return }
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        guard let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        commandEncoder.setFragmentSamplerState(samplerState, index: 0)
        commandEncoder.setDepthStencilState(depthStencilState)
        commandEncoder.setFrontFacing(.counterClockwise)
        commandEncoder.setCullMode(.back)
        
        time += 1 / Float(view.preferredFramesPerSecond)
        
        let modelScene = InstanceScene(device: device, view: view, rotation: SIMD2<Float>(yaw, pitch))
//        let modelScene = ModelScene(device: device, view: view, time: time)
        modelScene.render(commandEncoder: commandEncoder)
        
        commandEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

class InstanceScene: Renderer {
    
    var generator = SeededGenerator(seed: 1234)
    
    let device: MTLDevice
    let view: MTKView
    var rotation: SIMD2<Float>
    
    var objShader: MTLRenderPipelineState?
    
    var ttouchTexture: MTLTexture?
    var texture: MTLTexture?
    
    var meshes: ([MDLMesh], [MTKMesh])?
    
    var light = Light()
    
    init(device: MTLDevice, view: MTKView, rotation: SIMD2<Float>) {
        self.device = device
        self.view = view
        self.rotation = rotation
        
        objShader = buildOBJPipelineState(frag: "fragment_litTexture")
        if let ttouchTexture = setTexture(device: device, imageName: "Texture_01.png") {
            self.ttouchTexture = ttouchTexture
        }
        self.meshes = loadModel(device: device, modelName: "Ttouch")
        
        light.color = SIMD3<Float>(0, 0, 1)
        light.ambientIntensity = 0.5
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
              let vertexFunction = library.makeFunction(name: "instanced_vertex_shader"),
              let fragmentFunction = library.makeFunction(name: frag)
        else { return nil }
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
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
        let aspect = Float(view.drawableSize.width / view.drawableSize.height)
        let sceneProjectionMatrix = matrix_float4x4(fovY: radians(degrees:65), aspect: aspect, near: 0.1, far: 100)
        
        let rotX = matrix_float4x4(rotationAngle: rotation.y, x: 1, y: 0, z: 0)
        let rotY = matrix_float4x4(rotationAngle: rotation.x, x: 0, y: 1, z: 0)
        
        let sceneTranslationMatrix = matrix_float4x4(translationX: 0, y: -1, z: -5)
        
        let modelMatrix = matrix_multiply(rotY, rotX)
        let modelViewMatrix = matrix_multiply(sceneTranslationMatrix, modelMatrix)
        
        let sceneViewMatrix = matrix_multiply(sceneProjectionMatrix, modelViewMatrix)
        sceneConstants.sceneViewMatrix = sceneViewMatrix
        
        commandEncoder.setVertexBytes(&sceneConstants, length: MemoryLayout<SceneConstants>.stride,
                                      index: 2)
        
        commandEncoder.setFragmentBytes(&light, length: MemoryLayout<Light>.stride, index: 3)
        
//        MARK: 40 Ttouches, Instancing, One Draw Call
        var sourceModelConstantsArray = [ModelConstants](repeating: ModelConstants(), count: 40)
        guard let meshes = self.meshes?.1 as? [MTKMesh], meshes.count > 0 else { return }
        
        for i in 0..<40 {
            let ttouchScaleMatrix = matrix_float4x4(scaleX: Float(generator.next(upperBound: 5)), y: Float(generator.next(upperBound: 5)), z: Float(generator.next(upperBound: 5)))
            let ttouchTranslationMatrix = matrix_float4x4(translationX: Float(generator.next(upperBound: 5))-2, y: Float(generator.next(upperBound: 5))-3, z: -5)
            sourceModelConstantsArray[i].modelViewMatrix = matrix_multiply(ttouchTranslationMatrix, ttouchScaleMatrix)
        }
        
        commandEncoder.setVertexBytes(&sourceModelConstantsArray, length: MemoryLayout<ModelConstants>.stride * sourceModelConstantsArray.count, index: 1)
        commandEncoder.setFragmentTexture(ttouchTexture, index: 0)
        
        for mesh in meshes {
            let vertexBuffer = mesh.vertexBuffers[0]
            commandEncoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: 0)
            for submesh in mesh.submeshes {
                commandEncoder.drawIndexedPrimitives(type: submesh.primitiveType,
                                                     indexCount: submesh.indexCount,
                                                     indexType: submesh.indexType,
                                                     indexBuffer: submesh.indexBuffer.buffer,
                                                     indexBufferOffset: submesh.indexBuffer.offset,
                                                     instanceCount: 40)
            }
        }
    }
}

#Preview {
    ContentView()
}
