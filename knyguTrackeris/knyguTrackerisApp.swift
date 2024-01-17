import SwiftUI
import Firebase


@main
struct knyguTrackerisApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            AuthView()
                    }
    }
}
