//
//  EthereumServiceInstance.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 13/3/26.
//

import Foundation
import web3swift
import Web3Core
internal import CryptoSwift
import BigInt

final class EthereumServiceInstance: EthereumService {

    private let keychainService: KeychainService

    init(keychainService: KeychainService) {
        self.keychainService = keychainService
    }

    private func web3ReadOnly() async throws -> Web3 {
        guard let url = URL(string: Constants.RPCURL) else {
            throw EthereumError.contractLoadFailed
        }
        return try await Web3.new(url)
    }

    private func web3WithSigner() async throws -> Web3 {
        let web3 = try await web3ReadOnly()

        let privateKeyData = try keychainService.load(key: KeychainKeys.privateKey)

        guard let keystore = try? EthereumKeystoreV3(privateKey: privateKeyData, password: "") else {
            throw EthereumError.keystoreCreationFailed
        }
        let manager = KeystoreManager([keystore])
        web3.addKeystoreManager(manager)
        return web3
    }

    private func userAddress() throws -> EthereumAddress {
        let data = try keychainService.load(key: KeychainKeys.address)
        guard let str = String(data: data, encoding: .utf8), let addr = EthereumAddress(str) else {
            throw EthereumError.keychainDataCorrupted
        }
        return addr
    }

    private func contract(web3: Web3) throws -> web3swift.Web3.Contract {
        guard let contractAddress = EthereumAddress(Constants.keyRegistryAddress),
                let contract = web3.contract(Constants.keyRegistryABI, at: contractAddress, abiVersion: 2) else {
            throw EthereumError.contractLoadFailed
        }
        return contract
    }

    func getPublicKey(address: String) async throws -> Data? {
        let web3 = try await web3ReadOnly()
        let contract = try contract(web3: web3)

        guard let ethAddr = EthereumAddress(address) else {
            throw EthereumError.contractError("Неверный адрес: \(address)")
        }

        let result = try? await contract
            .createReadOperation("getKey", parameters: [ethAddr] as [AnyObject])?
            .callContractMethod()

        guard let bytes = result?["0"] as? Data, !bytes.isEmpty else {
            return nil
        }
        return bytes
    }

    func publishPublicKey(_ publicKey: Data) async throws -> String {
        let web3 = try await web3WithSigner()
        let from = try userAddress()
        let contract = try contract(web3: web3)

        guard let write = contract.createWriteOperation("publishKey", parameters: [publicKey] as [AnyObject]) else {
            throw EthereumError.contractError("Не удалось создать транзакцию")
        }

        write.transaction.from = from
        write.transaction.chainID = 560048

        let result = try await write.writeToChain(password: "", policies: .init(noncePolicy: .latest, gasLimitPolicy: .automatic, gasPricePolicy: .manual(1589398120), maxFeePerGasPolicy: .automatic, maxPriorityFeePerGasPolicy: .automatic))

        return result.hash
    }

    func waitForConfirmation(txHash: String) async throws {
        let web3 = try await web3ReadOnly()
        let hashData = Data(hex: txHash)

        for _ in 0..<30 {
            try await Task.sleep(nanoseconds: 2_000_000_000)

            if let receipt = try? await web3.eth.transactionReceipt(hashData) {
                guard receipt.status == .ok else {
                    throw PublishKeyError.transactionFailed
                }
                return
            }
        }
        throw PublishKeyError.timeout
    }
}
