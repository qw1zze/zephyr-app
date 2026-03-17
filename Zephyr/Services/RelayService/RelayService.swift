//
//  RelayService.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 14/3/26.
//

protocol RelayService: AnyObject {
    var incomingEnvelopes: AsyncStream<Envelope> { get }
    var deliveryStatuses: AsyncStream<ServerAckPayload> { get }
    var connectionState: RelayConnectionState { get }
    
    func connect() async throws
    func disconnect() async
    func send(envelope: Envelope) async throws
    func ack(messageId: String) async throws
}

struct ServerAckPayload: Codable, Sendable {
    let messageId: String
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case messageId = "message_id"
        case status
    }
}

enum RelayConnectionState {
    case disconnected
    case connecting
    case authenticating
    case connected
    case reconnecting
    case failed(Error)
}
