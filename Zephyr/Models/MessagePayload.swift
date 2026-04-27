//
//  MessagePayload.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 16/3/26.
//

import Foundation

struct MessagePayload: Codable {
    let type: String
    let text: String?
    let imageBase64: String?
    let fileBase64: String?
    let fileName: String?

    static func makeText(_ content: String) -> MessagePayload {
        MessagePayload(type: "text", text: content, imageBase64: nil, fileBase64: nil, fileName: nil)
    }

    static func makeImage(_ data: Data) -> MessagePayload {
        MessagePayload(type: "image", text: nil, imageBase64: data.base64EncodedString(), fileBase64: nil, fileName: nil)
    }

    static func makeFile(_ data: Data, fileName: String) -> MessagePayload {
        MessagePayload(type: "file", text: nil, imageBase64: nil, fileBase64: data.base64EncodedString(), fileName: fileName)
    }

    var imageData: Data? {
        guard type == "image", let b64 = imageBase64 else { return nil }
        return Data(base64Encoded: b64)
    }

    var fileData: Data? {
        guard type == "file", let b64 = fileBase64 else { return nil }
        return Data(base64Encoded: b64)
    }
}
