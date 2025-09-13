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
    
    var samplerState: MTLSamplerState?
    var depthStencilState: MTLDepthStencilState?
    
    var time: Float = 0.0
    
    
    init?(metalView: MTKView){
        self.device = metalView.device ?? MTLCreateSystemDefaultDevice()!
        self.commandQueue = self.device.makeCommandQueue()!
        super.init()
    
        buildSamplerState()
        buildDepthStencilState()
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
        
        let modelScene = ModelScene(device: device, view: view, time: time)
        modelScene.render(commandEncoder: commandEncoder)
        
        commandEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

#Preview {
    ContentView()
}
