//
//  RelayModels.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 14/3/26.
//

import Foundation

extension RelayServiceInstance {
    enum RelayMessageType: String, Codable {
        case challenge = "challenge"
        case auth = "auth"
        case authOK = "auth_ok"
        case send = "send"
        case deliver = "deliver"
        case ack = "ack"
        case serverAck = "server_ack"
        case ping = "ping"
        case pong = "pong"
    }
    
    enum RelayError: Error, LocalizedError {
        case unexpectedMessage(RelayMessageType)
        case authFailed
        case connectionLost
        case sendFailed
        case decodingFailed

        var errorDescription: String? {
            switch self {
            case .unexpectedMessage(let t):
                return "Unexpected message: \(t.rawValue)"
            case .authFailed:
                return "Authentication failed"
            case .connectionLost:
                return "Connection lost"
            case .sendFailed:
                return "Failed to send message"
            case .decodingFailed:
                return "Failed to decode message"
            }
        }
    }

    struct RelayMessage: Decodable {
        let type: RelayMessageType
        let payload: AnyCodable?

        func decode<T: Decodable>(_ type: T.Type) throws -> T {
            guard let payload else { throw RelayError.decodingFailed }
            return try payload.decode(type)
        }
    }

    struct ChallengePayload: Decodable {
        let nonce: String
    }

    struct AuthPayload: Encodable {
        let address: String
        let signature: String
    }

    struct AckPayload: Encodable {
        let messageId: String
        
        enum CodingKeys: String, CodingKey {
            case messageId = "message_id"
        }
    }

    struct EmptyPayload: Encodable {}

    struct RelayMessageWrapper<P: Encodable>: Encodable {
        let type: RelayMessageType
        let payload: P
    }
}
