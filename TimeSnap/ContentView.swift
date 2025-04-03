//
//  ContentView.swift
//  TimeSnap
//
//  Created by Ethan Blanche on 4/3/25.
//

import SwiftUI
import _PhotosUI_SwiftUI
import AVKit

struct ContentView: View {
    @StateObject private var viewModel = TimeCapsuleViewModel()
    @State private var showingNewCapsuleSheet = false
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.timeCapsules) { capsule in
                        TimeCapsuleCard(capsule: capsule, viewModel: viewModel)
                    }
                }
                .padding()
            }
            .navigationTitle("Time Capsules")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNewCapsuleSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewCapsuleSheet) {
                NewTimeCapsuleView(viewModel: viewModel)
            }
        }
    }
}

struct ShareButton: View {
    let isShared: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: isShared ? "person.2.fill" : "person.badge.plus")
                .font(.system(size: 24))
                .foregroundColor(.white)
                .padding(8)
                .background(isShared ? Color.green : Color.blue)
                .clipShape(Circle())
        }
        .offset(x: -30, y: -30)
    }
}

struct TimeCapsuleCard: View {
    let capsule: TimeCapsule
    @State private var showingDetail = false
    @State private var showingShareSheet = false
    @ObservedObject var viewModel: TimeCapsuleViewModel
    
    var body: some View {
        Button(action: {
            if capsule.unlockDate <= Date() {
                showingDetail = true
            }
        }) {
            VStack(spacing: 0) {
                // Time Capsule Image
                ZStack {
                    // Background gradient
                    LinearGradient(
                        gradient: Gradient(colors: [
                            capsule.color,
                            capsule.color.opacity(0.8)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    // Time capsule shape
                    Image(systemName: "capsule.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                        .shadow(radius: 5)
                    
                    // Lock overlay if locked
                    if capsule.unlockDate > Date() {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .offset(x: 30, y: -30)
                    }
                    
                    // Share button
                    ShareButton(isShared: capsule.isShared) {
                        showingShareSheet = true
                    }
                }
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    Text(capsule.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if capsule.unlockDate > Date() {
                        Text("Unlocks: \(capsule.unlockDate.formatted(date: .abbreviated, time: capsule.includeTime ? .shortened : .omitted))")
                            .font(.caption)
                            .foregroundColor(.blue)
                    } else {
                        Text(capsule.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                        
                        if !capsule.mediaItems.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.caption)
                                Text("\(capsule.mediaItems.count)")
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .shadow(radius: 5)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            TimeCapsuleDetailView(capsule: capsule)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareTimeCapsuleView(capsule: capsule, viewModel: viewModel)
        }
    }
}

class AudioPlayerManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    private var audioPlayer: AVAudioPlayer?
    
    func play(url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("Could not play audio: \(error)")
        }
    }
    
    func stop() {
        audioPlayer?.stop()
        isPlaying = false
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
    }
}

struct MediaItemDetailView: View {
    let item: MediaItem
    @Environment(\.dismiss) private var dismiss
    @StateObject private var audioManager = AudioPlayerManager()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                switch item.type {
                case .photo:
                    if let image = UIImage(contentsOfFile: item.url.path) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    
                case .video:
                    VideoPlayer(url: item.url)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                case .message:
                    VStack(spacing: 20) {
                        Image(systemName: "waveform")
                            .font(.system(size: 64))
                            .foregroundColor(.white)
                        
                        Button(action: {
                            if audioManager.isPlaying {
                                audioManager.stop()
                            } else {
                                audioManager.play(url: item.url)
                            }
                        }) {
                            Image(systemName: audioManager.isPlaying ? "stop.circle.fill" : "play.circle.fill")
                                .font(.system(size: 64))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        if audioManager.isPlaying {
                            audioManager.stop()
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TimeCapsuleDetailView: View {
    let capsule: TimeCapsule
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMediaItem: MediaItem?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title and Description
                    VStack(alignment: .leading, spacing: 12) {
                        Text(capsule.title)
                            .font(.title)
                            .bold()
                        
                        Text(capsule.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Media Items
                    if !capsule.mediaItems.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Media")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(capsule.mediaItems) { item in
                                        Button(action: {
                                            selectedMediaItem = item
                                        }) {
                                            MediaItemView(item: item)
                                                .frame(width: 120, height: 120)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Unlock Date
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Unlocked on")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(capsule.unlockDate.formatted(date: .long, time: capsule.includeTime ? .shortened : .omitted))
                            .font(.headline)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedMediaItem) { item in
                MediaItemDetailView(item: item)
            }
        }
    }
}

struct VideoPlayer: View {
    let url: URL
    @State private var player: AVPlayer?
    
    var body: some View {
        AVKit.VideoPlayer(player: player)
            .onAppear {
                player = AVPlayer(url: url)
                player?.play()
            }
            .onDisappear {
                player?.pause()
                player = nil
            }
    }
}

struct NewTimeCapsuleView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TimeCapsuleViewModel
    
    @State private var title = ""
    @State private var description = ""
    @State private var unlockDate = Date().addingTimeInterval(5 * 365 * 24 * 60 * 60) // 5 years from now
    @State private var includeTime = false
    @State private var mediaItems: [MediaItem] = []
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var selectedVideos: [PhotosPickerItem] = []
    @State private var showingAudioRecorder = false
    @State private var selectedColor = Color(red: 0.8, green: 0.6, blue: 0.4)
    
    let colors: [Color] = [
        Color(red: 0.8, green: 0.6, blue: 0.4), // Bronze
        Color(red: 0.7, green: 0.7, blue: 0.7), // Silver
        Color(red: 0.9, green: 0.8, blue: 0.5), // Gold
        Color(red: 0.6, green: 0.8, blue: 0.7), // Mint
        Color(red: 0.7, green: 0.6, blue: 0.8), // Purple
        Color(red: 0.8, green: 0.7, blue: 0.6), // Rose
        Color(red: 0.6, green: 0.7, blue: 0.8), // Blue
        Color(red: 0.8, green: 0.8, blue: 0.6)  // Yellow
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Time Capsule Details Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Time Capsule Details")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            TextField("Title", text: $title)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.horizontal)
                            
                            TextField("Description", text: $description, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...6)
                                .padding(.horizontal)
                            
                            Toggle("Include Time", isOn: $includeTime)
                                .padding(.horizontal)
                            
                            if includeTime {
                                DatePicker("Date and Time",
                                         selection: $unlockDate,
                                         in: Date()...,
                                         displayedComponents: [.date, .hourAndMinute])
                                    .padding(.horizontal)
                            } else {
                                DatePicker("Date",
                                         selection: $unlockDate,
                                         in: Date()...,
                                         displayedComponents: .date)
                                    .padding(.horizontal)
                            }
                            
                            // Color Selection
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Choose Color")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(colors, id: \.self) { color in
                                            Button(action: {
                                                selectedColor = color
                                            }) {
                                                Circle()
                                                    .fill(color)
                                                    .frame(width: 40, height: 40)
                                                    .overlay(
                                                        Circle()
                                                            .stroke(Color.primary, lineWidth: selectedColor == color ? 2 : 0)
                                                    )
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .padding(.vertical)
                    
                    // Media section - completely separate from Form
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Media")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        // Photo Button
                        PhotosPicker(selection: $selectedPhotos,
                                   maxSelectionCount: 1,
                                   matching: .images) {
                            HStack {
                                Image(systemName: "photo")
                                    .font(.system(size: 20))
                                Text("Add Photo")
                                    .font(.body)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        
                        // Video Button
                        PhotosPicker(selection: $selectedVideos,
                                   maxSelectionCount: 1,
                                   matching: .videos) {
                            HStack {
                                Image(systemName: "video")
                                    .font(.system(size: 20))
                                Text("Add Video")
                                    .font(.body)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .foregroundColor(.green)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        
                        // Voice Button
                        Button(action: { showingAudioRecorder = true }) {
                            HStack {
                                Image(systemName: "mic")
                                    .font(.system(size: 20))
                                Text("Add Voice")
                                    .font(.body)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .foregroundColor(.purple)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        
                        // Added Media Preview Section
                        if !mediaItems.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Added Media")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(mediaItems) { item in
                                            ZStack(alignment: .topTrailing) {
                                                MediaItemView(item: item)
                                                    .frame(width: 100, height: 100)
                                                
                                                Button(action: {
                                                    deleteMediaItem(item)
                                                }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.red)
                                                        .background(Color.white)
                                                        .clipShape(Circle())
                                                }
                                                .offset(x: 5, y: -5)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.top)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("New Time Capsule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create Time Capsule") {
                        let newCapsule = TimeCapsule(
                            title: title,
                            description: description,
                            unlockDate: unlockDate,
                            includeTime: includeTime,
                            mediaItems: mediaItems,
                            color: selectedColor,
                            sharedWith: [],
                            isShared: false
                        )
                        viewModel.addTimeCapsule(newCapsule)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .onChange(of: selectedPhotos) { items in
                guard let item = items.first else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        let fileName = "\(UUID().uuidString).\(item.supportedContentTypes.first?.preferredFilenameExtension ?? "jpg")"
                        if let url = saveMedia(data: data, fileName: fileName) {
                            let mediaItem = MediaItem(type: .photo, url: url)
                            mediaItems.append(mediaItem)
                        }
                    }
                }
                selectedPhotos.removeAll()
            }
            .onChange(of: selectedVideos) { items in
                guard let item = items.first else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        let fileName = "\(UUID().uuidString).\(item.supportedContentTypes.first?.preferredFilenameExtension ?? "mov")"
                        if let url = saveMedia(data: data, fileName: fileName) {
                            let mediaItem = MediaItem(type: .video, url: url)
                            mediaItems.append(mediaItem)
                        }
                    }
                }
                selectedVideos.removeAll()
            }
            .sheet(isPresented: $showingAudioRecorder) {
                AudioRecorderView { url in
                    let mediaItem = MediaItem(type: .message, url: url)
                    mediaItems.append(mediaItem)
                }
            }
        }
    }
    
    private func saveMedia(data: Data, fileName: String) -> URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Error saving media: \(error)")
            return nil
        }
    }
    
    private func deleteMediaItem(_ item: MediaItem) {
        // Remove the item from the array
        if let index = mediaItems.firstIndex(where: { $0.id == item.id }) {
            mediaItems.remove(at: index)
            
            // Delete the file from the filesystem
            do {
                try FileManager.default.removeItem(at: item.url)
            } catch {
                print("Error deleting media file: \(error)")
            }
        }
    }
}

struct ShareTimeCapsuleView: View {
    let capsule: TimeCapsule
    @ObservedObject var viewModel: TimeCapsuleViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var emailAddress = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if capsule.sharedWith.count > 0 {
                    // Show current shares
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Shared with:")
                            .font(.headline)
                        
                        ForEach(capsule.sharedWith, id: \.self) { email in
                            HStack {
                                Text(email)
                                Spacer()
                                Button(action: {
                                    viewModel.removeShare(capsule: capsule, email: email)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                // Add new share
                VStack(alignment: .leading, spacing: 8) {
                    Text("Share with:")
                        .font(.headline)
                    
                    HStack {
                        TextField("Email address", text: $emailAddress)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
                        Button(action: shareCapsule) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .disabled(emailAddress.isEmpty)
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Share Time Capsule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Share Time Capsule", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func shareCapsule() {
        guard !emailAddress.isEmpty else { return }
        
        // Basic email validation
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        
        if emailPredicate.evaluate(with: emailAddress) {
            viewModel.shareCapsule(capsule: capsule, with: emailAddress)
            emailAddress = ""
            alertMessage = "Time capsule shared successfully!"
        } else {
            alertMessage = "Please enter a valid email address."
        }
        showingAlert = true
    }
}

#Preview {
    ContentView()
}
