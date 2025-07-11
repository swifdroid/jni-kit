//
//  JObjectRefType.swift
//  JNIKit
//
//  Created by Mihael Isaev on 20.04.2025.
//

#if os(Android)
import Android
#endif

/// A Swift wrapper for `jobjectRefType`, representing the type of a Java object reference
/// (local, global, weak global, or invalid).
public struct JObjectRefType: @unchecked Sendable {
    #if os(Android)
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
    #endif

    /// Swift-style enum representing the type of reference.
    public enum Kind: String, Sendable, CustomStringConvertible {
        case invalid = "Invalid"
        case local = "Local"
        case global = "Global"
        case weakGlobal = "WeakGlobal"
        case unknown = "Unknown"

        public var description: String { rawValue }
    }

    /// Determine the kind of reference.
    public var kind: Kind {
        #if os(Android)
        switch ref {
        case JNIInvalidRefType: return .invalid
        case JNILocalRefType: return .local
        case JNIGlobalRefType: return .global
        case JNIWeakGlobalRefType: return .weakGlobal
        default: return .unknown
        }
        #else
        return .unknown
        #endif
    }

    /// Human-readable description of the reference type.
    public var description: String { kind.description }

    /// Whether this is a local reference.
    public var isLocal: Bool { kind == .local }

    /// Whether this is a global reference.
    public var isGlobal: Bool { kind == .global }

    /// Whether this is a weak global reference.
    public var isWeakGlobal: Bool { kind == .weakGlobal }

    /// Whether this is an invalid reference.
    public var isInvalid: Bool { kind == .invalid }
}
