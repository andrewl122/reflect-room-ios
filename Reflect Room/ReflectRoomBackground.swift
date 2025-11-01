import SwiftUI

struct ReflectRoomBackground: View {
    @State private var hueRotation: Double = 0

    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 216/255, green: 190/255, blue: 255/255),
                Color.white
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .hueRotation(.degrees(hueRotation))
        .animation(.linear(duration: 12).repeatForever(autoreverses: true), value: hueRotation)
        .onAppear {
            hueRotation = 360
        }
        .ignoresSafeArea()
    }
}
