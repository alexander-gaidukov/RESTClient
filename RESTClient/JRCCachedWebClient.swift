//
//  CachedWebService.swift
//  RESTClient
//
//  Created by Alexandr Gaidukov on 19/10/2017.
//  Copyright © 2017 Alexander Gaidukov. All rights reserved.
//

import Foundation

open class JRCCachedWebClient {
    
    private let webClient: JRCWebClient
    
    init(webClient: JRCWebClient) {
        self.webClient = webClient
    }
    
    private func cacheKey(path: String, params: JSON) -> String {
        var result = "cache_" + path + "_"
        for key in params.keys.sorted() {
            result += "\(key)=\(String(describing: params[key]))"
        }
        return result
    }
    
    public func load<A, CustomError>(path: String,
                              method: RequestMethod = .get,
                              params: JSON = [:],
                              headers: HTTPHeaders = [:],
                              forceUpdate: Bool = false,
                              cacheLiveInterval: TimeInterval? = nil,
                              parse: @escaping (Data) -> A?,
                              parseError: @escaping (Data) -> CustomError? = {_ in return nil},
                              completion: @escaping (Result<A, CustomError>) ->()) -> URLSessionDataTask? {
        
        let key = cacheKey(path: path, params: params)
        
        if !forceUpdate, method == .get, let data = Cache.shared.load(key: key)  {
            completion(Result(value: parse(data), or: .other))
            return nil
        }
        
        return webClient.load(path: path, method: method, params: params, headers: headers, parse: { return $0 }, parseError: parseError, completion: { result in
            if let data = result.value {
                if method == .get {
                    Cache.shared.save(data, forKey: key, aliveDuration: cacheLiveInterval)
                }
                completion(Result(value: parse(data), or: .other))
            } else {
                completion(.failure(result.error!))
            }
        })
    }
    
    public func loadJSON<A: Decodable, CustomError: Decodable>(path: String,
                                                        method: RequestMethod = .get,
                                                        params: JSON = [:],
                                                        headers: HTTPHeaders = [:],
                                                        forceUpdate: Bool = false,
                                                        cacheLiveInterval: TimeInterval? = nil,
                                                        decoder: JSONDecoder = JSONDecoder(),
                                                        completion: @escaping (Result<A, CustomError>) -> ()) -> URLSessionDataTask? {
        
        let newHeaders = headers.merging(["Accept": "application/json", "Content-Type": "application/json"]) { first, second in
            return second
        }
        
        return load(path: path,
                    method: method,
                    params: params,
                    headers: newHeaders,
                    forceUpdate: forceUpdate,
                    cacheLiveInterval: cacheLiveInterval,
                    parse: {return try? decoder.decode(A.self, from: $0)},
                    parseError: { return try? decoder.decode(CustomError.self, from: $0)},
                    completion: completion)
        
        
    }
}
