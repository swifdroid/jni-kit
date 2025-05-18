//
//  JObjectRefType.swift
//  JNIKit
//
//  Created by Mihael Isaev on 20.04.2025.
//

import Android

/// A Swift wrapper for `jobjectRefType`, representing the type of a Java object reference
/// (local, global, weak global, or invalid).
public struct JObjectRefType: @unchecked Sendable {
    /// The raw JNI `jobjectRefType` enum value.
    public let ref: jobjectRefType

    /// Initialize with a non-optional `jobjectRefType`.
    public init(_ ref: jobjectRefType) {
        self.ref = ref
    }

    /// Initialize from an optional JNI reference type.
    /// Returns `nil` if the passed pointer is nil.
    public init?(_ ref: jobjectRefType?) {
        guard let ref else { return nil }
        self.ref = ref
    }
}