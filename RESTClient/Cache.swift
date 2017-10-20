//
//  Cache.swift
//  RESTClient
//
//  Created by Alexandr Gaidukov on 19/10/2017.
//  Copyright © 2017 Alexander Gaidukov. All rights reserved.
//

import Foundation

extension Resource {
    var cacheKey: String {
        var result = "cache_" + path.absolutePath + "_"
        for key in params.keys.sorted() {
            result += "\(key)=\(String(describing: params[key]))"
        }
        return result
    }
}

final class Cache {
    
    static let shared: Cache = Cache()
    
    private var sessionCache: NSCache<AnyObject, CacheItem> = NSCache<AnyObject, CacheItem>()
    
    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(Cache.clearSessionCache), name: NSNotification.Name.UIApplicationDidReceiveMemoryWarning, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func clearSessionCache() {
        sessionCache.removeAllObjects()
    }
    
    func load<A, E>(forResource resource: Resource<A, E>) -> A? {
        
        guard resource.method == .get else { return nil }
        
        guard let cacheItem = (sessionCache.object(forKey: resource.cacheKey as AnyObject)) else {
            return nil
        }
        
        if let aliveTill = cacheItem.aliveTill, aliveTill.compare(Date()) == .orderedAscending {
            sessionCache.removeObject(forKey: cacheItem)
            return nil
        }
        
        return resource.parse(cacheItem.data)
    }
    
    func save<A, E>(_ data: Data, forResource resource: Resource<A, E>, aliveDuration: TimeInterval? = nil) {
        
        guard resource.method == .get else { return }
        
        let cacheItem = CacheItem(data: data, aliveTill: aliveDuration.flatMap({ Date().addingTimeInterval($0) }))
        
        sessionCache.setObject(cacheItem, forKey: resource.cacheKey as AnyObject)
    }
}
