import SwiftUI
import SwiftData

@main
struct OnThaSetApp: App {
    @AppStorage("hasAcceptedTerms") private var hasAcceptedTerms: Bool = false
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
            ContentRootView(hasAcceptedTerms: $hasAcceptedTerms)
                .environmentObject(authService)
                .modelContainer(sharedModelContainer)
                .onAppear {
                    authService.modelContext = sharedModelContainer.mainContext
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - Content Root View
struct ContentRootView: View {
    @Binding var hasAcceptedTerms: Bool
    @EnvironmentObject var authService: AuthService
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    // ✅ Derive setup status from the actual logged-in user's profile
    // Never rely on UserDefaults alone — always check the real profile
    private var currentUserProfile: UserProfile? {
        guard let userID = authService.currentUser?.id else { return nil }
        return profiles.first { $0.appleUserID == userID }
            ?? profiles.first { $0.appleUserID.lowercased() == userID.lowercased() }
    }

    private var hasCompletedSetup: Bool {
        guard authService.isLoggedIn else { return false }
        // If we have a profile and it's marked complete — skip setup
        if let profile = currentUserProfile {
            return profile.hasCompletedSetup
        }
        // Profile not yet created (still syncing) — wait
        return false
    }

    var body: some View {
        if !hasAcceptedTerms {
            FirstLaunchDisclaimerView(hasAcceptedTerms: $hasAcceptedTerms)
                .environmentObject(authService)
        } else if !authService.isLoggedIn {
            GatePage()
                .environmentObject(authService)
        } else if !hasCompletedSetup {
            // Either profile not synced yet or new user needing setup
            if currentUserProfile == nil {
                // Still syncing — show spinner
                ZStack {
                    Color.black.ignoresSafeArea()
                    VStack(spacing: 20) {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.yellow)
                            .overlay(
                                VStack(spacing: -1) {
                                    Text("ON").font(.system(size: 10, weight: .black))
                                    Text("THA").font(.system(size: 8, weight: .black))
                                    Text("SET").font(.system(size: 12, weight: .black))
                                }.foregroundColor(.black).offset(y: -2)
                            )
                        ProgressView().tint(.yellow)
                        Text("Loading your profile...")
                            .font(.subheadline).foregroundColor(.gray)
                    }
                }
            } else {
                // Profile exists but setup not complete — show setup
                WelcomeFlowView(profile: currentUserProfile!)
                    .environmentObject(authService)
            }
        } else {
            DefaultPageView()
                .environmentObject(authService)
        }
    }
}
