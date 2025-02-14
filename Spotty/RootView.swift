//
//  RootView.swift
//  Spotty
//
//  Created by Patrick Fortin on 2/13/25.
//

import SwiftUI

struct RootView: View {
    @State private var isActive = true

    var body: some View {
        if isActive {
            SplashScreen(isActive: $isActive)
        } else {
            if #available(iOS 17.0, *) {
                ContentView()
            } else {
                // Fallback on earlier versions
            }
        }
    }
}
