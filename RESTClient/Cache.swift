//
//  Cache.swift
//  RESTClient
//
//  Created by Alexandr Gaidukov on 19/10/2017.
//  Copyright © 2017 Alexander Gaidukov. All rights reserved.
//

import Foundation

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
    
    func load(key: String) -> Data? {
        guard let cacheItem = (sessionCache.object(forKey: key as AnyObject)) else {
            return nil
        }
        
        if let aliveTill = cacheItem.aliveTill, aliveTill.compare(Date()) == .orderedAscending {
            sessionCache.removeObject(forKey: cacheItem)
            return nil
        }
        
        return cacheItem.data
    }
    
    func save(_ data: Data, forKey key: String, aliveDuration: TimeInterval? = nil) {
        
        let cacheItem = CacheItem(data: data, aliveTill: aliveDuration.flatMap({ Date().addingTimeInterval($0) }))
        
        sessionCache.setObject(cacheItem, forKey: key as AnyObject)
    }
}
