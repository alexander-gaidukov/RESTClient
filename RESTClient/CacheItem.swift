//
//  CacheItem.swift
//  RESTClient
//
//  Created by Alexandr Gaidukov on 19/10/2017.
//  Copyright © 2017 Alexander Gaidukov. All rights reserved.
//

import Foundation

final class CacheItem {
    var data: Data
    var aliveTill: Date?
    
    init(data: Data, aliveTill: Date?) {
        self.data = data
        self.aliveTill = aliveTill
    }
}
