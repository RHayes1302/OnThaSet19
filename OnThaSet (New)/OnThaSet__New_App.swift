import SwiftUI
import SwiftData

@main
struct OnThaSetApp: App {
    @AppStorage("hasAcceptedTerms") private var hasAcceptedTerms: Bool = false

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Event.self,
            UserProfile.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            if hasAcceptedTerms {
                DefaultPageView()
                    .environmentObject(AuthService())
            } else {
                FirstLaunchDisclaimerView(hasAcceptedTerms: $hasAcceptedTerms)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
