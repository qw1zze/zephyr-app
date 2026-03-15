//
//  RelayServiceInstance.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 14/3/26.
//

import Foundation
import os
import web3swift
import Web3Core
internal import CryptoSwift

actor RelayServiceInstance: RelayService {
    private let wsURL: URL
    private let keychain: KeychainService
    private let logger: Logger

    private var webSocketTask: URLSessionWebSocketTask?

    private var currentState: RelayConnectionState = .disconnected {
        didSet { _rawState = currentState }
    }

    nonisolated(unsafe) private var _rawState: RelayConnectionState = .disconnected

    nonisolated var connectionState: RelayConnectionState { _rawState }

    private var envelopeContinuation: AsyncStream<Envelope>.Continuation?
    private var statusContinuation: AsyncStream<ServerAckPayload>.Continuation?

    nonisolated let incomingEnvelopes: AsyncStream<Envelope>
    nonisolated let deliveryStatuses: AsyncStream<ServerAckPayload>

    init(wsURL: URL, keychain: KeychainService, logger: Logger) {
        self.wsURL = wsURL
        self.keychain = keychain
        self.logger = logger

        var envCont: AsyncStream<Envelope>.Continuation!
        var statusCont: AsyncStream<ServerAckPayload>.Continuation!

        self.incomingEnvelopes = AsyncStream { c in envCont    = c }
        self.deliveryStatuses = AsyncStream { c in statusCont = c }

        self.envelopeContinuation = envCont
        self.statusContinuation = statusCont
    }

    func connect() async throws {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil

        logger.info("Connecting to relay: \(self.wsURL)")
        currentState = .connecting

        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: wsURL)
        webSocketTask?.resume()

        currentState = .authenticating
        let challengeMsg = try await receiveMessage()
        
        guard challengeMsg.type == .challenge else {
            throw RelayError.unexpectedMessage(challengeMsg.type)
        }
        
        let challenge = try challengeMsg.decode(ChallengePayload.self)
        logger.info("Received challenge: \(challenge.nonce)")

        let privateKey = try await keychain.load(key: KeychainKeys.privateKey)
        let addressData = try await keychain.load(key: KeychainKeys.address)
        
        guard let address = String(data: addressData, encoding: .utf8) else {
            throw RelayError.authFailed
        }
        
        let signature = try signEIP191(message: challenge.nonce, privateKey: privateKey)

        try await sendMessage(type: .auth, payload: AuthPayload(address: address, signature: signature))

        let authResult = try await receiveMessage()
        guard authResult.type == .authOK else {
            throw RelayError.authFailed
        }

        currentState = .connected
        logger.info("Authenticated as \(address)")
        logger.info("Connected to relay")

        Task {
            await receiveLoop()
        }
    }

    func disconnect() async {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        currentState = .disconnected
        envelopeContinuation?.finish()
        statusContinuation?.finish()
    }

    func send(envelope: Envelope) async throws {
        try await sendMessage(type: .send, payload: envelope)
    }

    func ack(messageId: String) async throws {
        try await sendMessage(type: .ack, payload: AckPayload(messageId: messageId))
    }

    private func sendMessage<T: Encodable>(type msgType: RelayMessageType, payload: T) async throws {
        let data = try JSONEncoder().encode(RelayMessageWrapper(type: msgType, payload: payload))
        
        guard let str = String(data: data, encoding: .utf8) else {
            throw RelayError.sendFailed
        }
        
        guard let task = webSocketTask else {
            throw RelayError.connectionLost
        }
        
        try await task.send(.string(str))
    }

    private func receiveMessage() async throws -> RelayMessage {
        guard let task = webSocketTask else {
            throw RelayError.connectionLost
        }
        
        let raw = try await task.receive()
        let data: Data
        switch raw {
        case .string(let str):
            guard let d = str.data(using: .utf8) else {
                throw RelayError.decodingFailed
            }
            
            data = d
        case .data(let d):
            data = d
        @unknown default:
            throw RelayError.decodingFailed
        }
        
        return try JSONDecoder().decode(RelayMessage.self, from: data)
    }

    private func receiveLoop() async {
        while true {
            guard case .connected = currentState else { break }
            
            do {
                let message = try await receiveMessage()
                switch message.type {
                case .deliver:
                    if let payload = message.payload {
                        let envelope = try await payload.decode(Envelope.self)
                        envelopeContinuation?.yield(envelope)
                    }
                case .serverAck:
                    if let payload = message.payload {
                        let ackStatus = try await payload.decode(ServerAckPayload.self)
                        statusContinuation?.yield(ackStatus)
                    }
                case .ping:
                    try await sendMessage(type: .pong, payload: EmptyPayload())
                default:
                    logger.warning("Unexpected message in receiveLoop: \(message.type.rawValue)")
                }
            } catch {
                if case .disconnected = currentState { break }

                logger.error("Relay receive error: \(error.localizedDescription)")
                currentState = .disconnected
                Task {
                    await scheduleReconnect(attempt: 0)
                }
                break
            }
        }
    }

    private func scheduleReconnect(attempt: Int) async {
        if case .connected = currentState { return }
        if case .disconnected = currentState, attempt > 0 { return }

        let delay = min(pow(2.0, Double(attempt)), 60.0)
        currentState = .reconnecting
        logger.info("Relay reconnecting in \(Int(delay))s (attempt \(attempt + 1))")

        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

        guard case .reconnecting = currentState else { return }

        do {
            try await connect()
        } catch {
            logger.error("Reconnect attempt \(attempt + 1) failed: \(error.localizedDescription)")
            await scheduleReconnect(attempt: attempt + 1)
        }
    }

    private func signEIP191(message: String, privateKey: Data) throws -> String {
        let messageData = message.data(using: .utf8)!

        let keystore = try EthereumKeystoreV3(privateKey: privateKey, password: "")
        let account = keystore?.addresses?.first
        
        guard let account, let keystore else {
            throw RelayError.connectionLost
        }

        let signature = try Web3Signer.signPersonalMessage(messageData, keystore: keystore, account: account, password: "")
        
        guard let signature else {
            throw RelayError.connectionLost
        }
        
        return signature.toHexString()
    }
}
