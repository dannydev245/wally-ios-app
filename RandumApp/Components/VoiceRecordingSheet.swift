//
//  VoiceRecordingSheet.swift
//  RandumApp
//
//  Created by dannyduy on 26/10/26.
//

import SwiftUI

struct VoiceRecordingSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject private var speechRecognizer = SpeechRecognizer()
    
    var onParsedSuccessfully: (TransactionItem) -> Void
    
    @State private var parsingError: String? = nil
    
    private var isVietnamese: Bool {
        themeManager.currentLanguage.locale.identifier.hasPrefix("vi")
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text(speechRecognizer.isRecording ? "Listening..." : "Tap mic to speak")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)
                .padding(.top, 10)
            
            if speechRecognizer.transcript.isEmpty {
                Text("e.g., 'Coffee 35k' or 'Dinner 12 dollars'")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(AppColors.textSecondary.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .frame(minHeight: 54)
            } else {
                Text(speechRecognizer.transcript)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .frame(minHeight: 54)
            }
            
            if let error = parsingError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.top, 1)
                    Text(error)
                        .font(.system(size: 13, weight: .medium))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(.orange)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.orange.opacity(0.12))
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
            
            Spacer()
            
            ZStack {
                if speechRecognizer.isRecording {
                    PulsingWaveRing(color: themeManager.currentAccent.primaryColor)
                }
                
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    if speechRecognizer.isRecording {
                        speechRecognizer.stopRecording()
                        processTranscript(speechRecognizer.transcript)
                    } else {
                        startRecording()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(themeManager.currentAccent.primaryColor)
                            .frame(width: 68, height: 68)
                            .shadow(color: themeManager.currentAccent.primaryColor.opacity(0.4), radius: 8, x: 0, y: 4)
                        
                        Image(systemName: speechRecognizer.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .padding()
        .tint(themeManager.currentAccent.primaryColor)
        .onAppear {
            speechRecognizer.onSilenceDetected = { finalText in
                processTranscript(finalText)
            }
        }
        .onDisappear {
            speechRecognizer.stopRecording()
        }
    }
    
    private func startRecording() {
        withAnimation {
            parsingError = nil
        }
        speechRecognizer.startRecording(locale: themeManager.currentLanguage.locale)
    }
    
    private func processTranscript(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let result = VoiceTransactionParser.parse(text: text)
        
        if result.amount > 0 {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onParsedSuccessfully(result)
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                parsingError = isVietnamese
                ? "Không tìm thấy số tiền. Hãy thử lại (vd: 'Cà phê 35k')"
                : "Could not detect amount. Try again (e.g. 'Coffee 5 dollars')"
            }
        }
    }
}

#Preview {
    VoiceRecordingSheet(onParsedSuccessfully:{
        string in
        print("abc")
    })
}
