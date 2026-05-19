//
//  ReflectRoomBackground.swift
//  Reflect Room
//
//  Created by Andrew Lawrence on 10/30/25.
//

import SwiftUI

struct ReflectRoomBackground: View {
    @Environment(\.colorScheme) private var scheme
    @State private var hueRotation: Double = 0

    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: backgroundColors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .hueRotation(.degrees(hueRotation))
        .animation(.linear(duration: 12).repeatForever(autoreverses: true), value: hueRotation)
        .onAppear { hueRotation = 360 }
        .ignoresSafeArea(.all)
        .overlay(Color.clear) // Forces full redraw and prevents split artifacts
    }

    private var backgroundColors: [Color] {
        if scheme == .dark {
            return [
                Color(red: 215/255, green: 201/255, blue: 255/255), // Lavender
                Color(red: 182/255, green: 212/255, blue: 255/255), // Blue
                Color(red: 189/255, green: 244/255, blue: 216/255), // Mint
                Color(red: 255/255, green: 213/255, blue: 184/255), // Peach
                Color(red: 255/255, green: 199/255, blue: 214/255)  // Pink
            ]
        } else {
            return [
                Color(red: 216/255, green: 190/255, blue: 255/255),
                Color.white
            ]
        }
    }
}
