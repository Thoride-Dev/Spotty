//
//  SplashScreenView.swift
//  Spotty
//
//  Created by Patrick Fortin on 2/13/25.
//

import SwiftUI
import AVKit
import AVFoundation

struct SplashScreen: View {
    @Binding var isActive: Bool
    @State private var fadeOut = false  // Controls fade animation

    var body: some View {
        ZStack {
            // Corrected background color #031B35 (dark blue)
            Color(red: 3/255, green: 27/255, blue: 53/255)
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer().frame(height: UIScreen.main.bounds.height * 0.2) // Moves video up slightly
                TransparentVideoPlayer(videoName: "Spotty_Splash", fileType: "mov", isActive: $isActive, fadeOut: $fadeOut)
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.3) // Full width, 30% height
                    .clipped()
                Spacer()
            }
            .opacity(fadeOut ? 0 : 1) // Apply fade-out effect
        }
        .animation(.easeOut(duration: 0.6), value: fadeOut) // Smooth fade-out animation
    }
}

struct TransparentVideoPlayer: UIViewRepresentable {
    var videoName: String
    var fileType: String
    @Binding var isActive: Bool
    @Binding var fadeOut: Bool

    class Coordinator {
        var parent: TransparentVideoPlayer

        init(_ parent: TransparentVideoPlayer) {
            self.parent = parent
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear // Ensure transparency

        if let path = Bundle.main.path(forResource: videoName, ofType: fileType) {
            let player = AVPlayer(url: URL(fileURLWithPath: path))
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.videoGravity = .resizeAspect // Keeps aspect ratio

            playerLayer.frame = containerView.bounds
            playerLayer.backgroundColor = UIColor.clear.cgColor // Transparency fix
            
            containerView.layer.addSublayer(playerLayer)

            player.isMuted = true // Mute video
            player.play()

            // Ensure the video layer resizes correctly
            DispatchQueue.main.async {
                playerLayer.frame = containerView.bounds
            }

            // Detect when video finishes
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
                withAnimation {
                    self.fadeOut = true // Start fading out
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { // Transition quicker after fade
                    self.isActive = false
                }
            }
        }
        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Ensure player layer matches SwiftUI frame
        if let playerLayer = uiView.layer.sublayers?.first as? AVPlayerLayer {
            playerLayer.frame = uiView.bounds
        }
    }
}

