//
//  JNIKit.swift
//  JNIKit
//
//  Created by Mihael Isaev on 20.04.2025.
//

import Android
import Logging

/// A globally accessible singleton that manages the JVM and thread attachment for JNI operations.
///
/// `JNIKit` provides an ergonomic and thread-safe bridge to the Java Virtual Machine (JVM)
/// and allows Swift code to access the appropriate `JNIEnv*` for the current thread.
///
/// Use this actor to:
/// - Initialize the JNI context using the `JavaVM*` pointer.
/// - Attach the current thread to obtain `JNIEnv*`.
/// - Detach threads if needed (optional).
///
/// It ensures consistent JNI usage and avoids repeated calls to `AttachCurrentThread` manually.
public final class JNIKit: @unchecked Sendable {
    /// Singleton instance of `JNIKit` used throughout the application.
    public static let shared = JNIKit()

    /// Reference to the global Java Virtual Machine.
    ///
    /// Set via `initialize(with:)` and required for all JNI interactions.
    public private(set) var vm: JVM!

    private var isInitialized = false

    private var jvmMutex = pthread_mutex_t()

    public var logger = Logger(label: "")

    public static var logger: Logger { shared.logger }

    /// Private initializer to enforce singleton usage.
    private init() {
        jvmMutex.activate(recursive: true)
    }

    deinit {
        jvmMutex.destroy()
    }

    /// Initialize the JNI context with the `JavaVM` pointer.
    ///
    /// This method must be called once (typically from `JNI_OnLoad`) to allow JNI access
    /// from Swift code on any thread.
    ///
    /// - Parameter vm: The `JavaVM` pointer provided by the JNI environment.
    public func initialize(with vm: JVM) {
        jvmMutex.lock()
        defer { jvmMutex.unlock() }
        guard !isInitialized else { return }
        self.vm = vm
    }

    /// Attach the current thread to the JVM and get a wrapped `JNIEnv*`.
    ///
    /// This ensures thread-local access to JNI methods and must be used before any JNI operations.
    ///
    /// - Returns: A `JEnv` wrapper around the attached `JNIEnv*`, or `nil` if the operation fails.
    public func attachCurrentThread() -> JEnv? {
        vm.attachCurrentThread()
    }

    /// Detach the current thread from the JVM.
    ///
    /// Typically not required unless you are managing threads manually.
    /// Useful for cleaning up in background threads or long-lived native tasks.
    public func detachCurrentThread() {
        vm.detachCurrentThread()
    }
}