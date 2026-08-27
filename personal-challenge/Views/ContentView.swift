//
//  ContentView.swift
//  personal-challenge
//
//  Created by Raka Febrian Syahputra on 20/08/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ImageClassificationScreen()
                .tabItem {
                    Label("Pemindai", systemImage: "camera.viewfinder")
                }
            
            DrawingCanvasScreen()
                .tabItem {
                    Label("Kanvas", systemImage: "pencil.and.scribble")
                }
        }
    }
}

#Preview {
    ContentView()
}
