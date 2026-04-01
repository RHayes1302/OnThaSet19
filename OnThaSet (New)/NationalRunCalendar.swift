//
//  NationalRunCalendar.swift
//  OnThaSet (New)
//

import SwiftUI
import WebKit

// MARK: - National Run Calendar View

struct NationalRunCalendarView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var manager = SupabaseManager.shared

    @State private var selectedCategory: EventCategory? = nil
    @State private var selectedEvent: SupabaseEvent? = nil
    @State private var showingEventDetail = false
    @State private var viewMode: ViewMode = .map
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var selectedStateName: String? = nil
    @State private var webViewRef: WKWebView? = nil

    enum ViewMode { case map, list }

    var nationalEvents: [SupabaseEvent] {
        manager.events.filter { event in
            guard let cat = EventCategory(rawValue: event.category) else { return false }
            guard cat.isNationalEvent else { return false }
            guard event.latitude != 0 && event.longitude != 0 else { return false }
            if let filter = selectedCategory { return cat == filter }
            return true
        }
    }

    var filteredByMonth: [SupabaseEvent] {
        nationalEvents.filter { event in
            let components = Calendar.current.dateComponents([.month, .year], from: event.date)
            return components.month == selectedMonth && components.year == selectedYear
        }
    }

    var eventsInSelectedState: [SupabaseEvent] {
        guard let state = selectedStateName else { return [] }
        return filteredByMonth.filter { event in
            let parts = event.locationName.split(separator: "|").map { String($0) }
            let eventState = parts.count >= 4 ? parts[3] : ""
            return eventState.lowercased() == state.lowercased() ||
                   stateAbbreviation(for: state).lowercased() == eventState.lowercased()
        }
    }

    var nationalCategories: [EventCategory] {
        EventCategory.allCases.filter { $0.isNationalEvent }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {

                // HEADER
                HStack {
                    Button(action: {
                        if selectedStateName != nil {
                            selectedStateName = nil
                            resetMapToUSA()
                        } else {
                            dismiss()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .bold))
                            if let state = selectedStateName {
                                Text(state).font(.caption.bold())
                            }
                        }
                        .foregroundColor(.yellow)
                    }
                    Spacer()
                    ZStack {
                        Image(systemName: "shield.fill").font(.system(size: 45)).foregroundColor(.yellow)
                        VStack(spacing: -1) {
                            Text("ON").font(.system(size: 7, weight: .black))
                            Text("THA").font(.system(size: 6, weight: .black))
                            Text("SET").font(.system(size: 9, weight: .black))
                        }.foregroundColor(.black).offset(y: -2)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Button(action: { viewMode = .map }) {
                            Image(systemName: "map.fill")
                                .foregroundColor(viewMode == .map ? .black : .yellow)
                                .padding(8)
                                .background(viewMode == .map ? Color.yellow : Color.white.opacity(0.1))
                                .cornerRadius(8)
                        }
                        Button(action: { viewMode = .list }) {
                            Image(systemName: "list.bullet")
                                .foregroundColor(viewMode == .list ? .black : .yellow)
                                .padding(8)
                                .background(viewMode == .list ? Color.yellow : Color.white.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal, 20).padding(.vertical, 10)

                // TITLE
                VStack(spacing: 4) {
                    Text("🗺️ NATIONAL RUN CALENDAR")
                        .font(.headline.bold()).foregroundColor(.yellow)
                    if let state = selectedStateName {
                        Text("\(state) Events")
                            .font(.caption.bold()).foregroundColor(.orange)
                    } else {
                        Text("Coast to Coast • All Clubs Welcome")
                            .font(.caption).foregroundColor(.gray)
                    }
                }
                .padding(.bottom, 8)

                // CATEGORY FILTER
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Button(action: { selectedCategory = nil }) {
                            Text("ALL")
                                .font(.caption.bold())
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(selectedCategory == nil ? Color.yellow : Color.white.opacity(0.1))
                                .foregroundColor(selectedCategory == nil ? .black : .white)
                                .cornerRadius(15)
                        }
                        ForEach(nationalCategories, id: \.self) { cat in
                            Button(action: {
                                selectedCategory = selectedCategory == cat ? nil : cat
                            }) {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(pinSwiftColor(for: cat))
                                        .frame(width: 8, height: 8)
                                    Text(cat.displayName).font(.caption.bold())
                                }
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(selectedCategory == cat ? Color.yellow : Color.white.opacity(0.1))
                                .foregroundColor(selectedCategory == cat ? .black : .white)
                                .cornerRadius(15)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)

                // MONTH SELECTOR
                HStack(spacing: 15) {
                    Button(action: { previousMonth() }) {
                        Image(systemName: "chevron.left").foregroundColor(.yellow).font(.caption.bold())
                    }
                    Text(monthYearString)
                        .font(.caption.bold()).foregroundColor(.white)
                        .frame(width: 120, alignment: .center)
                    Button(action: { nextMonth() }) {
                        Image(systemName: "chevron.right").foregroundColor(.yellow).font(.caption.bold())
                    }
                    Spacer()
                    if selectedStateName != nil {
                        Button(action: {
                            selectedStateName = nil
                            resetMapToUSA()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.counterclockwise").font(.caption2)
                                Text("ALL STATES").font(.caption2.bold())
                            }
                            .foregroundColor(.yellow)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(6)
                        }
                    }
                    Text("\(filteredByMonth.count) event\(filteredByMonth.count == 1 ? "" : "s")")
                        .font(.caption2).foregroundColor(.gray)
                }
                .padding(.horizontal, 20).padding(.bottom, 8)

                // CONTENT
                if manager.isLoading {
                    Spacer()
                    ProgressView().tint(.yellow)
                    Text("Loading national events...")
                        .font(.caption).foregroundColor(.gray).padding(.top, 8)
                    Spacer()
                } else if viewMode == .map {
                    VStack(spacing: 0) {
                        USMapWebView(
                            events: filteredByMonth,
                            onStateTapped: { stateName in
                                selectedStateName = stateName
                            },
                            onEventTapped: { eventID in
                                if let event = filteredByMonth.first(where: {
                                    $0.id?.uuidString == eventID
                                }) {
                                    selectedEvent = event
                                    showingEventDetail = true
                                }
                            },
                            webViewRef: $webViewRef
                        )
                        .frame(height: selectedStateName != nil ? 280 : 380)

                        if let state = selectedStateName {
                            if eventsInSelectedState.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "mappin.slash")
                                        .font(.system(size: 30))
                                        .foregroundColor(.yellow.opacity(0.4))
                                    Text("No events in \(state) this month")
                                        .font(.subheadline).foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity).padding(.top, 30)
                            } else {
                                ScrollView {
                                    LazyVStack(spacing: 10) {
                                        Text("\(eventsInSelectedState.count) event\(eventsInSelectedState.count == 1 ? "" : "s") in \(state)")
                                            .font(.caption.bold()).foregroundColor(.yellow)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.horizontal)
                                        ForEach(eventsInSelectedState.sorted { $0.date < $1.date }) { event in
                                            Button(action: {
                                                selectedEvent = event
                                                showingEventDetail = true
                                            }) {
                                                NationalEventRow(event: event)
                                            }
                                            .buttonStyle(.plain)
                                            .padding(.horizontal)
                                        }
                                    }
                                    .padding(.vertical, 10)
                                }
                            }
                        }
                    }
                } else {
                    listView
                }
            }
        }
        .navigationBarHidden(true)
        .task { await manager.fetchAllEvents() }
        .sheet(isPresented: $showingEventDetail) {
            if let event = selectedEvent {
                NationalEventDetailSheet(event: event)
            }
        }
        .onChange(of: filteredByMonth) { _, newEvents in
            updateMapPins(events: newEvents)
        }
    }

    // MARK: - List View

    var listView: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                if filteredByMonth.isEmpty {
                    VStack(spacing: 15) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 40)).foregroundColor(.yellow.opacity(0.3))
                        Text("No national events this month")
                            .font(.headline).foregroundColor(.white)
                        Text("Try a different month or category")
                            .font(.subheadline).foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity).padding(.top, 60)
                } else {
                    ForEach(filteredByMonth.sorted { $0.date < $1.date }) { event in
                        Button(action: {
                            selectedEvent = event
                            showingEventDetail = true
                        }) {
                            NationalEventRow(event: event)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .refreshable { await manager.fetchAllEvents() }
    }

    // MARK: - Helpers

    func resetMapToUSA() {
        webViewRef?.evaluateJavaScript("resetToUSA();", completionHandler: nil)
    }

    func updateMapPins(events: [SupabaseEvent]) {
        let pinsJSON = eventsToJSON(events)
        webViewRef?.evaluateJavaScript("updatePins(\(pinsJSON));", completionHandler: nil)
    }

    func eventsToJSON(_ events: [SupabaseEvent]) -> String {
        let pins = events.compactMap { event -> String? in
            guard let id = event.id else { return nil }
            let cat = EventCategory(rawValue: event.category)
            let color = pinHexColor(for: cat)
            let icon = cat?.icon ?? "📍"
            let title = event.title.replacingOccurrences(of: "'", with: "\\'")
            return """
            {id:'\(id.uuidString)',lat:\(event.latitude),lng:\(event.longitude),color:'\(color)',icon:'\(icon)',title:'\(title)'}
            """
        }
        return "[\(pins.joined(separator: ","))]"
    }

    func pinHexColor(for category: EventCategory?) -> String {
        switch category {
        case .rally:    return "#FF3B30"
        case .charity:  return "#007AFF"
        case .mcAnnual: return "#FFD60A"
        case .scAnnual: return "#FF69B4"
        case .rcAnnual: return "#34C759"
        case .unityRun: return "#AF52DE"
        default:        return "#8E8E93"
        }
    }

    func pinSwiftColor(for category: EventCategory) -> Color {
        switch category {
        case .rally:    return .red
        case .charity:  return .blue
        case .mcAnnual: return .yellow
        case .scAnnual: return Color(red: 1.0, green: 0.4, blue: 0.7)
        case .rcAnnual: return .green
        case .unityRun: return .purple
        default:        return .gray
        }
    }

    func stateAbbreviation(for fullName: String) -> String {
        let map: [String: String] = [
            "Alabama": "AL", "Alaska": "AK", "Arizona": "AZ", "Arkansas": "AR",
            "California": "CA", "Colorado": "CO", "Connecticut": "CT", "Delaware": "DE",
            "Florida": "FL", "Georgia": "GA", "Hawaii": "HI", "Idaho": "ID",
            "Illinois": "IL", "Indiana": "IN", "Iowa": "IA", "Kansas": "KS",
            "Kentucky": "KY", "Louisiana": "LA", "Maine": "ME", "Maryland": "MD",
            "Massachusetts": "MA", "Michigan": "MI", "Minnesota": "MN", "Mississippi": "MS",
            "Missouri": "MO", "Montana": "MT", "Nebraska": "NE", "Nevada": "NV",
            "New Hampshire": "NH", "New Jersey": "NJ", "New Mexico": "NM", "New York": "NY",
            "North Carolina": "NC", "North Dakota": "ND", "Ohio": "OH", "Oklahoma": "OK",
            "Oregon": "OR", "Pennsylvania": "PA", "Rhode Island": "RI", "South Carolina": "SC",
            "South Dakota": "SD", "Tennessee": "TN", "Texas": "TX", "Utah": "UT",
            "Vermont": "VT", "Virginia": "VA", "Washington": "WA", "West Virginia": "WV",
            "Wisconsin": "WI", "Wyoming": "WY", "Puerto Rico": "PR",
            "Washington DC": "DC", "District of Columbia": "DC"
        ]
        return map[fullName] ?? fullName
    }

    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        var components = DateComponents()
        components.month = selectedMonth
        components.year = selectedYear
        components.day = 1
        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date)
    }

    func previousMonth() {
        if selectedMonth == 1 { selectedMonth = 12; selectedYear -= 1 }
        else { selectedMonth -= 1 }
    }

    func nextMonth() {
        if selectedMonth == 12 { selectedMonth = 1; selectedYear += 1 }
        else { selectedMonth += 1 }
    }
}

// MARK: - US Map WebView

struct USMapWebView: UIViewRepresentable {
    let events: [SupabaseEvent]
    let onStateTapped: (String) -> Void
    let onEventTapped: (String) -> Void
    @Binding var webViewRef: WKWebView?

    func makeCoordinator() -> Coordinator {
        Coordinator(onStateTapped: onStateTapped, onEventTapped: onEventTapped)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        userContentController.add(WeakScriptMessageHandler(delegate: context.coordinator), name: "stateTapped")
        userContentController.add(WeakScriptMessageHandler(delegate: context.coordinator), name: "eventTapped")
        config.userContentController = userContentController

        if #available(iOS 14.0, *) {
            let pagePrefs = WKWebpagePreferences()
            pagePrefs.allowsContentJavaScript = true
            config.defaultWebpagePreferences = pagePrefs
        }

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        webView.isOpaque = false
        webView.scrollView.isScrollEnabled = false

        DispatchQueue.main.async { webViewRef = webView }
        webView.loadHTMLString(buildHTML(), baseURL: URL(string: "https://unpkg.com"))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "stateTapped")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "eventTapped")
    }

    func buildHTML() -> String {
        let alaskaFlag = "iVBORw0KGgoAAAANSUhEUgAAAOEAAACWCAMAAAAfSh8xAAAAolBMVEUPIEv/thITIkkfKkcvNEP8tBL4shMWJElKRT31sBQ4OUGFai5DQD52YTKeeSgrMkQzN0KjfSflphfxrRUcKEgZJkgnL0XXnRvqqBdWTDpfUjhkVTeLbS3PmB3doRoiLEZQSTuSciyOcCyZdimsgiWyhiS3iSPDkSDGkh/Llh3hoxntqxZ+ZjDAjyDJlB48PT9vXDRsWjSogCe8jCJdUDdqWDV/xPxdAAAB9klEQVR42u3bSW7bABQDUFKyRkuyLXme7Xh25rT3v1qRoMg2m7aoGb4Fz8BP4MPMzMzMzMzMzP6Sfh/iyhLiTkdoS+I4gbQJOYGosPVuT+5b70LISV5jfsoOAwiaNPytmUDT6o0fjkOoCjKSzBLISvkhhayK3O/ICrKa+BmYxhlUrS9dAOgs1xCVJviQpL6xzMzMzMzMzMxEJVBXQd21gLB+GE5YhWEIVetlRJLNFrKSHslxDmEFyTsoe81+jsZQdhgi6BUQFnzGN/QCdcsc2obcQli6GF0YL0YbyHqqSUZtCOvIV4EyeowvUPZYojPKIawLIOh6AjGzfyiHuHQHcb0xhA3a988N2+U8h6r0SvUanizIOIeymhFbEJY3PzrLOwibdoCgdCkwM/uDnqDuoQVtQdyGsLSa9zi+38wDqGpHJLnsQlcekacAwlLGHEHZ4RxOr0MIewHQXbsVmNn/YABxgwriZmMIC1Zh+MAiDPtQNW9IMhrlkNUdk9wGEHYg2cJtWs3wtSA7zrINbtP9G7423QDDHm7TOQugq7+vL2Rdn7pQFVQkeQohbEFmUDaI63NUQFj5MMC8B2Gdz/imCogbPkJcGfUhrH3XrrnbVilUrc6U/9HokSygbMEsmkJYeJ0luyOEFS0AMy/FZmZmZmZmZmYm5heSzRfZ+dK68wAAAABJRU5ErkJggg=="

        let pinsArray = events.compactMap { event -> String? in
            guard let id = event.id else { return nil }
            let cat = EventCategory(rawValue: event.category)
            let color = pinHexColor(for: cat)
            let icon = cat?.icon ?? "📍"
            let title = event.title.replacingOccurrences(of: "'", with: "\\'")
            let parts = event.locationName.split(separator: "|").map { String($0) }
            let state = parts.count >= 4 ? parts[3] : ""
            return """
            {id:'\(id.uuidString)',lat:\(event.latitude),lng:\(event.longitude),
             color:'\(color)',icon:'\(icon)',title:'\(title)',state:'\(state)'}
            """
        }.joined(separator: ",")

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
        <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"/>
        <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
        <style>
          * { margin:0; padding:0; box-sizing:border-box; }
          html, body { width:100%; height:100%; background:#1a1a1a; }
          #map { width:100%; height:calc(100% - 56px); background:#1a1a1a; }
          .leaflet-container { background:#1a1a1a !important; }
          .leaflet-control-zoom { display:none; }
          .leaflet-control-attribution { display:none; }
          .pin-label {
            background: rgba(0,0,0,0.85);
            border: 1px solid rgba(255,255,255,0.2);
            border-radius: 6px;
            padding: 2px 5px;
            font-size: 11px;
            font-weight: bold;
            color: white;
            white-space: nowrap;
            pointer-events: none;
          }
          .state-label {
            background: transparent;
            border: none;
            color: rgba(0,0,0,0.35);
            font-size: 8px;
            font-weight: 900;
            text-align: center;
            white-space: nowrap;
            pointer-events: none;
            text-shadow: 0 0 3px rgba(255,215,0,0.2);
            letter-spacing: 0.5px;
          }
          #territory-bar {
            position: absolute;
            bottom: 0;
            left: 0;
            right: 0;
            height: 56px;
            background: rgba(10,10,10,0.97);
            border-top: 1px solid rgba(255,214,10,0.3);
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 14px;
            z-index: 1000;
          }
          .territory-btn {
            display: flex;
            flex-direction: row;
            align-items: center;
            gap: 8px;
            background: rgba(255,214,10,0.06);
            border: 1px solid rgba(255,214,10,0.25);
            border-radius: 10px;
            padding: 6px 14px;
            cursor: pointer;
            min-width: 90px;
          }
          .territory-btn:active {
            background: rgba(255,214,10,0.22);
            border-color: #FFD60A;
          }
          .territory-flag {
            width: 32px;
            height: 20px;
            border-radius: 2px;
            border: 0.5px solid rgba(255,255,255,0.2);
          }
          .territory-flag-emoji {
            font-size: 20px;
            line-height: 1;
          }
          .territory-name {
            font-size: 9px;
            font-weight: 900;
            color: #FFD60A;
            letter-spacing: 1px;
          }
        </style>
        </head>
        <body>
        <div id="map"></div>
        <div id="territory-bar">
          <button class="territory-btn" onclick="selectTerritory('Hawaii')">
            <svg class="territory-flag" viewBox="0 0 120 63" xmlns="http://www.w3.org/2000/svg">
              <rect width="120" height="63" fill="#fff"/>
              <rect y="0" width="120" height="7" fill="#E4002B"/>
              <rect y="7" width="120" height="7" fill="#fff"/>
              <rect y="14" width="120" height="7" fill="#E4002B"/>
              <rect y="21" width="120" height="7" fill="#fff"/>
              <rect y="28" width="120" height="7" fill="#E4002B"/>
              <rect y="35" width="120" height="7" fill="#fff"/>
              <rect y="42" width="120" height="7" fill="#E4002B"/>
              <rect y="49" width="120" height="7" fill="#fff"/>
              <rect y="56" width="120" height="7" fill="#E4002B"/>
              <rect width="48" height="35" fill="#012169"/>
              <line x1="0" y1="0" x2="48" y2="35" stroke="#fff" stroke-width="5"/>
              <line x1="48" y1="0" x2="0" y2="35" stroke="#fff" stroke-width="5"/>
              <line x1="0" y1="0" x2="48" y2="35" stroke="#E4002B" stroke-width="3"/>
              <line x1="48" y1="0" x2="0" y2="35" stroke="#E4002B" stroke-width="3"/>
              <rect x="21" y="0" width="6" height="35" fill="#fff"/>
              <rect x="0" y="14.5" width="48" height="6" fill="#fff"/>
              <rect x="22.5" y="0" width="3" height="35" fill="#E4002B"/>
              <rect x="0" y="16" width="48" height="3" fill="#E4002B"/>
            </svg>
            <span class="territory-name">HAWAII</span>
          </button>
          <button class="territory-btn" onclick="selectTerritory('Alaska')">
            <img class="territory-flag"
              src="data:image/png;base64,\(alaskaFlag)"
              alt="Alaska"/>
            <span class="territory-name">ALASKA</span>
          </button>
          <button class="territory-btn" onclick="selectTerritory('Puerto Rico')">
            <span class="territory-flag-emoji">🇵🇷</span>
            <span class="territory-name">PUERTO RICO</span>
          </button>
        </div>
        <script>
          var tileURL = 'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}{r}.png';
          var tileOpts = { maxZoom: 19 };
          var stateStyle = {
            fillColor: '#FFD60A',
            fillOpacity: 0.65,
            color: '#000',
            weight: 1.2,
            opacity: 0.9
          };
          var selectedStyle = {
            fillColor: '#FF9500',
            fillOpacity: 0.88,
            color: '#000',
            weight: 1.5,
            opacity: 1
          };

          var map = L.map('map', {
            zoomControl: false,
            attributionControl: false,
            dragging: true,
            touchZoom: true,
            doubleClickZoom: false,
            scrollWheelZoom: false,
            minZoom: 3,
            maxZoom: 10
          }).setView([38.0, -96.0], 3);

          L.tileLayer(tileURL, tileOpts).addTo(map);

          var markers = [];
          var stateLayer = null;
          var selectedLayer = null;
          var stateLabels = [];

          var stateData = [
            {name:'AL',lat:32.8,lng:-86.8},{name:'AZ',lat:34.3,lng:-111.1},
            {name:'AR',lat:34.8,lng:-92.2},{name:'CA',lat:36.8,lng:-119.4},
            {name:'CO',lat:39.0,lng:-105.5},{name:'CT',lat:41.6,lng:-72.7},
            {name:'DE',lat:39.0,lng:-75.5},{name:'FL',lat:27.8,lng:-81.7},
            {name:'GA',lat:32.2,lng:-83.4},{name:'ID',lat:44.4,lng:-114.6},
            {name:'IL',lat:40.0,lng:-89.2},{name:'IN',lat:40.3,lng:-86.1},
            {name:'IA',lat:42.0,lng:-93.2},{name:'KS',lat:38.5,lng:-98.4},
            {name:'KY',lat:37.7,lng:-85.3},{name:'LA',lat:31.2,lng:-91.8},
            {name:'ME',lat:45.4,lng:-69.0},{name:'MD',lat:39.0,lng:-76.8},
            {name:'MA',lat:42.3,lng:-71.8},{name:'MI',lat:44.3,lng:-85.4},
            {name:'MN',lat:46.4,lng:-93.1},{name:'MS',lat:32.7,lng:-89.7},
            {name:'MO',lat:38.5,lng:-92.5},{name:'MT',lat:47.0,lng:-110.0},
            {name:'NE',lat:41.5,lng:-99.9},{name:'NV',lat:38.5,lng:-117.1},
            {name:'NH',lat:44.0,lng:-71.6},{name:'NJ',lat:40.1,lng:-74.5},
            {name:'NM',lat:34.5,lng:-106.1},{name:'NY',lat:42.9,lng:-75.5},
            {name:'NC',lat:35.6,lng:-79.4},{name:'ND',lat:47.5,lng:-100.4},
            {name:'OH',lat:40.4,lng:-82.8},{name:'OK',lat:35.6,lng:-97.5},
            {name:'OR',lat:44.1,lng:-120.5},{name:'PA',lat:40.9,lng:-77.8},
            {name:'RI',lat:41.7,lng:-71.5},{name:'SC',lat:33.9,lng:-80.9},
            {name:'SD',lat:44.4,lng:-100.2},{name:'TN',lat:35.9,lng:-86.4},
            {name:'TX',lat:31.5,lng:-99.3},{name:'UT',lat:39.3,lng:-111.1},
            {name:'VT',lat:44.1,lng:-72.7},{name:'VA',lat:37.8,lng:-78.2},
            {name:'WA',lat:47.4,lng:-120.5},{name:'WV',lat:38.6,lng:-80.6},
            {name:'WI',lat:44.3,lng:-89.6},{name:'WY',lat:43.0,lng:-107.6},
            {name:'DC',lat:38.9,lng:-77.0}
          ];

          function addStateLabels() {
            stateLabels.forEach(l => map.removeLayer(l));
            stateLabels = [];
            stateData.forEach(function(s) {
              var icon = L.divIcon({
                html: '<div class="state-label">' + s.name + '</div>',
                className: '',
                iconSize: [28, 14],
                iconAnchor: [14, 7]
              });
              var lbl = L.marker([s.lat, s.lng], {
                icon: icon,
                interactive: false,
                zIndexOffset: -1000
              }).addTo(map);
              stateLabels.push(lbl);
            });
          }

          function onStateTap(name) {
            window.webkit.messageHandlers.stateTapped.postMessage(name);
          }

          function onEachState(feature, layer) {
            layer.on('click', function() {
              var name = feature.properties.name;
              if (selectedLayer) selectedLayer.setStyle(stateStyle);
              layer.setStyle(selectedStyle);
              selectedLayer = layer;
              map.fitBounds(layer.getBounds(), { padding:[30,30], maxZoom:7 });
              onStateTap(name);
            });
            layer.on('mouseover', function() {
              if (layer !== selectedLayer) layer.setStyle({ fillOpacity:0.85 });
            });
            layer.on('mouseout', function() {
              if (layer !== selectedLayer) layer.setStyle({ fillOpacity:0.65 });
            });
          }

          fetch('https://raw.githubusercontent.com/PublicaMundi/MappingAPI/master/data/geojson/us-states.json')
            .then(r => r.json())
            .then(data => {
              stateLayer = L.geoJSON(data, {
                style: stateStyle,
                filter: f => f.properties.name !== 'Hawaii' && f.properties.name !== 'Alaska',
                onEachFeature: onEachState
              }).addTo(map);
              addStateLabels();
              addPins([\(pinsArray)]);
            })
            .catch(err => console.log('GeoJSON error:', err));

          function selectTerritory(name) {
            onStateTap(name);
            var coords = {
              'Hawaii':      { lat:20.5,  lng:-157.0, zoom:6 },
              'Alaska':      { lat:64.0,  lng:-153.0, zoom:4 },
              'Puerto Rico': { lat:18.2,  lng:-66.5,  zoom:8 }
            };
            if (coords[name]) {
              map.setView([coords[name].lat, coords[name].lng], coords[name].zoom);
            }
          }

          function addPins(pins) {
            markers.forEach(m => map.removeLayer(m));
            markers = [];
            pins.forEach(function(pin) {
              var dot = '<div style="width:14px;height:14px;border-radius:50%;background:' + pin.color + ';box-shadow:0 0 6px ' + pin.color + ';border:2px solid rgba(0,0,0,0.4);cursor:pointer;"></div>';
              var icon = L.divIcon({
                html: dot,
                className: '',
                iconSize: [14, 14],
                iconAnchor: [7, 7]
              });
              var marker = L.marker([pin.lat, pin.lng], { icon: icon });
              marker.on('click', function() {
                window.webkit.messageHandlers.eventTapped.postMessage(pin.id);
              });
              marker.bindTooltip(pin.title, {
                permanent: false,
                direction: 'top',
                className: 'pin-label',
                offset: [0, -8]
              });
              marker.addTo(map);
              markers.push(marker);
            });
          }

          function updatePins(pins) { addPins(pins); }

          function resetToUSA() {
            map.setView([38.0, -96.0], 3);
            if (selectedLayer) { selectedLayer.setStyle(stateStyle); selectedLayer = null; }
          }
        </script>
        </body>
        </html>
        """
    }

    func pinHexColor(for category: EventCategory?) -> String {
        switch category {
        case .rally:    return "#FF3B30"
        case .charity:  return "#007AFF"
        case .mcAnnual: return "#FFD60A"
        case .scAnnual: return "#FF69B4"
        case .rcAnnual: return "#34C759"
        case .unityRun: return "#AF52DE"
        default:        return "#8E8E93"
        }
    }

    class Coordinator: NSObject, WKScriptMessageHandler {
        let onStateTapped: (String) -> Void
        let onEventTapped: (String) -> Void

        init(onStateTapped: @escaping (String) -> Void,
             onEventTapped: @escaping (String) -> Void) {
            self.onStateTapped = onStateTapped
            self.onEventTapped = onEventTapped
        }

        func userContentController(_ userContentController: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            if message.name == "stateTapped",
               let state = message.body as? String {
                DispatchQueue.main.async { self.onStateTapped(state) }
            }
            if message.name == "eventTapped",
               let eventID = message.body as? String {
                DispatchQueue.main.async { self.onEventTapped(eventID) }
            }
        }
    }
}

// MARK: - Weak Script Message Handler

class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?

    init(delegate: WKScriptMessageHandler) {
        self.delegate = delegate
    }

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        delegate?.userContentController(userContentController, didReceive: message)
    }
}

// MARK: - National Event Row

struct NationalEventRow: View {
    let event: SupabaseEvent

    var category: EventCategory? { EventCategory(rawValue: event.category) }

    var stateFromLocation: String {
        let parts = event.locationName.split(separator: "|").map { String($0) }
        return parts.count >= 4 ? parts[3] : ""
    }

    var cityFromLocation: String {
        let parts = event.locationName.split(separator: "|").map { String($0) }
        return parts.count >= 3 ? parts[2] : event.locationName
    }

    var body: some View {
        HStack(spacing: 14) {

            VStack(spacing: 2) {
                Text(event.date.formatted(.dateTime.month(.abbreviated)))
                    .font(.system(size: 10, weight: .bold)).foregroundColor(.gray)
                Text(event.date.formatted(.dateTime.day()))
                    .font(.system(size: 22, weight: .black)).foregroundColor(.yellow)
                Text(event.date.formatted(.dateTime.year()))
                    .font(.system(size: 9)).foregroundColor(.gray)
            }
            .frame(width: 45).padding(.vertical, 8)
            .background(Color.white.opacity(0.05)).cornerRadius(10)

            VStack(alignment: .leading, spacing: 5) {
                if let cat = category {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(pinColor(for: cat))
                            .frame(width: 10, height: 10)
                            .shadow(color: pinColor(for: cat).opacity(0.6), radius: 3)
                        Text(cat.displayName)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gray)
                    }
                }
                Text(event.title)
                    .font(.headline.bold()).foregroundColor(.white).lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill").font(.caption).foregroundColor(.yellow)
                    Text("\(cityFromLocation)\(stateFromLocation.isEmpty ? "" : ", \(stateFromLocation)")")
                        .font(.caption).foregroundColor(.gray)
                }
                Text(event.date.formatted(.dateTime.hour().minute()))
                    .font(.caption2).foregroundColor(.gray)
            }

            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundColor(.gray)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    category.map { pinColor(for: $0) }?.opacity(0.3) ?? Color.clear,
                    lineWidth: 1
                )
        )
    }

    func pinColor(for category: EventCategory) -> Color {
        switch category {
        case .rally:    return .red
        case .charity:  return .blue
        case .mcAnnual: return .yellow
        case .scAnnual: return Color(red: 1.0, green: 0.4, blue: 0.7)
        case .rcAnnual: return .green
        case .unityRun: return .purple
        default:        return .gray
        }
    }
}

// MARK: - National Event Detail Sheet

struct NationalEventDetailSheet: View {
    let event: SupabaseEvent
    @Environment(\.dismiss) var dismiss
    @State private var showingNavigationOptions = false
    @State private var showingShare = false
    @State private var showingWeather = false

    var category: EventCategory? { EventCategory(rawValue: event.category) }

    var venueName: String {
        let parts = event.locationName.split(separator: "|").map { String($0) }
        return parts.first ?? event.title
    }

    var cityName: String {
        let parts = event.locationName.split(separator: "|").map { String($0) }
        return parts.count >= 3 ? parts[2] : event.locationName
    }

    var stateAbbr: String {
        let parts = event.locationName.split(separator: "|").map { String($0) }
        return parts.count >= 4 ? parts[3] : ""
    }

    func pinColor(for category: EventCategory) -> Color {
        switch category {
        case .rally:    return .red
        case .charity:  return .blue
        case .mcAnnual: return .yellow
        case .scAnnual: return Color(red: 1.0, green: 0.4, blue: 0.7)
        case .rcAnnual: return .green
        case .unityRun: return .purple
        default:        return .gray
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {

                        // FLYER
                        if let urlString = event.imageURL,
                           !urlString.isEmpty,
                           let url = URL(string: urlString) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().scaledToFit()
                                        .frame(maxWidth: .infinity).frame(height: 220)
                                        .cornerRadius(15)
                                        .shadow(color: .yellow.opacity(0.3), radius: 10)
                                case .empty:
                                    ProgressView().tint(.yellow).frame(height: 150)
                                default:
                                    EmptyView()
                                }
                            }
                            .padding(.horizontal)
                        }

                        // CATEGORY + TITLE
                        VStack(spacing: 10) {
                            if let cat = category {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(pinColor(for: cat))
                                        .frame(width: 14, height: 14)
                                        .shadow(color: pinColor(for: cat).opacity(0.6), radius: 4)
                                    Text(cat.displayName)
                                        .font(.subheadline.bold()).foregroundColor(.white)
                                }
                            }
                            Text(event.title)
                                .font(.title2.bold()).foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal)

                        // DETAILS CARD
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "calendar").foregroundColor(.yellow)
                                Text(event.date.formatted(date: .long, time: .shortened))
                                    .foregroundColor(.white)
                            }
                            HStack(alignment: .top) {
                                Image(systemName: "mappin.circle.fill").foregroundColor(.yellow)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(venueName).font(.headline).foregroundColor(.white)
                                    Text("\(cityName)\(stateAbbr.isEmpty ? "" : ", \(stateAbbr)")")
                                        .font(.subheadline).foregroundColor(.gray)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12).padding(.horizontal)

                        if !event.details.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("DETAILS").font(.caption.bold()).foregroundColor(.yellow)
                                Text(event.details).foregroundColor(.white)
                            }
                            .padding(.horizontal)
                        }

                        // ACTION BUTTONS
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                Button(action: { showingWeather = true }) {
                                    HStack {
                                        Image(systemName: "cloud.sun.fill")
                                            .symbolRenderingMode(.multicolor)
                                        Text("WEATHER").fontWeight(.bold)
                                    }
                                    .frame(maxWidth: .infinity).padding()
                                    .background(Color.blue.opacity(0.2)).foregroundColor(.white)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue.opacity(0.4), lineWidth: 1))
                                }
                                Button(action: { showingNavigationOptions = true }) {
                                    HStack {
                                        Image(systemName: "location.fill").foregroundColor(.yellow)
                                        Text("DIRECTIONS").fontWeight(.bold)
                                    }
                                    .frame(maxWidth: .infinity).padding()
                                    .background(Color.white.opacity(0.1)).foregroundColor(.white)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.yellow, lineWidth: 1))
                                }
                            }
                            Button(action: { showingShare = true }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("SHARE EVENT").fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity).padding()
                                .background(Color.yellow).foregroundColor(.black).cornerRadius(12)
                            }
                        }
                        .padding(.horizontal).padding(.bottom, 30)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark").foregroundColor(.yellow).font(.title3.bold())
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("National Run Calendar").font(.caption.bold()).foregroundColor(.yellow)
                }
            }
        }
        .confirmationDialog(
            "Choose Navigation App",
            isPresented: $showingNavigationOptions,
            titleVisibility: .visible
        ) {
            Button("Apple Maps") { openAppleMaps() }
            Button("Google Maps") { openGoogleMaps() }
            Button("Waze") { openWaze() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Get directions to this event")
        }
        .sheet(isPresented: $showingWeather) {
            if event.latitude != 0 && event.longitude != 0 {
                WeatherViewForCoordinates(
                    latitude: event.latitude,
                    longitude: event.longitude,
                    locationName: venueName
                )
            } else {
                WeatherViewForEvent(cityName: cityName)
            }
        }
        .sheet(isPresented: $showingShare) {
            SupabaseEventShareView(
                title: event.title,
                date: event.date,
                locationName: event.locationName,
                details: event.details,
                category: event.category,
                imageURL: event.imageURL
            )
        }
    }

    func openAppleMaps() {
        let url = URL(string: "maps://?daddr=\(event.latitude),\(event.longitude)&dirflg=d")
        if let url = url, UIApplication.shared.canOpenURL(url) { UIApplication.shared.open(url) }
    }

    func openGoogleMaps() {
        let googleURL = "comgooglemaps://?daddr=\(event.latitude),\(event.longitude)&directionsmode=driving"
        let webURL = "https://www.google.com/maps/dir/?api=1&destination=\(event.latitude),\(event.longitude)"
        if let url = URL(string: googleURL), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let url = URL(string: webURL) {
            UIApplication.shared.open(url)
        }
    }

    func openWaze() {
        if let url = URL(string: "https://waze.com/ul?ll=\(event.latitude),\(event.longitude)&navigate=yes") {
            UIApplication.shared.open(url)
        }
    }
}
