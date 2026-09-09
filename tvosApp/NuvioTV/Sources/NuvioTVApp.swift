import SwiftUI
import NuvioDomain
import NuvioFeatures

@main
struct NuvioTVApp: App {
    private let dependencies: AppDependencies

    init() {
        dependencies = .live()
    }

    var body: some Scene {
        WindowGroup {
            AppShellView(dependencies: dependencies)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    // Deep-link parsing is owned by NuvioDomain. The shell's
                    // navigation hook is deliberately the only app-layer seam.
                    _ = DeepLink(url: url)
                }
        }
    }
}
