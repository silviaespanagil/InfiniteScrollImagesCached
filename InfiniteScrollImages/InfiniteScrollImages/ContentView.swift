//
//  ContentView.swift
//  InfiniteScrollImages
//
//  Created by sespana on 14/11/24.
//

import SwiftUI

// MARK: - Data Models
// Update models to match your service

struct ArtworkResponse: Codable {
    
    let data: [Artwork]
    let pagination: Pagination
}

struct Artwork: Codable, Identifiable {
    
    let id: Int
    let title: String
    let image_id: String?
    
    var imageUrl: String? {
        guard let imageId = image_id else { return nil }
        return "https://www.artic.edu/iiif/2/\(imageId)/full/843,/0/default.jpg"
    }
}

struct Pagination: Codable {
    
    let total: Int
    let limit: Int
    let offset: Int
    let total_pages: Int
    let current_page: Int
}

// MARK: - Cache Management
// Custom cache implementation using NSCache to store and manage images in memory
// Automatically handles memory by removing old images when limits are reached

final class ImageCache {
    
    static let shared = ImageCache()
    private var itemCount = 0
    private var totalCostInBytes = 0
    
    // Init the cache only when needed
    private let cache: NSCache<NSString, UIImage> = {
        
        let cache = NSCache<NSString, UIImage>()
        
        // Set limit of cache 100MB or 100 images
        cache.totalCostLimit = 1024 * 1024 * 100
        cache.countLimit = 100
        
        print("📱 Cache initiated - Limit: \(cache.countLimit) images or \(cache.countLimit)")
        return cache
    }()
    
    private init() {}
    
    //Save image in cache
    func set(_ image: UIImage, forKey key: String) {
        
        let cost = Int(image.size.width * image.size.height * 4)
        
        cache.setObject(image, forKey: key as NSString, cost: cost)
        
        itemCount += 1
        totalCostInBytes += cost
        
        print("💾 Image added - Size: \(cost/1024)KB - Total images number: \(itemCount)")
        
        if itemCount >= cache.countLimit || totalCostInBytes >= cache.totalCostLimit {
            print("⚠️ ¡Cache limit reached! Old images will get erased")
        }
    }
    
    //Get image in cache
    func get(forKey key: String) -> UIImage? {
        
        let image = cache.object(forKey: key as NSString)
        
        print(image != nil ? "✅ Image found" : "❌ Image not found")
        
        return image
    }
    
    //Clear cache: This is only called when view dissappear
    func clear() {
        
        print("🧹 Cleaning cache")
        itemCount = 0
        
        cache.removeAllObjects()
    }
}

// MARK: - Image Loading View
// Custom view that handles image loading with cache support
// Shows view by states, placeholder for errors, and cached/downloaded images

struct CachedAsyncImage: View {
    
    let url: String
    
    @State private var image: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        
        Group {
            
            if let image = image {
                
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if isLoading {
                
                ProgressView()
            } else {
                
                Image(systemName: "photo")
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            
            loadImage()
        }
    }
    
    private func loadImage() {
        
        if let cachedImage = ImageCache.shared.get(forKey: url) {
            
            self.image = cachedImage
            return
        }
        
        guard let imageUrl = URL(string: url) else { return }
        isLoading = true
        
        URLSession.shared.dataTask(with: imageUrl) { data, response, error in
            
            isLoading = false
            guard let data = data,
                  let loadedImage = UIImage(data: data) else { return }
            
            ImageCache.shared.set(loadedImage, forKey: url)
            
            DispatchQueue.main.async {
                
                self.image = loadedImage
            }
        }.resume()
    }
}

// MARK: - Gallery View Model
// Manages the artwork data and pagination
// Loads initial batch of 10 images and adds 10 more when user reaches threshold

class ArtGalleryViewModel: ObservableObject {
    
    @Published var artworks: [Artwork] = []
    @Published var isLoading = false
    
    private var currentOffset = 0
    private var canLoadMore = true
    
    private let initialLoadCount = 10    // Number of images to load initially
    private let batchSize = 10          // Number of images to load in each subsequent batch
    private let preloadThreshold = 4    // Load more images when user is 4 images away from the end
    
    func loadInitialBatch() {
        
        guard artworks.isEmpty else { return }
        fetchArtworks(count: initialLoadCount)
    }
    
    func loadMoreIfNeeded() {
        
        guard !isLoading && canLoadMore else { return }
        fetchArtworks(count: batchSize)
    }
    
    private func fetchArtworks(count: Int) {
        
        guard !isLoading else { return }
        isLoading = true
        
        guard let url = URL(string: "https://api.artic.edu/api/v1/artworks?page=\(currentOffset/count + 1)&limit=\(count)&fields=id,title,image_id") else {
            
            isLoading = false
            return
        }
        
        print("Loading \(count) images")
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                
                defer { self.isLoading = false }
                
                if let error = error {
                    
                    print("Error cargando datos: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else { return }
                
                do {
                    
                    let response = try JSONDecoder().decode(ArtworkResponse.self, from: data)
                    let newArtworks = response.data.filter { $0.image_id != nil }
                    
                    self.artworks.append(contentsOf: newArtworks)
                    self.currentOffset += newArtworks.count
                    self.canLoadMore = !newArtworks.isEmpty
                    
                    print("Loaded \(newArtworks.count) new images. Total: \(self.artworks.count)")
                } catch {
                    print("Error decoding response: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
}

// MARK: - Main Gallery View
// Displays artwork in a scrollable grid with infinite scroll capability
// Handles loading states and triggers new data loading when needed

struct ArtGalleryView: View {
    
    @StateObject private var viewModel = ArtGalleryViewModel()
    
    var body: some View {
        
        ScrollView {
            
            LazyVStack(spacing: 16) {
                
                ForEach(Array(viewModel.artworks.enumerated()), id: \.element.id) { index, artwork in
                    
                    VStack(spacing: 8) {
                        
                        if let imageUrl = artwork.imageUrl {
                            
                            CachedAsyncImage(url: imageUrl)
                                .frame(height: 200)
                                .clipped()
                        }
                        
                        Text(artwork.title)
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Divider()
                    }
                    .onAppear {
                        
                        if index == viewModel.artworks.count - 4 {
                            
                            viewModel.loadMoreIfNeeded()
                        }
                    }
                }
                
                if viewModel.isLoading {
                    
                    ProgressView()
                        .padding()
                }
            }
        }
        .onAppear {
            
            viewModel.loadInitialBatch()
        }
        .onDisappear {
            
            ImageCache.shared.clear()
        }
    }
}

#Preview {
    ArtGalleryView()
}
