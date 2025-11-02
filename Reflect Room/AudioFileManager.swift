//
//  AudioFileManager.swift
//  Reflect Room
//
//  Created by Andrew Lawrence on 11/01/25.
//

import Foundation

struct AudioFileManager {
    static let shared = AudioFileManager()

    /// Save a recorded audio file (from a temp URL) into the app’s Documents folder as `.m4a`.
    /// Returns the filename (not the full path) on success.
    func saveAudioToDocuments(audioURL: URL) -> String? {
        let fileManager = FileManager.default
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let filename = UUID().uuidString + ".m4a"
        let destinationURL = documents.appendingPathComponent(filename)

        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: audioURL, to: destinationURL)
            print("✅ Audio saved at: \(destinationURL.path)")
            return filename
        } catch {
            print("❌ Error saving audio: \(error.localizedDescription)")
            return nil
        }
    }

    /// Delete a saved audio by filename (in Documents)
    static func deleteAudio(at path: String) {
        let documents = documentsDirectory()
        let fileURL = documents.appendingPathComponent(path)

        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(at: fileURL)
                print("🗑️ Deleted audio at \(fileURL.lastPathComponent)")
            } catch {
                print("❌ Failed to delete audio: \(error.localizedDescription)")
            }
        } else {
            print("⚠️ No audio found at \(fileURL.lastPathComponent)")
        }
    }

    /// Retrieve the app's Documents directory URL
    static func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    /// List all saved `.m4a` files
    static func listAllSavedAudios() -> [URL] {
        let documents = documentsDirectory()
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documents, includingPropertiesForKeys: nil)
            return fileURLs.filter { $0.pathExtension.lowercased() == "m4a" }
        } catch {
            print("❌ Error reading documents directory: \(error.localizedDescription)")
            return []
        }
    }
}
