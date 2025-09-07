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
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.clearColor = Colors.wenderlichGreen

        let delegate = MetalViewDelegate(metalKitView: mtkView)
        mtkView.delegate = delegate
        context.coordinator.delegate = delegate
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {}
    
    class Coordinator {
        var delegate: MetalViewDelegate?
    }
}

#Preview {
    ContentView()
}
