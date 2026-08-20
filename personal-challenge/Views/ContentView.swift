//
//  ContentView.swift
//  personal-challenge
//
//  Created by Raka Febrian Syahputra on 20/08/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var translationResult: String = "No result yet"
    
    let mlService = MLVisionService()
    
    var body: some View {
        VStack (spacing: 20) {
            Image(systemName: "camera.viewfinder")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundStyle(.blue)
            
            Text("Penerjemah Aksara Jawir")
                .font(.title)
                .bold()
            
            Text("Hasil Terjemahan")
                .font(.title2)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
            Spacer()
        }
        .padding()
        
    }

   
}

#Preview {
    ContentView()
}
