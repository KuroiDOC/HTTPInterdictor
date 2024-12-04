//
//  Request.swift
//  
//
//  Created by Daniel Otero on 27/12/23.
//

import Foundation

public struct Request {
    public var url: URL
    public var method: Method
    public var headers: [String: String]
    public var queryItems: [URLQueryItem]?
    public var body: Encodable?
    public var encoder: JSONEncoder

    public init(url: URL, method: Method = .get, headers: [String : String] = [:], queryItems: [URLQueryItem]? = nil, body: Encodable? = nil, encoder: JSONEncoder = JSONEncoder()) {
        self.url = url
        self.method = method
        self.headers = headers
        self.queryItems = queryItems
        self.body = body
        self.encoder = encoder
    }

    fileprivate func buildURLRequest() throws -> URLRequest {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            throw BuildError()
        }
        components.queryItems = queryItems

        guard let url = components.url else { throw BuildError() }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue.uppercased()
        if !headers.keys.contains("Accept") {
            request.setValue("application/json", forHTTPHeaderField: "Accept")
        }
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        if let body {
            request.httpBody = try encoder.encode(body)
            if !headers.keys.contains("Content-Type") {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        }

        return request
    }
}

public extension Request {
    enum Method: String {
        case get, post, put, delete, patch, update
    }

    struct BuildError: Error {}
}

extension URLSession {
    func data(for request: Request, delegate: URLSessionTaskDelegate? = nil) async throws -> Response {
        try await self.data(for: request.buildURLRequest())
    }
}


