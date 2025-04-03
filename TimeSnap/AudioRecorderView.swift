import SwiftUI
import AVFoundation

struct AudioRecorderView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (URL) -> Void
    
    @StateObject private var audioRecorder = AudioRecorder()
    @State private var isRecording = false
    @State private var showingPreview = false
    @State private var isPlaying = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                if showingPreview {
                    // Preview Section
                    VStack(spacing: 20) {
                        Text("Preview Recording")
                            .font(.headline)
                        
                        // Playback Controls
                        HStack(spacing: 40) {
                            Button(action: {
                                if isPlaying {
                                    audioRecorder.stopPlayback()
                                } else {
                                    audioRecorder.startPlayback()
                                }
                                isPlaying.toggle()
                            }) {
                                Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 64))
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        // Action Buttons
                        HStack(spacing: 20) {
                            Button(action: {
                                audioRecorder.deleteRecording()
                                showingPreview = false
                                isPlaying = false
                            }) {
                                Label("Discard", systemImage: "trash")
                                    .padding()
                                    .background(Color.red.opacity(0.1))
                                    .foregroundColor(.red)
                                    .cornerRadius(10)
                            }
                            
                            Button(action: {
                                if let url = audioRecorder.recordingURL {
                                    // Ensure the recording is stopped and saved
                                    audioRecorder.stopRecording()
                                    onSave(url)
                                    dismiss()
                                }
                            }) {
                                Label("Add to Time Capsule", systemImage: "checkmark")
                                    .padding()
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(10)
                            }
                        }
                    }
                } else {
                    // Recording Section
                    VStack(spacing: 20) {
                        Text(isRecording ? "Recording..." : "Ready to Record")
                            .font(.headline)
                        
                        Button(action: {
                            if isRecording {
                                audioRecorder.stopRecording()
                                isRecording = false
                                showingPreview = true
                            } else {
                                audioRecorder.startRecording()
                                isRecording = true
                            }
                        }) {
                            Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.system(size: 64))
                                .foregroundColor(isRecording ? .red : .blue)
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("Voice Recording")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if isRecording {
                            audioRecorder.stopRecording()
                        }
                        if isPlaying {
                            audioRecorder.stopPlayback()
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}

class AudioRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    var recordingURL: URL?
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    func startRecording() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("\(UUID().uuidString).m4a")
        recordingURL = audioFilename
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
        } catch {
            print("Could not start recording: \(error)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        // Ensure the recording is saved
        audioRecorder?.prepareToRecord()
    }
    
    func startPlayback() {
        guard let url = recordingURL else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
        } catch {
            print("Could not start playback: \(error)")
        }
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
    }
    
    func deleteRecording() {
        if let url = recordingURL {
            do {
                try FileManager.default.removeItem(at: url)
                recordingURL = nil
            } catch {
                print("Could not delete recording: \(error)")
            }
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // AVAudioRecorderDelegate
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("Recording failed")
        }
    }
    
    // AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Handle playback completion if needed
    }
}

struct WaveformView: View {
    let audioLevels: [Float]
    
    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(audioLevels.indices, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.blue)
                    .frame(width: 3, height: CGFloat(audioLevels[index]) * 100)
            }
        }
    }
} 