//
//  VideoFileManager.swift
//  Reflect Room
//
//  Created by Andrew Lawrence on 10/30/25.
//

import Foundation

struct VideoFileManager {
    static let shared = VideoFileManager()

    /// Save a recorded video to the app’s Documents folder.
    /// Returns the filename (not full path) for Core Data storage.
    func saveVideoToDocuments(videoURL: URL) -> String? {
        let fileManager = FileManager.default
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let filename = UUID().uuidString + ".mov"
        let destinationURL = documents.appendingPathComponent(filename)

        do {
            try fileManager.copyItem(at: videoURL, to: destinationURL)
            print("✅ Video saved at: \(destinationURL.path)")
            return filename  // ✅ only return filename, not full absolute path
        } catch {
            print("❌ Error saving video: \(error.localizedDescription)")
            return nil
        }
    }

    /// Delete a saved video by filename
    static func deleteVideo(at path: String) {
        let documents = documentsDirectory()
        let fileURL = documents.appendingPathComponent(path)

        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(at: fileURL)
                print("🗑️ Deleted video at \(fileURL.lastPathComponent)")
            } catch {
                print("❌ Failed to delete video: \(error.localizedDescription)")
            }
        } else {
            print("⚠️ No video found at \(fileURL.lastPathComponent)")
        }
    }

    /// Retrieve the app's Documents directory URL
    static func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    /// List all saved `.mov` files
    static func listAllSavedVideos() -> [URL] {
        let documents = documentsDirectory()
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documents, includingPropertiesForKeys: nil)
            return fileURLs.filter { $0.pathExtension == "mov" }
        } catch {
            print("❌ Error reading documents directory: \(error.localizedDescription)")
            return []
        }
    }
}
