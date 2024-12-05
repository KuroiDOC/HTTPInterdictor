import Foundation

public typealias Response = (Data, URLResponse)

public class HTTPInterdictor: @unchecked Sendable {
    var session = URLSession.shared
    var interceptors: [Interceptor] = []

    public init(session: URLSession = URLSession.shared, interceptors: [Interceptor] = []) {
        self.session = session
        self.interceptors = interceptors
    }

    public func execute(request: Request) async throws -> Response {
        let chain = InterceptorChain(request: request, interceptors: interceptors) { request in
            try await self.performRequest(request: request)
        }

        return try await chain.proceed(request: request)
    }

    internal func performRequest(request: Request) async throws -> Response {
        try await session.data(for: request)
    }
}

