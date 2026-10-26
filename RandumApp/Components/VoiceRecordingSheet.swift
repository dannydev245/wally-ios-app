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
    
    // Callback khi người dùng nói xong và muốn phân tích
    var onFinishedSpeaking: (String) -> Void
    
    @State private var isPulsing: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Gợi ý câu nói mẫu
            Text(speechRecognizer.isRecording ? "Listening..." : "Tap mic to speak")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)
                .padding(.top, 10)
            
            // Khung hiển thị câu nói của user (Live Transcript)
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
                    Circle()
                        .stroke(themeManager.currentAccent.primaryColor.opacity(0.25), lineWidth: 4)
                        .frame(width: 86, height: 86)
                        .scaleEffect(isPulsing ? 1.3 : 1.0)
                        .opacity(isPulsing ? 0 : 1)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: false), value: isPulsing)
                }
                
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    if speechRecognizer.isRecording {
                        speechRecognizer.stopRecording()
                        isPulsing = false
                        if !speechRecognizer.transcript.isEmpty {
                            onFinishedSpeaking(speechRecognizer.transcript)
                        }
                    } else {
                        speechRecognizer.startRecording(locale: themeManager.currentLanguage.locale)
                        isPulsing = true
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
