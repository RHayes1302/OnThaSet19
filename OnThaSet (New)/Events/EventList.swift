//
//  EventList.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 12/4/25.
//

import SwiftUI
import SwiftData

struct EventHomeView: View {
    @Environment(\.modelContext) private var modelContext
    // 1. BACK BUTTON LOGIC: Environment variable to allow the view to close
    @Environment(\.dismiss) var dismiss
    @Query(sort: \Event.date) private var events: [Event]
    
    @State private var viewMode: ViewMode
    @State private var selectedDate = Date()

    enum ViewMode {
        case list, calendar
    }

    init(initialMode: ViewMode) {
        _viewMode = State(initialValue: initialMode)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // YELLOW HIGHWAY SIGN HEADER LOGO
                VStack(spacing: -5) {
                    ZStack {
                        // The Highway Shield Shape - YELLOW
                        Image(systemName: "shield.fill")
                            .font(.system(size: 65))
                            .foregroundColor(.yellow)
                        
                        // Road Text inside - BLACK
                        VStack(spacing: -2) {
                            Text("ON")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(.black)
                            Text("THA")
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(.black)
                            Text("SET")
                                .font(.system(size: 15, weight: .black))
                                .foregroundColor(.black)
                        }
                        .offset(y: -2)
                    }
                }
                .padding(.top, 10)

                // Segmented Picker
                Picker("View", selection: $viewMode) {
                    Text("List").tag(ViewMode.list)
                    Text("Calendar").tag(ViewMode.calendar)
                }
                .pickerStyle(.segmented)
                // Styling the picker background to stay within theme
                .background(Color.yellow.opacity(0.8).cornerRadius(8))
                .padding()

                if viewMode == .list {
                    eventList
                } else {
                    calendarView
                }
            }
        }
        .navigationTitle("") // Shield acts as the title
        // 2. BACK BUTTON LOGIC: Hide the default blue back button
        .navigationBarBackButtonHidden(true)
        .toolbar {
            // 3. BACK BUTTON LOGIC: Add the yellow chevron on the left
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.yellow)
                }
            }
        }
    }
}

// MARK: - Sub-Views
extension EventHomeView {
    
    var eventList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if events.isEmpty {
                    ContentUnavailableView(
                        "No Events Posted",
                        systemImage: "signpost.right.and.left.fill",
                        description: Text("The road is empty. Be the first to post an event!")
                    )
                    .foregroundColor(.gray)
                    .padding(.top, 50)
                } else {
                    ForEach(events) { event in
                        NavigationLink(destination: EventDetailView(event: event)) {
                            EventLinkItem(event: event)
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.yellow.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
    }

    var calendarView: some View {
        VStack {
            DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date])
                .datePickerStyle(.graphical)
                .accentColor(.yellow)
                .colorScheme(.dark)
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(15)
                .padding()

            let filteredEvents = events.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
            
            ScrollView {
                ForEach(filteredEvents) { event in
                    NavigationLink(destination: EventDetailView(event: event)) {
                        EventLinkItem(event: event)
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }
            }
        }
    }
}
