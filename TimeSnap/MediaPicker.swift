import SwiftUI
import PhotosUI
import AVFoundation

struct PhotoPickerButton: View {
    @Binding var selectedPhotos: [PhotosPickerItem]
    
    var body: some View {
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
    }
}

struct VideoPickerButton: View {
    @Binding var selectedVideos: [PhotosPickerItem]
    
    var body: some View {
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
    }
}

struct VoiceButton: View {
    @Binding var showingAudioRecorder: Bool
    
    var body: some View {
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
    }
}

struct MediaPicker: View {
    @Binding var mediaItems: [MediaItem]
    
    var body: some View {
        if !mediaItems.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Added Items (\(mediaItems.count))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(mediaItems) { item in
                            MediaItemView(item: item)
                                .frame(width: 100, height: 100)
                                .overlay(alignment: .topTrailing) {
                                    Button(action: { removeMediaItem(item) }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.white)
                                            .background(Color.black.opacity(0.5))
                                            .clipShape(Circle())
                                    }
                                    .padding(4)
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top)
        }
    }
    
    private func removeMediaItem(_ item: MediaItem) {
        // Delete the file
        try? FileManager.default.removeItem(at: item.url)
        // Remove from the array
        mediaItems.removeAll { $0.id == item.id }
    }
}

struct MediaItemView: View {
    let item: MediaItem
    
    var body: some View {
        Group {
            switch item.type {
            case .photo:
                if let image = UIImage(contentsOfFile: item.url.path) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            case .video:
                VideoThumbnailView(url: item.url)
            case .message:
                Image(systemName: "waveform")
                    .font(.system(size: 30))
                    .foregroundColor(.blue)
            }
        }
        .frame(width: 100, height: 100)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct VideoThumbnailView: View {
    let url: URL
    @State private var thumbnail: UIImage?
    
    var body: some View {
        Group {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "play.circle")
                    .font(.system(size: 30))
                    .foregroundColor(.blue)
            }
        }
        .onAppear {
            generateThumbnail()
        }
    }
    
    private func generateThumbnail() {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
            thumbnail = UIImage(cgImage: cgImage)
        } catch {
            print("Error generating thumbnail: \(error)")
        }
    }
} 
