//
//  PostedByProfileView.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 2/8/26.
//

import SwiftUI

struct PostedByProfileView: View {
    let userID: String
    let posterName: String

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {

                Spacer()

                Image(systemName: "person.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.yellow)

                Text(posterName.isEmpty ? "Community Member" : posterName)
                    .font(.title.bold())
                    .foregroundColor(.white)

                Text("Rider ID: \(userID.prefix(8))...")
                    .font(.caption)
                    .foregroundColor(.gray)

                Spacer()

                Text("Full rider profiles are coming soon.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
            }
        }
        .navigationTitle("Posted By")
        .navigationBarTitleDisplayMode(.inline)
    }
}
