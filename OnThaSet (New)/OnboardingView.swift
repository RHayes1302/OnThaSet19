//
//  OnboardingView.swift
//  OnThaSet (New)
//

import SwiftUI

// MARK: - First Launch Disclaimer

struct FirstLaunchDisclaimerView: View {
    @Binding var hasAcceptedTerms: Bool
    @State private var showingTerms = false
    @State private var showingPrivacy = false
    @State private var agreedToTerms = false
    @State private var agreedToLiability = false
    @State private var shake = false

    private var canProceed: Bool {
        agreedToTerms && agreedToLiability
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 30) {

                    // LOGO
                    VStack(spacing: 8) {
                        ZStack {
                            Image(systemName: "shield.fill")
                                .font(.system(size: 100))
                                .foregroundColor(.yellow)
                            VStack(spacing: -2) {
                                Text("ON").font(.system(size: 16, weight: .black))
                                Text("THA").font(.system(size: 13, weight: .black))
                                Text("SET").font(.system(size: 21, weight: .black))
                            }
                            .foregroundColor(.black).offset(y: -4)
                        }
                        Text("Welcome to On Tha Set")
                            .font(.title2.bold()).foregroundColor(.yellow)
                        Text("The Motorcycle Community Platform")
                            .font(.caption).foregroundColor(.gray)
                    }
                    .padding(.top, 60)

                    // DISCLAIMER CARD
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.shield.fill")
                                .foregroundColor(.yellow).font(.title2)
                            Text("IMPORTANT NOTICE")
                                .font(.headline.bold()).foregroundColor(.yellow)
                        }

                        Text("Before using On Tha Set, please read and acknowledge the following:")
                            .font(.subheadline).foregroundColor(.gray)

                        Divider().background(Color.yellow.opacity(0.3))

                        // LIABILITY NOTICE
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange).font(.caption)
                                Text("EVENT LIABILITY NOTICE")
                                    .font(.caption.bold()).foregroundColor(.orange)
                            }

                            Text("On Tha Set is a technology platform only. We do not organize, host, sponsor, or control any events listed on this platform. Attendance at any event discovered through On Tha Set is entirely at your own risk.")
                                .font(.caption).foregroundColor(.gray)

                            Text("On Tha Set, its owners, operators, and affiliates are NOT responsible for any injury, death, property damage, criminal acts, accidents, or harm of any kind that occurs in connection with events posted on this platform.")
                                .font(.caption.bold()).foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.08))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(15)
                    .padding(.horizontal)

                    // CHECKBOXES
                    VStack(spacing: 16) {

                        // Terms checkbox
                        Button(action: { agreedToTerms.toggle() }) {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                                    .font(.title3)
                                    .foregroundColor(agreedToTerms ? .yellow : .gray)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("I agree to the Terms of Service and Privacy Policy")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.leading)

                                    HStack(spacing: 12) {
                                        Button(action: { showingTerms = true }) {
                                            Text("Read Terms")
                                                .font(.caption.bold())
                                                .foregroundColor(.yellow)
                                                .underline()
                                        }
                                        Button(action: { showingPrivacy = true }) {
                                            Text("Read Privacy Policy")
                                                .font(.caption.bold())
                                                .foregroundColor(.yellow)
                                                .underline()
                                        }
                                    }
                                }
                                Spacer()
                            }
                            .padding()
                            .background(agreedToTerms ? Color.yellow.opacity(0.08) : Color.white.opacity(0.04))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(agreedToTerms ? Color.yellow.opacity(0.5) : Color.gray.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)

                        // Liability checkbox
                        Button(action: { agreedToLiability.toggle() }) {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: agreedToLiability ? "checkmark.square.fill" : "square")
                                    .font(.title3)
                                    .foregroundColor(agreedToLiability ? .yellow : .gray)

                                Text("I understand that On Tha Set is not responsible for any harm, injury, death, or damage that occurs at or in connection with any event posted on this platform. I attend all events at my own risk.")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)

                                Spacer()
                            }
                            .padding()
                            .background(agreedToLiability ? Color.yellow.opacity(0.08) : Color.white.opacity(0.04))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(agreedToLiability ? Color.yellow.opacity(0.5) : Color.gray.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                    .offset(x: shake ? -8 : 0)
                    .animation(shake ? .easeInOut(duration: 0.1).repeatCount(4) : .default, value: shake)

                    // MUST CHECK BOTH notice
                    if !canProceed {
                        Text("You must agree to both statements to continue")
                            .font(.caption).foregroundColor(.orange)
                            .multilineTextAlignment(.center)
                    }

                    // ENTER BUTTON
                    Button(action: {
                        if canProceed {
                            // Save acceptance to UserDefaults
                            UserDefaults.standard.set(true, forKey: "hasAcceptedTerms")
                            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "termsAcceptedDate")
                            withAnimation { hasAcceptedTerms = true }
                        } else {
                            shake = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                shake = false
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: canProceed ? "checkmark.shield.fill" : "lock.fill")
                            Text(canProceed ? "ENTER ON THA SET" : "AGREE TO CONTINUE")
                                .font(.headline.bold())
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canProceed ? Color.yellow : Color.gray.opacity(0.4))
                        .cornerRadius(12)
                        .shadow(color: canProceed ? .yellow.opacity(0.4) : .clear, radius: 8)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showingTerms) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showingPrivacy) {
            PrivacyPolicyView()
        }
    }
}
