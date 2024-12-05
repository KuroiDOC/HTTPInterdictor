//
//  Request.swift
//  
//
//  Created by Daniel Otero on 27/12/23.
//

import Foundation

public struct Request: Sendable {
    public var url: URL
    public var method: Method
    public var headers: [String: String]
    public var queryItems: [URLQueryItem]?
    public var body: Data?

    public init(url: URL, method: Method = .get, headers: [String : String] = [:], queryItems: [URLQueryItem]? = nil, body: Encodable?, encoder: JSONEncoder = JSONEncoder()) throws {
        self.url = url
        self.method = method
        self.headers = headers
        self.queryItems = queryItems
        if let body {
            self.body = try encoder.encode(body)
        }
    }

    public init(url: URL, method: Method = .get, headers: [String : String] = [:], queryItems: [URLQueryItem]? = nil, rawBody: Data? = nil) {
        self.url = url
        self.method = method
        self.headers = headers
        self.queryItems = queryItems
        self.body = rawBody
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
            request.httpBody = body
            if !headers.keys.contains("Content-Type") {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        }

        return request
    }
}

public extension Request {
    enum Method: String, Sendable {
        case get, post, put, delete, patch, update
    }

    struct BuildError: Error {}
}

extension URLSession {
    func data(for request: Request, delegate: URLSessionTaskDelegate? = nil) async throws -> Response {
        try await self.data(for: request.buildURLRequest())
    }
}


