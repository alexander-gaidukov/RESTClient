//
//  CachedWebService.swift
//  RESTClient
//
//  Created by Alexandr Gaidukov on 19/10/2017.
//  Copyright © 2017 Alexander Gaidukov. All rights reserved.
//

import Foundation

open class CachedWebClient {
    
    private let webClient: WebClient
    
    init(webClient: WebClient) {
        self.webClient = webClient
    }
    
    public func load<A, CustomError>(resource: Resource<A, CustomError>,
                                     forceUpdate: Bool = false,
                                     cacheAliveDuration: TimeInterval? = nil,
                              completion: @escaping (Result<A, CustomError>) ->()) -> URLSessionDataTask? {

        if !forceUpdate, let object = Cache.shared.load(forResource: resource)  {
            completion(Result(value: object, or: .other))
            return nil
        }
        
        let dataResource = Resource<Data, CustomError>(path: resource.path.absolutePath, method: resource.method, params: resource.params, headers: resource.headers, parse: { $0 }, parseError: resource.parseError)
        
        return webClient.load(resource: dataResource) { result in
            switch result {
            case .success(let data):
                if let value = resource.parse(data) {
                    Cache.shared.save(data, forResource: resource, aliveDuration: cacheAliveDuration)
                    completion(.success(value))
                } else {
                    completion(.failure(.other))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
