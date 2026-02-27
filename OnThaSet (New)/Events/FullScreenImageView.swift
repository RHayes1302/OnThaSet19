////
////  FullScreenImageView.swift
////  OnThaSet (New)
////
////  Created by Ramone Hayes on 1/29/26.
////
//
//import SwiftUI
//
//struct FullScreenImageView: View {
//    @Environment(\.dismiss) private var dismiss
//    let image: UIImage
//    
//    @State private var scale: CGFloat = 1.0
//    @State private var lastScale: CGFloat = 1.0
//    @State private var offset: CGSize = .zero
//    @State private var lastOffset: CGSize = .zero
//    
//    var body: some View {
//        ZStack {
//            Color.black.ignoresSafeArea()
//            
//            Image(uiImage: image)
//                .resizable()
//                .scaledToFit()
//                .scaleEffect(scale)
//                .offset(offset)
//                .gesture(
//                    MagnificationGesture()
//                        .onChanged { value in
//                            scale = lastScale * value
//                        }
//                        .onEnded { _ in
//                            lastScale = scale
//                            // Limit zoom
//                            if scale < 1 {
//                                withAnimation {
//                                    scale = 1
//                                    lastScale = 1
//                                }
//                            } else if scale > 4 {
//                                withAnimation {
//                                    scale = 4
//                                    lastScale = 4
//                                }
//                            }
//                        }
//                )
//                .gesture(
//                    DragGesture()
//                        .onChanged { value in
//                            offset = CGSize(
//                                width: lastOffset.width + value.translation.width,
//                                height: lastOffset.height + value.translation.height
//                            )
//                        }
//                        .onEnded { _ in
//                            lastOffset = offset
//                        }
//                )
//            
//            // Close button
//            VStack {
//                HStack {
//                    Spacer()
//                    Button(action: { dismiss() }) {
//                        Image(systemName: "xmark.circle.fill")
//                            .font(.system(size: 30))
//                            .foregroundColor(.white)
//                            .shadow(color: .black.opacity(0.5), radius: 5)
//                    }
//                    .padding()
//                }
//                Spacer()
//            }
//            
//            // Reset zoom button (only shown when zoomed)
//            if scale != 1 || offset != .zero {
//                VStack {
//                    Spacer()
//                    Button(action: {
//                        withAnimation {
//                            scale = 1
//                            lastScale = 1
//                            offset = .zero
//                            lastOffset = .zero
//                        }
//                    }) {
//                        Label("Reset", systemImage: "arrow.counterclockwise")
//                            .padding()
//                            .background(.ultraThinMaterial)
//                            .cornerRadius(20)
//                    }
//                    .padding(.bottom, 40)
//                }
//            }
//        }
//        .statusBar(hidden: true)
//    }
//}
