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
    
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer?
    
    func startRecording(locale: Locale) {
        // Khởi tạo nhận diện theo locale của app
        speechRecognizer = SFSpeechRecognizer(locale: locale)
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "The voice recognition service is currently unavailable."
            return
        }
        
        // Yêu cầu cấp quyền
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
        
        // Đẩy việc kích hoạt Audio Session và khởi chạy Engine sang Background Thread
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
                // Không dùng 'await' vì setActive là synchronous API
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
            
            // Cập nhật state và gán task trên Main Thread
            await MainActor.run {
                self.audioEngine = engine
                self.recognitionRequest = request
                self.isRecording = true
                self.transcript = ""
                self.errorMessage = nil
                
                self.recognitionTask = self.speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
                    guard let self = self else { return }
                    
                    if let result = result {
                        self.transcript = result.bestTranscription.formattedString
                    }
                    
                    if error != nil || (result?.isFinal ?? false) {
                        self.stopRecording()
                    }
                }
            }
        }
    }

    func stopRecording() {
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
        
        // Deactivate audio session ở background thread
        Task.detached(priority: .background) {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }
}
