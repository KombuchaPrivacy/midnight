/*
 * Based on: https://github.com/slashmo/swift-app-store-receipt-validation
 * Author: Moritz Lang
 * License: Apache 2.0
 */


import class Foundation.JSONDecoder
import class Foundation.JSONEncoder

import Vapor

public protocol AppStoreClientRequestEncoder {
    func encodeAsByteBuffer<T: Encodable>(_ value: T, allocator: ByteBufferAllocator) throws -> ByteBuffer
}

public protocol AppStoreClientResponseDecoder {
    func decode<T: Decodable>(_ type: T.Type, from: ByteBuffer) throws -> T
}

public enum AppStore {
    public struct Client {
        let vaporClient: Vapor.Client
        let secret: String?
        let allocator = ByteBufferAllocator()
        let encoder: AppStoreClientRequestEncoder
        let decoder: AppStoreClientResponseDecoder

        public init(vaporClient: Vapor.Client, secret: String?) {
            self.init(vaporClient: vaporClient,
                      encoder: JSONEncoder(),
                      decoder: JSONDecoder(),
                      secret: secret)
        }

        public init(
            vaporClient: Vapor.Client,
            encoder: AppStoreClientRequestEncoder,
            decoder: AppStoreClientResponseDecoder,
            secret: String?
        ) {
            self.vaporClient = vaporClient
            self.encoder = encoder
            self.decoder = decoder
            self.secret = secret
        }

        public func validateReceipt(
            _ receipt: String,
            excludeOldTransactions: Bool? = nil
        ) -> EventLoopFuture<AppStore.Response> {

            let request = AppStore.Request(
                receiptData: receipt,
                password: self.secret,
                excludeOldTransactions: excludeOldTransactions
            )

            return executeRequest(request, in: .production, allocator: allocator)
                .flatMapError { (error) -> EventLoopFuture<AppStore.Response> in
                    switch error {
                    case Error.receiptIsFromTestEnvironmentButWasSentToProductionEnvironment:
                        return self.executeRequest(request, in: .sandbox, allocator: allocator)
                    default:
                        // TBD: This doesn't look good. Maybe we keep the eventLoopGroup for ourselfs?
                        return vaporClient.eventLoop.makeFailedFuture(error)
                    }
                }
                /*
                .map { (response) -> (AppStore.Receipt) in
                    response.receipt
                }
                */
        }

        private func executeRequest(
            _ request: AppStore.Request,
            in environment: Environment,
            allocator: ByteBufferAllocator
        ) -> EventLoopFuture<AppStore.Response> {

            let url = URL(string: environment.url)!
            let appStoreUri = URI(scheme: url.scheme,
                                  host: url.host,
                                  port: url.port,
                                  path: url.path)
            return vaporClient.post(appStoreUri) { req in
                // The App Store validation `Request` structure should be the body of the HTTP request
                try req.content.encode(request)
            }
            .flatMap { (clientResponse) -> EventLoopFuture<AppStore.Response> in
                // Cool we got the response from the App Store
                // Decode it into the AppStore.Response data structure that we're supposed to return
                guard let appStoreResponse = try? clientResponse.content.decode(AppStore.Response.self) else {
                    // Boo - Either we got garbage data, no data, or we failed to decode what we got
                    return vaporClient.eventLoop.makeFailedFuture(Abort(.internalServerError, reason: "Failed to validate receipt"))
                }
                return vaporClient.eventLoop.makeSucceededFuture(appStoreResponse)
            }

            /*
            return eventLoop.makeSucceededFuture(())
                .flatMapThrowing { (_) -> HTTPClient.Request in
                    let buffer = try self.encoder.encodeAsByteBuffer(request, allocator: allocator)
                    return try HTTPClient.Request(url: environment.url, method: .POST, body: .byteBuffer(buffer))
                }
                .flatMap { (request) -> EventLoopFuture<HTTPClient.Response> in
                    self.vaporClient.execute(request: request, eventLoop: .delegateAndChannel(on: eventLoop))
                }
                .flatMapThrowing { (resp) throws -> (Response) in
                    let status = try self.decoder.decode(Status.self, from: resp.body!)

                    if status.status != 0 {
                        throw Error(statusCode: status.status)
                    }

                    return try self.decoder.decode(Response.self, from: resp.body!)
                }
            */
        }
    }
}

extension JSONEncoder: AppStoreClientRequestEncoder {}

extension JSONDecoder: AppStoreClientResponseDecoder {}

