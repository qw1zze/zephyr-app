//
//  RelayServiceMock.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 14/3/26.
//

import Foundation

final class RelayServiceMock: RelayService {
    let incomingEnvelopes: AsyncStream<Envelope> = AsyncStream { _ in }
    let deliveryStatuses: AsyncStream<ServerAckPayload> = AsyncStream { _ in }
    var connectionState: RelayConnectionState = .disconnected

    func connect() async throws {}
    func disconnect() async {}
    func send(envelope: Envelope) async throws {}
    func ack(messageId: String) async throws {}
}
