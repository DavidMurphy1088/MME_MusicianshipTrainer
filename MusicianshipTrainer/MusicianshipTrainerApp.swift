//
//  MusicianshipTrainerApp.swift
//  MusicianshipTrainer
//
//  Created by David Murphy on 11/20/23.
//

import SwiftUI

@main
struct MusicianshipTrainerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
