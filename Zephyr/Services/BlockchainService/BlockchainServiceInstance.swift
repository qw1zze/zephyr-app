//
//  BlockchainServiceInstance.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 13/3/26.
//

import Foundation
import web3swift
import Web3Core
internal import CryptoSwift
import BigInt
internal import secp256k1

final class BlockchainServiceInstance: BlockchainService {

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

    private func messageRegistryContract(web3: Web3) throws -> web3swift.Web3.Contract {
        guard let contractAddress = EthereumAddress(Constants.messageRegistryAddress),
              let contract = web3.contract(Constants.messageRegistryABI, at: contractAddress, abiVersion: 2) else {
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

    private func isAlreadyKnown(_ error: Error) -> Bool {
        let description = error.localizedDescription.lowercased()
        return description.contains("already known") || description.contains("-32000")
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

        do {
            let result = try await write.writeToChain(password: "", policies: .init(noncePolicy: .latest, gasLimitPolicy: .automatic, gasPricePolicy: .manual(1589398120), maxFeePerGasPolicy: .automatic, maxPriorityFeePerGasPolicy: .automatic))
            return result.hash
        } catch {
            if isAlreadyKnown(error) { return "" }
            throw error
        }
    }

    func createChat(chatId: String, recipientAddress: String) async throws -> String {
        let web3 = try await web3WithSigner()
        let from = try userAddress()
        let contract = try messageRegistryContract(web3: web3)

        guard let recipient = EthereumAddress(recipientAddress) else {
            throw EthereumError.contractError("Неверный адрес получателя: \(recipientAddress)")
        }

        let chatIdBytes = Data(hex: chatId)

        guard let write = contract.createWriteOperation(
            "createChat",
            parameters: [chatIdBytes, recipient] as [AnyObject]
        ) else {
            throw EthereumError.contractError("Не удалось создать транзакцию createChat")
        }

        write.transaction.from = from
        write.transaction.chainID = 560048

        do {
            let result = try await write.writeToChain(
                password: "",
                policies: .init(
                    noncePolicy: .latest,
                    gasLimitPolicy: .automatic,
                    gasPricePolicy: .manual(1589398120),
                    maxFeePerGasPolicy: .automatic,
                    maxPriorityFeePerGasPolicy: .automatic
                )
            )
            return result.hash
        } catch {
            if isAlreadyKnown(error) { return "" }
            throw error
        }
    }

    func anchorBatch(chatId: String, messageIds: [String], cids: [String], timestamps: [Int64]) async throws -> String {
        let web3 = try await web3WithSigner()
        let from = try userAddress()
        let contract = try messageRegistryContract(web3: web3)

        let chatIdBytes = bytes32(hex: chatId)
        let msgIdBytes = messageIds.map { bytes32(uuid: $0) } as [AnyObject]
        let cidsAny = cids as [AnyObject]
        let tsAny = timestamps.map { BigUInt($0) } as [AnyObject]

        guard let write = contract.createWriteOperation("anchorBatch", parameters: [chatIdBytes, msgIdBytes, cidsAny, tsAny] as [AnyObject]) else {
            throw EthereumError.contractError("Не удалось создать транзакцию anchorBatch")
        }

        write.transaction.from = from
        write.transaction.chainID = 560048

        do {
            let result = try await write.writeToChain(
                password: "",
                policies: .init(
                    noncePolicy: .latest,
                    gasLimitPolicy: .automatic,
                    gasPricePolicy: .manual(2589398120),
                    maxFeePerGasPolicy: .automatic,
                    maxPriorityFeePerGasPolicy: .automatic
                )
            )
            return result.hash
        } catch {
            if isAlreadyKnown(error) { return "" }
            throw error
        }
    }

    private func bytes32(hex: String) -> Data {
        let stripped = hex.hasPrefix("0x") ? String(hex.dropFirst(2)) : hex
        var data = Data(from: stripped) ?? Data()
        if data.count < 32 { data.append(contentsOf: [UInt8](repeating: 0, count: 32 - data.count)) }
        return Data(data.prefix(32))
    }

    private func bytes32(uuid uuidString: String) -> Data {
        guard let uuid = UUID(uuidString: uuidString) else { return Data(count: 32) }
        var data = withUnsafeBytes(of: uuid.uuid) { Data($0) }   // 16 bytes
        data.append(contentsOf: [UInt8](repeating: 0, count: 16))
        return data
    }

    func getLatestBlock() async throws -> UInt64 {
        let web3 = try await web3ReadOnly()
        let blockNum = try await web3.eth.blockNumber()
        return UInt64(blockNum)
    }

    func getChatCreatedAtBlock(chatId: String) async throws -> UInt64 {
        let web3 = try await web3ReadOnly()
        let contract = try messageRegistryContract(web3: web3)
        let chatIdBytes = bytes32(hex: chatId)

        guard let result = try? await contract
            .createReadOperation("getChatCreatedAtBlock", parameters: [chatIdBytes] as [AnyObject])?
            .callContractMethod(), let value = result["0"] as? BigUInt else {
            return 0
        }
        return UInt64(value)
    }

    func getAnchoredBatches(chatId: String, fromBlock: UInt64, toBlock: UInt64) async throws -> [BatchAnchoredEvent] {
        let web3 = try await web3ReadOnly()

        guard let contractAddress = EthereumAddress(Constants.messageRegistryAddress) else {
            throw EthereumError.contractLoadFailed
        }

        let chatIdTopic = "0x" + chatId

        var filter = EventFilterParameters()
        filter.fromBlock = .exact(BigUInt(fromBlock))
        filter.toBlock = .exact(BigUInt(toBlock))
        filter.address = [contractAddress]
        filter.topics = [
            .string("0xe347f787e6b2a804533dcddc812eab35b5eeed05ed936f08bfaebb7bd2e73f6c"),
            .string(chatIdTopic)
        ]

        let logs = try await web3.eth.getLogs(eventFilter: filter)

        var events: [BatchAnchoredEvent] = []

        for log in logs {
            guard log.topics.count > 2 else { continue }
            let rawHex = "0x" + log.topics[2].suffix(20).toHexString()
            let senderAddr = EthereumAddress(rawHex)?.address ?? rawHex

            guard let decoded = decodeEventData(log.data) else { continue }

            let messageIds = decoded.messageIds.compactMap { uuidString(from: $0) }
            let timestamps = decoded.timestamps.map { Int64($0) }
            let blockNum = UInt64(decoded.blockNumber)

            guard messageIds.count == decoded.cids.count, messageIds.count == timestamps.count else { continue }

            events.append(BatchAnchoredEvent(sender: senderAddr, messageIds: messageIds, cids: decoded.cids, timestamps: timestamps, blockNumber: blockNum))
        }

        return events
    }

    private func decodeEventData(_ data: Data) -> (messageIds: [Data], cids: [String], timestamps: [BigUInt], blockNumber: BigUInt)? {
        guard data.count >= 128 else { return nil }

        let off0 = Int(BigUInt(data[0..<32]))
        let off1 = Int(BigUInt(data[32..<64]))
        let off2 = Int(BigUInt(data[64..<96]))
        let blockNumber = BigUInt(data[96..<128])

        guard let msgIds = decodeBytes32Array(data: data, offset: off0),
                let cids = decodeStringArray(data: data, offset: off1), let timestamps = decodeUint256Array(data: data, offset: off2) else { return nil }

        return (msgIds, cids, timestamps, blockNumber)
    }

    private func decodeBytes32Array(data: Data, offset: Int) -> [Data]? {
        guard offset + 32 <= data.count else { return nil }
        let count = Int(BigUInt(data[offset..<(offset + 32)]))
        var result: [Data] = []
        for i in 0..<count {
            let start = offset + 32 + i * 32
            guard start + 32 <= data.count else { return nil }
            result.append(data[start..<(start + 32)])
        }
        
        return result
    }

    private func decodeUint256Array(data: Data, offset: Int) -> [BigUInt]? {
        guard offset + 32 <= data.count else { return nil }
        let count = Int(BigUInt(data[offset..<(offset + 32)]))
        var result: [BigUInt] = []
        for i in 0..<count {
            let start = offset + 32 + i * 32
            guard start + 32 <= data.count else { return nil }
            result.append(BigUInt(data[start..<(start + 32)]))
        }
        
        return result
    }

    private func decodeStringArray(data: Data, offset: Int) -> [String]? {
        guard offset + 32 <= data.count else { return nil }
        let count = Int(BigUInt(data[offset..<(offset + 32)]))
        let arrayBase = offset + 32
        var result: [String] = []
        for i in 0..<count {
            let offsetSlot = arrayBase + i * 32
            guard offsetSlot + 32 <= data.count else { return nil }
            let relOffset = Int(BigUInt(data[offsetSlot..<(offsetSlot + 32)]))
            let strHead = arrayBase + relOffset
            guard strHead + 32 <= data.count else { return nil }
            let strLen = Int(BigUInt(data[strHead..<(strHead + 32)]))
            let strStart = strHead + 32
            guard strStart + strLen <= data.count else { return nil }
            let strData = data[strStart..<(strStart + strLen)]
            result.append(String(data: strData, encoding: .utf8) ?? "")
        }
        
        return result
    }

    private func uuidString(from bytes32Data: Data) -> String? {
        guard bytes32Data.count >= 16 else { return nil }
        let uuidBytes = bytes32Data.prefix(16)
        var uuidT: uuid_t = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
        withUnsafeMutableBytes(of: &uuidT) { ptr in
            ptr.copyBytes(from: uuidBytes)
        }
        
        return UUID(uuid: uuidT).uuidString
    }

    func getUserChats(userAddress: String) async throws -> [String] {
        let web3 = try await web3ReadOnly()
        let contract = try messageRegistryContract(web3: web3)

        guard let ethAddr = EthereumAddress(userAddress) else {
            throw EthereumError.contractError("Неверный адрес: \(userAddress)")
        }

        guard let result = try? await contract
            .createReadOperation("getUserChats", parameters: [ethAddr] as [AnyObject])?
            .callContractMethod() else {
            return []
        }

        guard let chatIds = result["0"] as? [Data] else { return [] }
        return chatIds.map { $0.toHexString() }
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
