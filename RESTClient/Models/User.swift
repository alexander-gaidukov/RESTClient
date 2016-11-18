//
//  User.swift
//  RESTClient
//
//  Created by Alexander Gaidukov on 11/18/16.
//  Copyright © 2016 Alexander Gaidukov. All rights reserved.
//

import Foundation

typealias JSON = [String: Any]

struct User {
    var id: String
    var email: String?
    var name: String?
}

extension User {
    init?(json: JSON) {
        guard let id = json["id"] as? String else {
            return nil
        }
        
        self.id = id
        self.email = json["email"] as? String
        self.name = json["name"] as? String
    }
}
