//
//  VoiceRecordingSheet.swift
//  RandumApp
//
//  Created by dannyduy on 26/10/26.
//

import SwiftUI

struct VoiceRecordingSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    @StateObject private var speechRecognizer = SpeechRecognizer()
    
    var onFinishedSpeaking: (String) -> Void
        
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
            
            Spacer()
            
            // Nút Micro chính giữa kèm hiệu ứng sóng âm (Pulsing)
            ZStack {
                if speechRecognizer.isRecording {
                    PulsingWaveRing(color: themeManager.currentAccent.primaryColor)
                }
                
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    if speechRecognizer.isRecording {
                        speechRecognizer.stopRecording()
                        if !speechRecognizer.transcript.trimmingCharacters(in: .whitespaces).isEmpty {
                            onFinishedSpeaking(speechRecognizer.transcript)
                        }
                    } else {
                        speechRecognizer.startRecording(locale: themeManager.currentLanguage.locale)
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
        .onDisappear {
            speechRecognizer.stopRecording()
        }
        .tint(themeManager.currentAccent.primaryColor)
    }
}

#Preview {
    VoiceRecordingSheet(onFinishedSpeaking:{
        string in
        print("abc")
    })
}
