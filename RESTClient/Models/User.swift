//
//  User.swift
//  RESTClient
//
//  Created by Alexander Gaidukov on 11/18/16.
//  Copyright © 2016 Alexander Gaidukov. All rights reserved.
//

import Foundation

struct User: Decodable {
    var id: String
    var email: String
    var name: String
}

struct FriendsResponse: Decodable {
    var friends: [User]
}
