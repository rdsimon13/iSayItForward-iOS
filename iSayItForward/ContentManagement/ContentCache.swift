import Foundation
import UIKit

/// Manages caching of content for offline access
actor ContentCache {
    static let shared = ContentCache()
    
    private let cacheDirectory: URL
    private let metadataFileName = "cache_metadata.json"
    private var cachedItems: [UUID: ContentItem] = [:]
    private let maxCacheSize: Int64 = 500_000_000 // 500MB
    
    private init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        cacheDirectory = documentsPath.appendingPathComponent("ContentCache")
        
        // Create cache directory if needed
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Load cached metadata
        loadCachedMetadata()
    }
    
    /// Caches a content item
    func cacheContent(_ contentItem: ContentItem) async {
        guard let localURL = contentItem.localURL else { return }
        
        let cachedURL = cacheDirectory.appendingPathComponent(contentItem.id.uuidString).appendingPathExtension(localURL.pathExtension)
        
        do {
            // Copy file to cache directory
            if FileManager.default.fileExists(atPath: cachedURL.path) {
                try FileManager.default.removeItem(at: cachedURL)
            }
            try FileManager.default.copyItem(at: localURL, to: cachedURL)
            
            // Update cached item with cache URL
            var cachedItem = contentItem
            cachedItem.localURL = cachedURL
            cachedItems[contentItem.id] = cachedItem
            
            // Save metadata
            saveCachedMetadata()
            
            // Clean up cache if needed
            await cleanupCacheIfNeeded()
            
        } catch {
            print("Failed to cache content: \(error)")
        }
    }
    
    /// Gets cached content URL if available
    func getCachedContentURL(for contentId: UUID) async -> URL? {
        guard let cachedItem = cachedItems[contentId],
              let localURL = cachedItem.localURL,
              FileManager.default.fileExists(atPath: localURL.path) else {
            return nil
        }
        
        // Update access time
        try? FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: localURL.path)
        
        return localURL
    }
    
    /// Gets cached content item if available
    func getCachedContent(for contentId: UUID) async -> ContentItem? {
        guard let cachedItem = cachedItems[contentId],
              let localURL = cachedItem.localURL,
              FileManager.default.fileExists(atPath: localURL.path) else {
            // Remove from cache if file doesn't exist
            cachedItems.removeValue(forKey: contentId)
            saveCachedMetadata()
            return nil
        }
        
        return cachedItem
    }
    
    /// Removes cached content
    func removeCachedContent(for contentId: UUID) async {
        guard let cachedItem = cachedItems[contentId],
              let localURL = cachedItem.localURL else {
            return
        }
        
        // Remove file
        try? FileManager.default.removeItem(at: localURL)
        
        // Remove from cache
        cachedItems.removeValue(forKey: contentId)
        saveCachedMetadata()
    }
    
    /// Gets all cached content items
    func getAllCachedContent() async -> [ContentItem] {
        return Array(cachedItems.values)
    }
    
    /// Clears all cached content
    func clearCache() async {
        // Remove all files
        for (_, contentItem) in cachedItems {
            if let localURL = contentItem.localURL {
                try? FileManager.default.removeItem(at: localURL)
            }
        }
        
        // Clear metadata
        cachedItems.removeAll()
        saveCachedMetadata()
    }
    
    /// Gets current cache size in bytes
    func getCacheSize() async -> Int64 {
        var totalSize: Int64 = 0
        
        for (_, contentItem) in cachedItems {
            if let localURL = contentItem.localURL {
                if let attributes = try? FileManager.default.attributesOfItem(atPath: localURL.path),
                   let fileSize = attributes[.size] as? Int64 {
                    totalSize += fileSize
                }
            }
        }
        
        return totalSize
    }
    
    /// Gets formatted cache size string
    func getFormattedCacheSize() async -> String {
        let size = await getCacheSize()
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    // MARK: - Private Methods
    
    private func loadCachedMetadata() {
        let metadataURL = cacheDirectory.appendingPathComponent(metadataFileName)
        
        guard let data = try? Data(contentsOf: metadataURL),
              let items = try? JSONDecoder().decode([UUID: ContentItem].self, from: data) else {
            return
        }
        
        cachedItems = items
        
        // Validate cached files still exist
        var itemsToRemove: [UUID] = []
        for (id, item) in cachedItems {
            if let localURL = item.localURL,
               !FileManager.default.fileExists(atPath: localURL.path) {
                itemsToRemove.append(id)
            }
        }
        
        // Remove missing items
        for id in itemsToRemove {
            cachedItems.removeValue(forKey: id)
        }
        
        if !itemsToRemove.isEmpty {
            saveCachedMetadata()
        }
    }
    
    private func saveCachedMetadata() {
        let metadataURL = cacheDirectory.appendingPathComponent(metadataFileName)
        
        do {
            let data = try JSONEncoder().encode(cachedItems)
            try data.write(to: metadataURL)
        } catch {
            print("Failed to save cache metadata: \(error)")
        }
    }
    
    private func cleanupCacheIfNeeded() async {
        let currentSize = await getCacheSize()
        
        if currentSize > maxCacheSize {
            await cleanupOldestFiles()
        }
    }
    
    private func cleanupOldestFiles() async {
        // Get files sorted by modification date (oldest first)
        var fileInfos: [(UUID, URL, Date)] = []
        
        for (id, item) in cachedItems {
            if let localURL = item.localURL,
               let attributes = try? FileManager.default.attributesOfItem(atPath: localURL.path),
               let modificationDate = attributes[.modificationDate] as? Date {
                fileInfos.append((id, localURL, modificationDate))
            }
        }
        
        fileInfos.sort { $0.2 < $1.2 }
        
        // Remove oldest files until we're under the limit
        var currentSize = await getCacheSize()
        let targetSize = maxCacheSize * 3 / 4 // Clean up to 75% of max size
        
        for (id, url, _) in fileInfos {
            if currentSize <= targetSize {
                break
            }
            
            if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
               let fileSize = attributes[.size] as? Int64 {
                currentSize -= fileSize
            }
            
            await removeCachedContent(for: id)
        }
    }
}