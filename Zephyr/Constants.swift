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
    static let RPCURL = "https://0xrpc.io/hoodi"

    static let keyRegistryAddress = "0xf6Ae9950F3a70664f47D9C308ceCF53F5C5cEF65"
    static let messageRegistryAddress = "0xc6Ba133C2D1bb807f81C639685b4a0585e1ff0Db"

    static let messageRegistryABI = """
    [
      {
        "name": "createChat",
        "type": "function",
        "inputs": [
          {"name": "chatId", "type": "bytes32"},
          {"name": "recipients", "type": "address[]"}
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
        "name": "getChatParticipants",
        "type": "function",
        "inputs": [{"name": "chatId", "type": "bytes32"}],
        "outputs": [{"name": "", "type": "address[]"}],
        "stateMutability": "view"
      },
      {
        "name": "getUserChats",
        "type": "function",
        "inputs": [{"name": "user", "type": "address"}],
        "outputs": [{"name": "", "type": "bytes32[]"}],
        "stateMutability": "view"
      },
      {
        "name": "ChatCreated",
        "type": "event",
        "inputs": [
          {"name": "chatId", "type": "bytes32", "indexed": true},
          {"name": "creator", "type": "address", "indexed": true},
          {"name": "participants", "type": "address[]", "indexed": false},
          {"name": "blockNumber", "type": "uint256", "indexed": false}
        ]
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
        "name": "setProfileCID",
        "type": "function",
        "inputs": [{"name": "cid", "type": "string"}],
        "outputs": [],
        "stateMutability": "nonpayable"
      },
      {
        "name": "profileCID",
        "type": "function",
        "inputs": [{"name": "", "type": "address"}],
        "outputs": [{"name": "", "type": "string"}],
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
      },
      {
        "name": "ProfileUpdated",
        "type": "event",
        "inputs": [
          {"name": "user", "indexed": true, "type": "address"},
          {"name": "cid", "indexed": false, "type": "string"}
        ]
      }
    ]
    """
}
