//
//  FriendsService.swift
//  RESTClient
//
//  Created by Alexander Gaidukov on 11/18/16.
//  Copyright © 2016 Alexander Gaidukov. All rights reserved.
//

import Foundation

final class FriendsService {
    private let client = WebClient()
    
    @discardableResult
    func loadFriends(completion: @escaping ([User]?, ServiceError?) -> ()) -> URLSessionDataTask? {
        
        let params: JSON = [:]
        
        return client.load(path: "/friends", method: .get, params: params) { result, error in
            let dictionaries = result as? [JSON]
            completion(dictionaries?.flatMap(User.init), error)
        }
    }
}
