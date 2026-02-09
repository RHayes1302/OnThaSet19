//
//  ImageFileStore.swift
//  OnThaSet (New)
//
//  Created by Ramone Hayes on 2/5/26.
//

import Foundation
import UIKit

class ImageFileStore {
    
    private let folderName: String = "CameraDemoStorage"
    
    enum Kind {
        case before
        case after
    }
    
    // Initialize and create folder if needed
    init() {
        createFolderIfNeeded()
    }
    
    // Creates a image name from before or after
    func makeFileName(id: UUID, kind: Kind) -> String {
        if kind == .before {
            return id.uuidString + "_before.jpg"
        } else {
            return id.uuidString + "_after.jpg"
        }
    }
    
    // IMAGE TO DATA
    func saveIMG(_ image: UIImage, fileName: String) throws {
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw NSError(
                domain: "CameraDemoStorage",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Could not convert image into DATA"]
            )
        }
        
        let url = fileURL(fileName: fileName)
        try data.write(to: url, options: .atomic)
    }
    
    // DATA TO IMAGE
    func loadIMG(fileName: String) -> UIImage? {
        let url = fileURL(fileName: fileName)
        
        // The file exist?
        if FileManager.default.fileExists(atPath: url.path()) == false {
            return nil
        }
        
        // Any errors from damage information
        guard let data = try? Data(contentsOf: url) else { return nil }
        
        // Parsing data to IMAGE
        return UIImage(data: data)
    }
    
    func deleteIMG(fileName: String) {
        let url = fileURL(fileName: fileName)
        
        // The file exist?
        if FileManager.default.fileExists(atPath: url.path()) == false {
            return
        }
        
        try? FileManager.default.removeItem(at: url)
    }
    
    func createFolderIfNeeded() {
        let url = folderURL()
        
        if FileManager.default.fileExists(atPath: url.path()) {
            return
        }
        
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }
    
    // MARK: - URL Helpers
    
    // Create Folder URL
    func docURL() -> URL {
        // create a folder for this APP in user's phone
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func folderURL() -> URL {
        // on users Local Storage create a path to this folder
        docURL().appendingPathComponent(folderName)
        // Documents/CameraDemoStorage/
    }
    
    func fileURL(fileName: String) -> URL {
        // ✅ FIXED - Now saves to Documents/CameraDemoStorage/filename
        folderURL().appendingPathComponent(fileName)
    }
}
