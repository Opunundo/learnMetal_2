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




#Preview {
    ContentView()
}
