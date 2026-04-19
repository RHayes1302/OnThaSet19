//
//  ReportEventView.swift
//  OnThaSet (New)
//
//  Allows any user to flag an event for admin review.
//  Reports are written to the `event_reports` table in Supabase.
//

import SwiftUI
import SwiftData

// MARK: - Report Reason

enum ReportReason: String, CaseIterable {
    case inappropriateContent = "Inappropriate Content"
    case spam                 = "Spam / Fake Event"
    case hateSpeech           = "Hate Speech"
    case wrongCategory        = "Wrong Category"
    case duplicate            = "Duplicate Event"
    case other                = "Other"

    var icon: String {
        switch self {
        case .inappropriateContent: return "exclamationmark.triangle.fill"
        case .spam:                 return "bolt.slash.fill"
        case .hateSpeech:           return "hand.raised.slash.fill"
        case .wrongCategory:        return "tag.slash.fill"
        case .duplicate:            return "doc.on.doc.fill"
        case .other:                return "ellipsis.circle.fill"
        }
    }
}

// MARK: - Report Model

struct EventReport: Codable {
    var eventID: String
    var eventTitle: String
    var reportedByUserID: String
    var reason: String
    var additionalNotes: String

    enum CodingKeys: String, CodingKey {
        case eventID           = "event_id"
        case eventTitle        = "event_title"
        case reportedByUserID  = "reported_by_user_id"
        case reason
        case additionalNotes   = "additional_notes"
    }
}

// MARK: - ReportEventView

struct ReportEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]

    let eventID: String
    let eventTitle: String

    @State private var selectedReason: ReportReason? = nil
    @State private var additionalNotes: String = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""

    private var reporterID: String {
        profiles.first?.appleUserID ?? "anonymous"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // Header icon
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.15))
                                .frame(width: 80, height: 80)
                            Image(systemName: "flag.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.red)
                        }
                        .padding(.top, 20)

                        VStack(spacing: 6) {
                            Text("REPORT EVENT")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            Text("\u{201C}" + eventTitle + "\u{201D}")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .padding(.horizontal)
                        }

                        // Reason picker
                        VStack(alignment: .leading, spacing: 10) {
                            Text("REASON")
                                .font(.caption.bold())
                                .foregroundColor(.gray)
                                .padding(.horizontal)

                            VStack(spacing: 8) {
                                ForEach(ReportReason.allCases, id: \.self) { reason in
                                    Button(action: { selectedReason = reason }) {
                                        HStack(spacing: 14) {
                                            Image(systemName: reason.icon)
                                                .font(.title3)
                                                .foregroundColor(selectedReason == reason ? .black : .red)
                                                .frame(width: 28)

                                            Text(reason.rawValue)
                                                .font(.subheadline.bold())
                                                .foregroundColor(selectedReason == reason ? .black : .white)

                                            Spacer()

                                            if selectedReason == reason {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.black)
                                            }
                                        }
                                        .padding()
                                        .background(selectedReason == reason ? Color.red : Color.white.opacity(0.07))
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(selectedReason == reason ? Color.red : Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Optional notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ADDITIONAL DETAILS (optional)")
                                .font(.caption.bold())
                                .foregroundColor(.gray)

                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.07))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )

                                if additionalNotes.isEmpty {
                                    Text("Describe the issue...")
                                        .foregroundColor(.gray.opacity(0.6))
                                        .font(.subheadline)
                                        .padding(14)
                                }

                                TextEditor(text: $additionalNotes)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .scrollContentBackground(.hidden)
                                    .background(.clear)
                                    .padding(10)
                                    .frame(minHeight: 90)
                            }
                            .frame(minHeight: 90)
                        }
                        .padding(.horizontal)

                        // Submit
                        Button(action: submitReport) {
                            HStack {
                                if isSubmitting {
                                    ProgressView().tint(.black)
                                } else {
                                    Image(systemName: "flag.fill")
                                    Text("SUBMIT REPORT")
                                        .font(.headline.bold())
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedReason == nil ? Color.red.opacity(0.3) : Color.red)
                            .foregroundColor(selectedReason == nil ? .white.opacity(0.4) : .white)
                            .cornerRadius(12)
                        }
                        .disabled(selectedReason == nil || isSubmitting)
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.yellow)
                }
                ToolbarItem(placement: .principal) {
                    Text("Report Event")
                        .font(.caption.bold())
                        .foregroundColor(.yellow)
                }
            }
        }
        .alert("Report Submitted", isPresented: $showSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text("Thank you. Our team will review this event and take action if necessary.")
        }
        .alert("Submission Failed", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Submit

    private func submitReport() {
        guard let reason = selectedReason else { return }
        isSubmitting = true

        Task {
            do {
                try await postReport(
                    eventID: eventID,
                    eventTitle: eventTitle,
                    reportedByUserID: reporterID,
                    reason: reason.rawValue,
                    notes: additionalNotes.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                await MainActor.run {
                    isSubmitting = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    private func postReport(
        eventID: String,
        eventTitle: String,
        reportedByUserID: String,
        reason: String,
        notes: String
    ) async throws {
        let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpsdnFob3dmbHZneWF5dGhmemt4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ1NDQ4OTEsImV4cCI6MjA5MDEyMDg5MX0.mtw-bDXWk0U513symOwPR7AQuKH01Kykt55SEIaBtzI"
        let projectURL = "https://zlvqhowflvgyaythfzkx.supabase.co"

        let url = URL(string: "\(projectURL)/rest/v1/event_reports")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")

        let body: [String: Any] = [
            "event_id":             eventID,
            "event_title":          eventTitle,
            "reported_by_user_id":  reportedByUserID,
            "reason":               reason,
            "additional_notes":     notes,
            "status":               "pending"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse

        guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "Supabase", code: httpResponse.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: msg])
        }
    }
}
