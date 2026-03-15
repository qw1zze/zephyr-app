//
//  ServiceContainer.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 13/3/26.
//

import Foundation
import Combine
import os

enum KeychainKeys {
    static let mnemonic = "zephyr.mnemonic"
    static let address = "zephyr.address"
    static let privateKey = "zephyr.privateKey"
    static let publicKey  = "zephyr.publicKey"
}

struct ServiceContainer {
    let keychain: KeychainService
    let crypto: CryptoService
    let ethereum: BlockchainService
    let persistence: PersistenceService
    let relay: RelayService
    let storage: StorageService
    let messageSender: MessageSender
    let messageBatch: MessageBatchService
    let blockchainRecovery: BlockchainRecoveryService

    let envelopePublisher: PassthroughSubject<Envelope, Never>

    static func live() -> ServiceContainer {
        let keychain = KeychainServiceInstance()
        let crypto = CryptoServiceInstance()
        let ethereum = BlockchainServiceInstance(keychainService: keychain)
        let relay = RelayServiceInstance(wsURL: URL(string: Constants.relayWSURL)!, keychain: keychain,
                                         logger: Logger(subsystem: "com.zephyr.app", category: "RelayClient"))
        let storage = StorageServiceInstance(baseURL: URL(string: Constants.storageBaseURL)!,
                                               logger: Logger(subsystem: "com.zephyr.app", category: "StorageClient"))
        let sender = MessageSender(keychain: keychain, ethereum: ethereum, storage: storage, relay: relay,
                                   crypto: crypto, logger: Logger(subsystem: "com.zephyr.app", category: "MessageSender"))
        
        let persistence = try! PersistenceServiceInstance()
        let recovery = BlockchainRecoveryService(ethereum: ethereum, persistence: persistence,
                                                 messageSender: sender, logger: Logger(subsystem: "com.zephyr.app", category: "BlockchainRecovery"))

        return ServiceContainer(keychain: keychain, crypto: crypto, ethereum: ethereum, persistence: persistence, relay: relay,
                                storage: storage, messageSender: sender, messageBatch: MessageBatchService(ethereum: ethereum),
                                blockchainRecovery: recovery, envelopePublisher: PassthroughSubject<Envelope, Never>())
    }

    static func mock() -> ServiceContainer {
        let keychain = KeychainServiceMock()
        let crypto = CryptoServiceMock()
        let ethereum = BlockchainServiceMock()
        let relay = RelayServiceMock()
        let storage = StorageServiceMock()
        let sender = MessageSender(
            keychain: keychain,
            ethereum: ethereum,
            storage: storage,
            relay: relay,
            crypto: crypto,
            logger: Logger(subsystem: "com.zephyr.app", category: "MessageSender")
        )
        
        let persistence = PersistenceServiceMock()
        let recovery = BlockchainRecoveryService(ethereum: ethereum, persistence: persistence, messageSender: sender,
                                                 logger: Logger(subsystem: "com.zephyr.app", category: "BlockchainRecovery"))

        return ServiceContainer(keychain: keychain, crypto: crypto, ethereum: ethereum, persistence: persistence,
                                relay: relay, storage: storage, messageSender: sender, messageBatch: MessageBatchService(ethereum: ethereum),
                                blockchainRecovery: recovery, envelopePublisher: PassthroughSubject<Envelope, Never>())
    }
}
