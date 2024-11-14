# Infinite Scroll Image Gallery

A SwiftUI implementation of an infinite scroll gallery that loads and caches images efficiently. This example uses the Art Institute of Chicago API, but can be easily adapted to work with any other API.

## Features

- Infinite scroll with pagination
- Image caching system that can be easily adapted. For the example code is 100MB or 100 images limit
- Loading states and placeholders
- Automatic cache cleanup using native `NSCache`
- Memory-efficient lazy loading

## How It Works

The app consists of four main components:

1. **Image Cache System**: Manages image storage in memory
2. **CachedAsyncImage**: Custom view for loading and displaying images
3. **Gallery ViewModel**: Handles data fetching and pagination
4. **Gallery View**: Displays the images in a scrollable list

How It Works
------------

The app consists of four main components:

1.  **Image Cache System**: Manages image storage in memory
    
2.  **CachedAsyncImage**: Custom view for loading and displaying images
    
3.  **Gallery ViewModel**: Handles data fetching and pagination
    
4.  **Gallery View**: Displays the images in a scrollable list
    

Customization Guide
-------------------

### 1\. Data Models

You'll need to replace the current models with your API response structure. Your models should conform to Codable and include:

*   A response structure for your API
    
*   An image model with a unique identifier and image URL
    

### 2\. Cache Configuration

The cache system can be configured by adjusting the limits in `ImageCache.swift`. Default values are:

*   Memory limit: 100MB
    
*   Image count limit: 100 images
    
*   Cache type: NSCache (memory only)
    

### 3\. Pagination Settings

The gallery loads images in batches. You can adjust these values in the ViewModel:

*   Initial load: 10 images
    
*   Batch size: 10 images
    
*   Preload threshold: 4 images from the end
    

### 4\. API Integration

Replace the API endpoint with your own in the ViewModel or adjust to a better architecture, remember this is only an implementation exercise. Make sure to:

*   Update the URL structure
    
*   Modify any query parameters
    
*   Adjust the response parsing
    

Requirements
------------

*   iOS 15.0+
    
*   Xcode 13.0+
    
*   SwiftUI

Usage
-----

Simply add ArtGalleryView to your SwiftUI view hierarchy and configure as needed. Rename views and variables to match your API.

Code considerations
-----

Please check to see `Code considerations` current code has many prints to make the cache actions more visuals. To use the code I recommed to replace the methods on `ImageCache.swift` with the ones stated there.

Important Notes
---------------

*   The cache is automatically cleared when the view disappears
    
*   Images are loaded in batches to optimize performance
    
*   The cache automatically manages memory pressure using NSCache
    

Known Limitations
-----------------

*   Currently only supports image types that UIImage can handle
    
*   No offline persistence (intentionally, to avoid excessive device storage usage)
    
*   Cache is memory-only, which is suitable for this type of gallery application
