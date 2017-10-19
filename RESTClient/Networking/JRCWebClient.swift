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
        setValue("application/json", forHTTPHeaderField: "Accept")
        setValue("application/json", forHTTPHeaderField: "Content-Type")
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
    var jsonDecoder = JSONDecoder()
    
    init(baseUrl: String) {
        self.baseUrl = baseUrl
    }
    
    func load<A: Decodable, CustomError>(path: String,
                                         method: RequestMethod = .get,
                                         params: JSON = [:],
                                         headers: HTTPHeaders = [:],
                                         completion: @escaping (A?, JRCWebError<CustomError>?) -> ()) -> URLSessionDataTask? {
        // Checking internet connection availability
        if !Reachability.isConnectedToNetwork() {
            completion(nil, .noInternetConnection)
            return nil
        }
        
        // Adding common parameters
        let parameters = params.merging(commonParams, uniquingKeysWith: { spec, common in
            return spec
        })
        
        // Creating the URLRequest object
        let request = URLRequest(baseUrl: baseUrl, path: path, method: method, params: parameters, headers: headers)
        
        // Sending request to the server.
        let task = URLSession.shared.dataTask(with: request) { data, response, _ in
            // Parsing incoming data
            guard let response = response as? HTTPURLResponse else {
                completion(nil, .other)
                return
            }
            
            if (200..<300) ~= response.statusCode {
                if let result = data.flatMap({ try? self.jsonDecoder.decode(A.self, from: $0) }) {
                    completion(result, nil)
                } else {
                    completion(nil, .other)
                }
            } else if response.statusCode == 401 {
                completion(nil, .unauthorized)
            } else {
                let error: JRCWebError = data.flatMap({ try? self.jsonDecoder.decode(CustomError.self, from: $0) }).map({ JRCWebError.custom($0) }) ?? .other
                completion(nil, error)
            }
        }
        
        task.resume()
        
        return task
    }
}
