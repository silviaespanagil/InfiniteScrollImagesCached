`#  Code considerations

## Methods

Methods on `ImageCache` could and should be simplified for final use removing code that was added solely to add some prints for information.

 Methods such as `set`, `get` and `clear` could be
 
 ```
func set(_ image: UIImage, forKey key: String) {

        let cost = Int(image.size.width * image.size.height * 4)
        
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }
    
    func get(forKey key: String) -> UIImage? {
    
        return cache.object(forKey: key as NSString)
    }
    
    func clear() {
    
        cache.removeAllObjects()
    }
```
