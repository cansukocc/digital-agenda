//
//  Dijital_AjandaApp.swift
//  Dijital Ajanda
//
//  Created by Cansu Koç on 21.09.2026.
//

import SwiftUI

@main
struct Dijital_AjandaApp: App {
    @State private var notes = NoteStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(notes)
        }
    }
}
