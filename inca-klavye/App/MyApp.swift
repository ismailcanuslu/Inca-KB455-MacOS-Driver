import SwiftUI

@main struct MyApp: App {
    var body: some Scene {
        WindowGroup("Inca Empousa") {
            ContentView()
                .frame(minWidth: 920, minHeight: 620)
        }
        .windowToolbarStyle(.unified(showsTitle: false))
        .defaultSize(width: 1060, height: 740)
    }
}
