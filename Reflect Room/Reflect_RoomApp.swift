//
//  Reflect_RoomApp.swift
//  ReflectRoom
//

import SwiftUI
import CoreData


@main
struct Reflect_RoomApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            LoadingView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
