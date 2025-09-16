//
//  ViewDelegate.swift
//  learnMetal_2
//
//  Created by Hyeok Cho on 9/6/25.
//
import SwiftUI
import MetalKit

//class MetalViewDelegate : NSObject, MTKViewDelegate {
//    private let device: MTLDevice
//    private let commandQueue: MTLCommandQueue
//    
//    private var samplerState: MTLSamplerState?
//    private var depthStencilState: MTLDepthStencilState?
//    
//    private var time: Float = 0.0
//    
//    
//    //화면 회전
//    private var yaw: Float = 0
//    private var pitch: Float = 0
//    private var previousTouch: CGPoint = .zero
//    private let sensitivity: Float = 0.01
//    
//    init?(metalView: MTKView){
//        self.device = metalView.device ?? MTLCreateSystemDefaultDevice()!
//        self.commandQueue = self.device.makeCommandQueue()!
//        super.init()
//    
//        metalView.depthStencilPixelFormat = .depth32Float
//        
//        buildSamplerState()
//        buildDepthStencilState()
//    }
//    
//    func handleTouchesBegan(_ touches: Set<UITouch>, in view: UIView) {
//        guard let t = touches.first else { return }
//        previousTouch = t.location(in: view)
//    }
//    func handleTouchesMoved(_ touches: Set<UITouch>, in view: UIView) {
//        guard let t = touches.first else { return }
//        let loc = t.location(in: view)
//        let dx = Float(previousTouch.x - loc.x)
//        let dy = Float(previousTouch.y - loc.y)
//        
//        pitch += dy * sensitivity
//        yaw += dx * sensitivity
//        
//        previousTouch = loc
//    }
//    func handleTouchesEnded(_ touches: Set<UITouch>, in view: UIView) {}
//    func handleTouchesCancelled(_ touches: Set<UITouch>, in view: UIView) {}
//    
//    private func buildSamplerState() {
//        let descriptor = MTLSamplerDescriptor()
//        descriptor.minFilter = .linear
//        descriptor.magFilter = .linear
//        self.samplerState = device.makeSamplerState(descriptor: descriptor)
//    }
//    
//    private func buildDepthStencilState() {
//        let depthStencilDescriptor = MTLDepthStencilDescriptor()
//        depthStencilDescriptor.depthCompareFunction = .less
//        depthStencilDescriptor.isDepthWriteEnabled = true
//        depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)
//    }
//    
//    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
//        
//    }
//    
//    func draw(in view: MTKView) {
//        guard let renderPassDescriptor = view.currentRenderPassDescriptor,
//              let drawable = view.currentDrawable else
//        { return }
//        
//        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
//        guard let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
//        commandEncoder.setFragmentSamplerState(samplerState, index: 0)
//        commandEncoder.setDepthStencilState(depthStencilState)
//        commandEncoder.setFrontFacing(.counterClockwise)
//        commandEncoder.setCullMode(.back)
//        
//        time += 1 / Float(view.preferredFramesPerSecond)
//        
//        let modelScene = InstanceScene(device: device, view: view)
////        let modelScene = ModelScene(device: device, view: view, time: time)
//        modelScene.render(commandEncoder: commandEncoder)
//        
//        commandEncoder.endEncoding()
//        commandBuffer.present(drawable)
//        commandBuffer.commit()
//    }
//}
//
//#Preview {
//    ContentView()
//}
