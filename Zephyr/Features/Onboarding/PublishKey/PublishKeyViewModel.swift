//
//  PublishKeyView.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 13/3/26.
//

import Foundation
import Combine

enum PublishKeyError: LocalizedError {
    case transactionFailed
    case timeout
    case keychainError
    case contractError(String)

    var errorDescription: String? {
        switch self {
        case .transactionFailed:         
            return "Транзакция отклонена сетью"
        case .timeout:                  
            return "Превышено время ожидания подтверждения"
        case .keychainError:             
            return "Ошибка чтения ключей из Keychain"
        case .contractError(let msg):    
            return "Ошибка контракта: \(msg)"
        }
    }
}

@MainActor
final class PublishKeyViewModel: ObservableObject {
    @Published private(set) var state: PublishKeyState = .checking

    private let container: ServiceContainer
    let onComplete: () -> Void

    init(container: ServiceContainer, onComplete: @escaping () -> Void) {
        self.container = container
        self.onComplete = onComplete
    }
    
    enum PublishKeyState: Equatable {
        case checking
        case publishing
        case waitingConfirm
        case done
        case alreadyExists
        case error(String)
    }

    func start() async {
        state = .checking
        do {
            guard let addressStr = try? container.keychain.load(key: KeychainKeys.address),
                let address = String(data: addressStr, encoding: .utf8),
                let pubKeyData = try? container.keychain.load(key: KeychainKeys.publicKey)
            else {
                throw PublishKeyError.keychainError
            }

            let existing = try await container.ethereum.getPublicKey(address: address)
            if existing != nil {
                state = .alreadyExists
                return
            }

            state = .publishing
            let txHash = try await container.ethereum.publishPublicKey(pubKeyData)

            state = .waitingConfirm
            try await container.ethereum.waitForConfirmation(txHash: txHash)

            state = .done

        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func retry() async {
        await start()
    }
}
