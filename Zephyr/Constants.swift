//
//  KeychainServiceMock.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 13/3/26.
//

import Foundation

enum Constants {
    
    static let RPCURL = "https://ethereum-hoodi-rpc.publicnode.com"

    static let keyRegistryAddress = "0x4B948B5B31485F4069F48090cA7ac48B4FcD1EB4"

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
          {"name": "user",        "indexed": true,  "type": "address"},
          {"name": "publicKey",   "indexed": false, "type": "bytes"},
          {"name": "blockNumber", "indexed": false, "type": "uint256"}
        ]
      }
    ]
    """
}
