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
    @State private var lock = LockManager()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(notes)
                .environment(lock)
        }
    }
}
