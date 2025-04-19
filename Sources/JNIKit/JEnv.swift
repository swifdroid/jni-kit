//
//  JEnv.swift
//  JNIKit
//
//  Created by Mihael Isaev on 13.01.2022.
//

import Android

/// A safe and ergonomic wrapper around `JNIEnv*` for use in Swift 6.1+
///
/// This wrapper hides unsafe pointer access and provides convenience methods for
/// working with Java classes, methods, fields, strings, and objects.
public struct JEnv: @unchecked Sendable {
    /// The raw JNI environment pointer (thread-local)
    public let env: UnsafeMutablePointer<JNIEnv?>

    public init(_ env: UnsafeMutablePointer<JNIEnv?>) {
        self.env = env
    }

    public init?(_ env: UnsafeMutablePointer<JNIEnv?>?) {
        guard let env else { return nil }
        self.env = env
    }
}

