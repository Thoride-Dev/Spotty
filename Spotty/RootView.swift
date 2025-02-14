//
//  RootView.swift
//  Spotty
//
//  Created by Patrick Fortin on 2/13/25.
//

import SwiftUI

struct RootView: View {
    @State private var isActive = true
    @State private var contentOpacity = 0.0 // Initially hidden

    var body: some View {
        ZStack {
            // ContentView starts hidden and fades in
            if #available(iOS 17.0, *) {
                ContentView()
                    .opacity(contentOpacity)
            } else {
                // Fallback on earlier versions
            }

            // Splash screen on top, fades out
            if isActive {
                SplashScreen(isActive: $isActive)
                    .onDisappear {
                        withAnimation(.easeOut(duration: 0.6)) {
                            contentOpacity = 1.0 // Fade in ContentView
                        }
                    }
            }
        }
        .animation(.easeOut(duration: 0.6), value: isActive) // Smooth transition
    }
}
