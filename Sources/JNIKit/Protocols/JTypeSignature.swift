//
//  JTypeSignature.swift
//  JNIKit
//
//  Created by Mihael Isaev on 20.04.2025.
//

/// Represents a type that has a JNI type signature (used in method or field declarations)
public protocol JTypeSignature: Sendable {
    /// JNI-compliant signature string (e.g. `I`, `Ljava/lang/String;`, `[F`)
    var signature: String { get }

    /// Fully qualified class name for object types
    var className: String { get }

    /// Whether this is an object or array-of-object type
    var isObject: Bool { get }
}