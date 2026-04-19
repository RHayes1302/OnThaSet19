import SwiftUI
import SwiftData

@main
struct OnThaSetApp: App {
    @AppStorage("hasAcceptedTerms") private var hasAcceptedTerms: Bool = false
    @AppStorage("hasCompletedProfileSetup") private var hasCompletedProfileSetup: Bool = false
    @StateObject private var authService = AuthService()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Event.self,
            UserProfile.self,
            BikeProgress.self,
            EventPhoto.self,
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
            if !hasAcceptedTerms {
                // First launch — show terms
                FirstLaunchDisclaimerView(hasAcceptedTerms: $hasAcceptedTerms)
                    .environmentObject(authService)
            } else if !authService.isLoggedIn {
                // Not logged in — show sign in screen
                GatePage()
                    .environmentObject(authService)
                    .modelContainer(sharedModelContainer)
            } else if !hasCompletedProfileSetup {
                // Logged in but new user — show profile setup
                WelcomeFlowView(hasCompletedSetup: $hasCompletedProfileSetup)
                    .environmentObject(authService)
                    .modelContainer(sharedModelContainer)
            } else {
                // Fully set up — show main app
                DefaultPageView()
                    .environmentObject(authService)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
