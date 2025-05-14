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

extension JEnv {
    /// Convenience helper to get `JNIEnvWrapper` for the current thread using the stored `JavaVM`.
    ///
    /// This safely attaches the current thread to the JVM and returns a wrapped `JNIEnv` pointer.
    public static func current() async -> JEnv? {
        guard let vm = await JNIKit.shared.vm else { return nil }
        return vm.attachCurrentThread()
    }
}
