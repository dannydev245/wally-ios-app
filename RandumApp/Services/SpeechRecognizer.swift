//
//  SpeechRecognizer.swift
//  RandumApp
//
//  Created by dannyduy on 26/10/26.
//

import Foundation
import Speech
import AVFoundation
import Combine

@MainActor
final class SpeechRecognizer: ObservableObject {
    @Published var transcript: String = ""
    @Published var isRecording: Bool = false
    @Published var errorMessage: String?
    
    var onSilenceDetected: ((String) -> Void)?
    
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer?
    
    private var silenceTimerTask: Task<Void, Never>?
    private let silenceThreshold: TimeInterval = 1.8 // Stop after 1.8s silent
    
    func startRecording(locale: Locale) {
        speechRecognizer = SFSpeechRecognizer(locale: locale)
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "The voice recognition service is currently unavailable."
            return
        }
        
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            Task { @MainActor in
                guard let self = self else { return }
                switch authStatus {
                case .authorized:
                    self.beginAudioSession()
                case .denied, .restricted:
                    self.errorMessage = "Please grant microphone and speech recognition permissions in Settings."
                case .notDetermined:
                    self.errorMessage = "Voice access has not been granted."
                @unknown default:
                    break
                }
            }
        }
    }
    
    private func beginAudioSession() {
        stopRecording()
        
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            } catch {
                await MainActor.run {
                    self.errorMessage = "Unable to start audio session: \(error.localizedDescription)"
                }
                return
            }
            
            let engine = AVAudioEngine()
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            
            let inputNode = engine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                request.append(buffer)
            }
            
            engine.prepare()
            
            do {
                try engine.start()
            } catch {
                await MainActor.run {
                    self.errorMessage = "Unable to start recording: \(error.localizedDescription)"
                }
                return
            }
            
            await MainActor.run {
                self.audioEngine = engine
                self.recognitionRequest = request
                self.isRecording = true
                self.transcript = ""
                self.errorMessage = nil
                
                self.recognitionTask = self.speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
                    guard let self = self else { return }
                    
                    if let result = result {
                        let text = result.bestTranscription.formattedString
                        self.transcript = text
                        
                        // Restart the timer whenever a new word is detected
                        if !text.trimmingCharacters(in: .whitespaces).isEmpty {
                            self.resetSilenceTimer()
                        }
                    }
                    
                    if error != nil || (result?.isFinal ?? false) {
                        self.stopRecording()
                    }
                }
            }
        }
    }
    
    private func resetSilenceTimer() {
        silenceTimerTask?.cancel()
        silenceTimerTask = Task { [weak self] in
            guard let self = self else { return }
            do {
                try await Task.sleep(nanoseconds: UInt64(self.silenceThreshold * 1_000_000_000))
                
                if !Task.isCancelled && self.isRecording {
                    let finalText = self.transcript
                    self.stopRecording()
                    self.onSilenceDetected?(finalText)
                }
            } catch {
                // The task is canceled when the user continues by speaking the next word.
            }
        }
    }
    
    func stopRecording() {
        silenceTimerTask?.cancel()
        silenceTimerTask = nil
        
        if let engine = audioEngine, engine.isRunning {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }
        audioEngine = nil
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isRecording = false
        
        Task.detached(priority: .background) {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }
}
