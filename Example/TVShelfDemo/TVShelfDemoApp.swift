import SwiftUI

@main
struct TVShelfDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(scene: ScreenshotScene.current)
                .preferredColorScheme(.dark)
        }
    }
}
