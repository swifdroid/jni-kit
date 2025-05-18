//
//  JObjectRefType.swift
//  JNIKit
//
//  Created by Mihael Isaev on 20.04.2025.
//

import Android

public struct JObjectRefType: @unchecked Sendable {
    public let ref: jobjectRefType
    
    public init(_ ref: jobjectRefType) {
        self.ref = ref
    }

    /// Convenient overload for optional `id`
    public init?(_ ref: jobjectRefType?) {
        guard let ref else { return nil }
        self.ref = ref
    }
}