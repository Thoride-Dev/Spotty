//
//  SplashScreenView.swift
//  Spotty
//
//  Created by Patrick Fortin on 2/13/25.
//

import SwiftUI
import AVKit

struct SplashScreen: View {
    @Binding var isActive: Bool
    @State private var fadeOut = false  // Controls fade animation

    var body: some View {
        ZStack {
            // Corrected background color #031D3D
            Color(red: 3/255, green: 27/255, blue: 53/255)
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer().frame(height: UIScreen.main.bounds.height * 0.2) // Move video up slightly
                FullScreenVideoPlayer(videoName: "logosplash", fileType: "mp4", isActive: $isActive, fadeOut: $fadeOut)
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.3) // Full width, 30% height
                    .clipped()
                Spacer()
            }
            .opacity(fadeOut ? 0 : 1) // Apply fade-out effect
            .animation(.easeOut(duration: 0.6), value: fadeOut) // Smooth fade-out animation
        }
    }
}

// UIKit-based Video Player with Scaling, Muting, and Positioning
struct FullScreenVideoPlayer: UIViewControllerRepresentable {
    var videoName: String
    var fileType: String
    @Binding var isActive: Bool
    @Binding var fadeOut: Bool

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.showsPlaybackControls = false

        if let path = Bundle.main.path(forResource: videoName, ofType: fileType) {
            let player = AVPlayer(url: URL(fileURLWithPath: path))
            controller.player = player
            controller.videoGravity = .resizeAspectFill // Maintain aspect ratio, fill width

            // Mute the video
            player.isMuted = true

            player.play()

            // Detect when video finishes
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
                withAnimation {
                    fadeOut = true // Start fading out
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { // Transition quicker after fade
                    isActive = false
                }
            }
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}
