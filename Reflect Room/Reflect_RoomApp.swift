//
//  ReflectRoomApp.swift
//  Reflect Room
//
//  Created by Andrew Lawrence on 10/30/25.
//

import SwiftUI
import CoreData

@main
struct ReflectRoomApp: App {
    let persistenceController = PersistenceController.shared
    @State private var isLoading = true

    var body: some Scene {
        WindowGroup {
            Group {
                if isLoading {
                    LoadingView()
                        .transition(.opacity)
                } else {
                    HomeView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .transition(.opacity)
                }
            }
            .onAppear {
                // Simulated loading time
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        isLoading = false
                    }
                }
            }
        }
    }
}
