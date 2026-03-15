//
//  KeychainServiceMock.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 13/3/26.
//

import Foundation

enum Constants {

    static let relayWSURL    = "ws://localhost:8082/ws"
    static let storageBaseURL = "http://localhost:8080"
    static let RPCURL = "https://ethereum-hoodi-rpc.publicnode.com"

    static let keyRegistryAddress = "0x4B948B5B31485F4069F48090cA7ac48B4FcD1EB4"
    static let messageRegistryAddress = "0x7B296afb07fa405f979dbD08CE8ed44d2A8856E5"

    static let messageRegistryABI = """
    [
      {
        "name": "createChat",
        "type": "function",
        "inputs": [
          {"name": "chatId", "type": "bytes32"},
          {"name": "recipient", "type": "address"}
        ],
        "outputs": [],
        "stateMutability": "nonpayable"
      },
      {
        "name": "anchorBatch",
        "type": "function",
        "inputs": [
          {"name": "chatId", "type": "bytes32"},
          {"name": "messageIds", "type": "bytes32[]"},
          {"name": "cids", "type": "string[]"},
          {"name": "timestamps", "type": "uint256[]"}
        ],
        "outputs": [],
        "stateMutability": "nonpayable"
      },
      {
        "name": "getChatCreatedAtBlock",
        "type": "function",
        "inputs": [{"name": "chatId", "type": "bytes32"}],
        "outputs": [{"name": "", "type": "uint256"}],
        "stateMutability": "view"
      },
      {
        "name": "BatchAnchored",
        "type": "event",
        "inputs": [
          {"name": "chatId",      "type": "bytes32",   "indexed": true},
          {"name": "sender",      "type": "address",   "indexed": true},
          {"name": "messageIds",  "type": "bytes32[]", "indexed": false},
          {"name": "cids",        "type": "string[]",  "indexed": false},
          {"name": "timestamps",  "type": "uint256[]", "indexed": false},
          {"name": "blockNumber", "type": "uint256",   "indexed": false}
        ]
      }
    ]
    """

    static let keyRegistryABI = """
    [
      {
        "name": "publishKey",
        "type": "function",
        "inputs": [{"name": "publicKey", "type": "bytes"}],
        "outputs": [],
        "stateMutability": "nonpayable"
      },
      {
        "name": "getKey",
        "type": "function",
        "inputs": [{"name": "user", "type": "address"}],
        "outputs": [{"name": "", "type": "bytes"}],
        "stateMutability": "view"
      },
      {
        "name": "KeyPublished",
        "type": "event",
        "inputs": [
          {"name": "user", "indexed": true, "type": "address"},
          {"name": "publicKey", "indexed": false, "type": "bytes"},
          {"name": "blockNumber", "indexed": false, "type": "uint256"}
        ]
      }
    ]
    """
}
