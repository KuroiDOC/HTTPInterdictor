import XCTest
@testable import HTTPInterdictor

final class HTTPInterdictorTests: XCTestCase {
    struct FakeInterceptor: Interceptor {
        var block: (InterceptorChain) async throws -> Response

        func intercept(chain: InterceptorChain) async throws -> Response {
            try await block(chain)
        }
    }

    let fakeClient = FakeClient { _ in (Data(), URLResponse())}

    func testInterceptorShouldModifyHeader() async throws {
        let request = Request(url: URL(string: "https://example.com")!, headers: ["SomeHeader": "SomeValue"])

        fakeClient.handler = { request in
            XCTAssertEqual(request.headers["SomeHeader"], "SomeValue")
            return (Data(), URLResponse())
        }

        _ = try await fakeClient.execute(request: request)

        let fakeInterceptor = FakeInterceptor { chain in
            var newRequest = chain.request
            newRequest.headers["SomeHeader"] = nil
            return try await chain.proceed(request: newRequest)
        }

        fakeClient.interceptors = [fakeInterceptor]
        fakeClient.handler = { request in
            XCTAssertNil(request.headers["SomeHeader"])
            return (Data(), URLResponse())
        }

        _ = try await fakeClient.execute(request: request)
    }

    func testInterceptorShouldAbortRequest() async throws {
        var request = Request(url: URL(string: "https://example.com")!)

        let fakeInterceptor = FakeInterceptor { chain in
            return if (chain.request.body as? Data)?.isEmpty ?? true {
                ("NIL".data(using: .utf8)!, HTTPURLResponse(url: request.url, statusCode: 500, httpVersion: nil, headerFields: nil)!)
            } else {
                ("SOME".data(using: .utf8)!, HTTPURLResponse(url: request.url, statusCode: 200, httpVersion: nil, headerFields: nil)!)
            }
        }
        fakeClient.interceptors = [fakeInterceptor]

        fakeClient.handler = { _ in
            XCTFail("Request should have been aborted")
            return (Data(), URLResponse())
        }

        var (data, response) = try await fakeClient.execute(request: request)
        XCTAssertEqual("NIL", String(data: data, encoding: .utf8))
        XCTAssertEqual(500, (response as? HTTPURLResponse)?.statusCode)

        request.body = "HELLO THERE!".data(using: .utf8)
        (data, response) = try await fakeClient.execute(request: request)
        XCTAssertEqual("SOME", String(data: data, encoding: .utf8))
        XCTAssertEqual(200, (response as? HTTPURLResponse)?.statusCode)

        _ = try await fakeClient.execute(request: request)
    }
}
