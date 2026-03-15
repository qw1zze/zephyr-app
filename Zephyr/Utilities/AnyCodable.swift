//
//  AnyCodable.swift
//  Zephyr
//
//  Created by Dmitriy Kalyakin on 14/3/26.
//

import Foundation

enum AnyCodable: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case object([String: AnyCodable])
    case array([AnyCodable])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let v = try? container.decode(Bool.self) {
            self = .bool(v)
            return
        }
        
        if let v = try? container.decode(Int.self) {
            self = .int(v)
            return
        }
        
        if let v = try? container.decode(Double.self) {
            self = .double(v)
            return
        }
        
        if let v = try? container.decode(String.self) {
            self = .string(v)
            return
        }
        
        if let v = try? container.decode([String: AnyCodable].self) {
            self = .object(v)
            return
        }
        
        if let v = try? container.decode([AnyCodable].self) {
            self = .array(v)
            return
        }
        
        if container.decodeNil() {
            self = .null
            return
        }
        
        throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "unsupported type"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .string(let v):
            try container.encode(v)
        case .int(let v):
            try container.encode(v)
        case .double(let v):
            try container.encode(v)
        case .bool(let v):
            try container.encode(v)
        case .object(let v):
            try container.encode(v)
        case .array(let v):
            try container.encode(v)
        case .null:
            try container.encodeNil()
        }
    }
    
    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        let data = try JSONEncoder().encode(self)
        return try JSONDecoder().decode(T.self, from: data)
    }
}
