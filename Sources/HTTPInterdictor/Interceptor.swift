//
//  Interceptor.swift
//  
//
//  Created by Daniel Otero on 26/12/23.
//

import Foundation

public actor InterceptorChain: Sendable {
    public let originalRequest: Request
    public private(set) var request: Request
    private var iterator: IndexingIterator<[Interceptor]>
    private let completion: (Request) async throws -> Response

    internal init(request: Request, interceptors: [Interceptor], completion: @Sendable @escaping (Request) async throws -> Response) {
        self.request = request
        self.originalRequest = request
        self.completion = completion
        self.iterator = interceptors.makeIterator()
    }


    public func proceed(request: Request) async throws -> Response {
        self.request = request
        return if let next = iterator.next() {
            try await next.intercept(chain: self)
        } else {
            try await completion(request)
        }
    }
}

public protocol Interceptor: Sendable {
    func intercept(chain: InterceptorChain) async throws -> Response
}
