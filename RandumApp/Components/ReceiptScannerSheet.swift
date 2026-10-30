//
//  ReceiptScannerSheet.swift
//  RandumApp
//
//  Created by dannyduy on 28/10/26.
//

import SwiftUI
import Vision
import PhotosUI

struct ReceiptScannerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var onScanCompleted: (ParsedTransactionResult) -> Void
    
    @State private var isProcessing: Bool = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    
    var body: some View {
        ZStack {
            // 1. Apple Document Camera Native View
            DocumentCameraView(
                onScan: { scannedImages in
                    processImages(scannedImages)
                },
                onCancel: {
                    dismiss()
                }
            )
            .ignoresSafeArea()
            
            // 2. Bottom Controls Overlay: Photos Picker Button
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 25)
                    .padding(.bottom, 36)
                }
            }
            .allowsHitTesting(!isProcessing)
            
            // 3. Loading & Analyzing Overlay (Locks interaction)
            if isProcessing {
                ZStack {
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 14) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                        
                        Text("Analyzing receipt...")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 4)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isProcessing)
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        processImages([image])
                    }
                }
            }
        }
    }
    
    // MARK: - Vision OCR Processing (2D Spatial Extraction)
    private func processImages(_ images: [UIImage]) {
        guard !images.isEmpty else { return }
        isProcessing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            var allElements: [OCRTextElement] = []
            
            for (pageIndex, image) in images.enumerated() {
                let normalizedImg = image.fixedOrientation()
                guard let cgImage = normalizedImg.cgImage else { continue }
                
                let semaphore = DispatchSemaphore(value: 0)
                let request = VNRecognizeTextRequest { request, error in
                    defer { semaphore.signal() }
                    guard error == nil,
                          let observations = request.results as? [VNRecognizedTextObservation] else {
                        return
                    }
                    
                    for obs in observations {
                        if let candidate = obs.topCandidates(1).first {
                            var adjustedBox = obs.boundingBox
                            adjustedBox.origin.y -= CGFloat(pageIndex)
                             
                            allElements.append(
                                OCRTextElement(text: candidate.string, box: adjustedBox)
                            )
                        }
                    }
                }
                
                request.recognitionLevel = .accurate
                request.recognitionLanguages = ["vi-VN", "en-US"]
                request.usesLanguageCorrection = true
                
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try? handler.perform([request])
                semaphore.wait()
            }
            
            print("allElements", allElements)
            
            // Processing using a spatial clustering algorithm to group 2D lines
            let parsedResult = ReceiptOCRParser.parse(elements: allElements)
            
            DispatchQueue.main.async {
                self.isProcessing = false
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                self.onScanCompleted(parsedResult)
            }
        }
    }
}

