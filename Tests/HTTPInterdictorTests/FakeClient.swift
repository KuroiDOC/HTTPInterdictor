//
//  FakeClient.swift
//  
//
//  Created by Daniel Otero on 26/12/23.
//

import Foundation
@testable import HTTPInterdictor

class FakeClient: HTTPInterdictor {
    var handler: (Request) async throws -> Response

    init(handler: @escaping (Request) -> Response) {
        self.handler = handler
    }

    override func performRequest(request: Request) async throws -> Response {
        try await handler(request)
    }
}
