//
//  ServiceContainer.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 13/3/26.
//

import Foundation

enum KeychainKeys {
    static let mnemonic   = "zephyr.mnemonic"
    static let address    = "zephyr.address"
    static let privateKey = "zephyr.privateKey"
    static let publicKey  = "zephyr.publicKey"
}

struct ServiceContainer {
    let keychain:  KeychainService
    let crypto:    CryptoService
    let ethereum:  EthereumService

    static func live() -> ServiceContainer {
        let keychain = KeychainServiceInstance()
        return ServiceContainer(
            keychain:  keychain,
            crypto:    CryptoServiceInstance(),
            ethereum:  EthereumServiceInstance(keychainService: keychain)
        )
    }

    static func mock() -> ServiceContainer {
        ServiceContainer(
            keychain:  KeychainServiceMock(),
            crypto:    CryptoServiceMock(),
            ethereum:  EthereumServiceMock()
        )
    }
}
