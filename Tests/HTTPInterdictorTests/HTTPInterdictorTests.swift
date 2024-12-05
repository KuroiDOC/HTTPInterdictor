import Foundation
import Testing
@testable import HTTPInterdictor

struct InterceptorTests {
    private struct FakeInterceptor: @unchecked Sendable, Interceptor {
        var block: (InterceptorChain) async throws -> Response

        func intercept(chain: InterceptorChain) async throws -> Response {
            try await block(chain)
        }
    }

    private let fakeClient = FakeClient { _ in (Data(), URLResponse())}

    @Test func interceptorShouldModifyHeader() async throws {
        let request = Request(url: URL(string: "https://example.com")!, headers: ["SomeHeader": "SomeValue"])

        fakeClient.handler = { request in
            #expect(request.headers["SomeHeader"] == "SomeValue")
            return (Data(), URLResponse())
        }

        _ = try await fakeClient.execute(request: request)

        let fakeInterceptor = FakeInterceptor { chain in
            var newRequest = await chain.request
            newRequest.headers["SomeHeader"] = nil
            return try await chain.proceed(request: newRequest)
        }

        fakeClient.interceptors = [fakeInterceptor]
        fakeClient.handler = { request in
            #expect(request.headers["SomeHeader"] == nil)
            return (Data(), URLResponse())
        }

        _ = try await fakeClient.execute(request: request)
    }

    @Test func interceptorShouldAbortRequest() async throws {
        var request = Request(url: URL(string: "https://example.com")!)

        let fakeInterceptor = FakeInterceptor { chain in
            return if (await chain.request.body)?.isEmpty ?? true {
                ("NIL".data(using: .utf8)!, HTTPURLResponse(url: request.url, statusCode: 500, httpVersion: nil, headerFields: nil)!)
            } else {
                ("SOME".data(using: .utf8)!, HTTPURLResponse(url: request.url, statusCode: 200, httpVersion: nil, headerFields: nil)!)
            }
        }
        fakeClient.interceptors = [fakeInterceptor]

        fakeClient.handler = { _ in
            Issue.record("Request should have been aborted as interceptor does not execure chain.proceed()")
            return (Data(), URLResponse())
        }

        var (data, response) = try await fakeClient.execute(request: request)
        #expect("NIL" == String(data: data, encoding: .utf8))
        #expect(500 == (response as? HTTPURLResponse)?.statusCode)

        request.body = "HELLO THERE!".data(using: .utf8)
        (data, response) = try await fakeClient.execute(request: request)
        #expect("SOME" == String(data: data, encoding: .utf8))
        #expect(200 == (response as? HTTPURLResponse)?.statusCode)

        _ = try await fakeClient.execute(request: request)
    }
}
