//
//  WebClient.swift
//  RESTClient
//
//  Created by Alexander Gaidukov on 11/18/16.
//  Copyright © 2016 Alexander Gaidukov. All rights reserved.
//

import Foundation

public typealias JSON = [String: Any]
public typealias HTTPHeaders = [String: String]

public enum RequestMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

struct Path {
    private var components: [String]
    
    var absolutePath: String {
        return "/" + components.joined(separator: "/")
    }
    
    init(_ path: String) {
        components = path.components(separatedBy: "/").filter({ !$0.isEmpty })
    }
    
    mutating func append(path: String) {
        components += path.components(separatedBy: "/").filter({ !$0.isEmpty })
    }
    
    func appending(path: String) -> Path {
        var copy = self
        copy.append(path: path)
        return copy
    }
}

public enum Result<A, CustomError> {
    case success(A)
    case failure(JRCWebError<CustomError>)
}

extension Result {
    init(value: A?, or error: JRCWebError<CustomError>) {
        guard let value = value else {
            self = .failure(error)
            return
        }
        
        self = .success(value)
    }
    
    var value: A? {
        guard case let .success(value) = self else { return nil }
        return value
    }
    
    var error: JRCWebError<CustomError>? {
        guard case let .failure(error) = self else { return nil }
        return error
    }
}

extension URL {
    init(baseUrl: String, path: String, params: JSON, method: RequestMethod) {
        var components = URLComponents(string: baseUrl)!
        components.path = Path(components.path).appending(path: path).absolutePath
        
        switch method {
        case .get, .delete:
            components.queryItems = params.map {
                URLQueryItem(name: $0.key, value: String(describing: $0.value))
            }
        default:
            break
        }
        
        self = components.url!
    }
}

extension URLRequest {
    init(baseUrl: String, path: String, method: RequestMethod, params: JSON, headers: HTTPHeaders) {
        let url = URL(baseUrl: baseUrl, path: path, params: params, method: method)
        self.init(url: url)
        httpMethod = method.rawValue
        headers.forEach{
            setValue($0.value, forHTTPHeaderField: $0.key)
        }
        switch method {
        case .post, .put:
            httpBody = try! JSONSerialization.data(withJSONObject: params, options: [])
        default:
            break
        }
    }
}

open class JRCWebClient {
    private var baseUrl: String
    
    var commonParams: JSON = [:]
    
    init(baseUrl: String) {
        self.baseUrl = baseUrl
    }
    
    func load<A, CustomError>(path: String,
                 method: RequestMethod = .get,
                 params: JSON = [:],
                 headers: HTTPHeaders = [:],
                 parse: @escaping (Data) -> A?,
                 parseError: @escaping (Data) -> CustomError? = {_ in return nil},
                 completion: @escaping (Result<A, CustomError>) ->()) -> URLSessionDataTask? {
        
        if !Reachability.isConnectedToNetwork() {
            completion(.failure(.noInternetConnection))
            return nil
        }
        
        let parameters = params.merging(commonParams, uniquingKeysWith: { spec, common in
            return spec
        })
        
        let request = URLRequest(baseUrl: baseUrl, path: path, method: method, params: parameters, headers: headers)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, _ in
            // Parsing incoming data
            guard let response = response as? HTTPURLResponse else {
                completion(.failure(.noInternetConnection))
                return
            }
            
            if (200..<300) ~= response.statusCode {
                completion(Result(value: data.flatMap(parse), or: .other))
            } else if response.statusCode == 401 {
                completion(.failure(.unauthorized))
            } else {
                completion(.failure(data.flatMap(parseError).map({.custom($0)}) ?? .other))
            }
        }
        
        task.resume()
        
        return task
        
    }
    
    func loadJSON<A: Decodable, CustomError: Decodable>(path: String,
                                         method: RequestMethod = .get,
                                         params: JSON = [:],
                                         headers: HTTPHeaders = [:],
                                         decoder: JSONDecoder = JSONDecoder(),
                                         completion: @escaping (Result<A, CustomError>) -> ()) -> URLSessionDataTask? {
        
        let newHeaders = headers.merging(["Accept": "application/json", "Content-Type": "application/json"]) { first, second in
            return second
        }
        
        return load(path: path,
                    method: method,
                    params: params,
                    headers: newHeaders,
                    parse: {return try? decoder.decode(A.self, from: $0)},
                    parseError: { return try? decoder.decode(CustomError.self, from: $0)},
                    completion: completion)
        
        
    }
}
