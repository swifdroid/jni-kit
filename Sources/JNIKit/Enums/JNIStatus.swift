//
//  JNIStatus.swift
//  JNIKit
//
//  Created by Mihael Isaev on 20.04.2025.
//

/// Represents possible return values from JNI functions.
public enum JNIStatus: Int32, Sendable {
    /// Operation completed successfully.
    case ok = 0

    /// Unknown error occurred.
    case error = -1

    /// Thread is not attached to the JVM.
    case detached = -2

    /// Unsupported JNI version.
    case version = -3

    /// Not enough memory.
    case noMemory = -4

    /// VM is already created.
    case alreadyExists = -5

    /// Invalid arguments.
    case invalid = -6

    /// Unknown status code.
    case unknown = -100

    /// Maps raw JNI return code to `JNIStatus`.
    public init(fromRawValue value: Int32) {
        self = JNIStatus(rawValue: value) ?? .unknown
    }
}
