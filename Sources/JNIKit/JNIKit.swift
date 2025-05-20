//
//  JNIKit.swift
//  JNIKit
//
//  Created by Mihael Isaev on 20.04.2025.
//

import Android
import Logging

/// A globally accessible singleton that manages the Java Virtual Machine (JVM) and provides thread-safe
/// access to JNI operations in a Swift application.
///
/// `JNIKit` allows Swift code to reliably access the appropriate `JNIEnv*` for the current thread,
/// which is required for all JNI interactions. It also provides consistent logging behavior integrated
/// with Android's logcat output.
///
/// ## Responsibilities
/// - Holds the global `JavaVM*` reference.
/// - Attaches and detaches threads from the JVM as needed.
/// - Ensures `JNIEnv*` access is isolated per thread (as required by JNI).
/// - Manages log level and output using Swift's `Logger`, compatible with Android.
/// 
/// ## Usage
/// Call `JNIKit.shared.initialize(with:)` exactly once when the app launches (typically via `JNI_OnLoad`
/// or the `@_cdecl("...")` entry point). After that, use `attachCurrentThread()` anywhere you need access
/// to JNI from Swift.
///
/// - Note: This class is `@unchecked Sendable` because it contains mutex-protected state.
public final class JNIKit: @unchecked Sendable {
    /// Singleton instance of `JNIKit` used throughout the application.
    public static let shared = JNIKit()

    // MARK: - JVM Reference

    /// The reference to the global `JavaVM` instance.
    ///
    /// This must be initialized exactly once via `initialize(with:)` and is required
    /// to attach Swift threads to the JVM and obtain their `JNIEnv*`.
    ///
    /// - Warning: Accessing this before calling `initialize(with:)` results in undefined behavior.
    public private(set) var vm: JVM!

    // MARK: - Internal State

    private var isInitialized = false

    /// Mutex used to ensure thread-safe access to `vm` during initialization.
    private var jvmMutex = pthread_mutex_t()

    /// Mutex used to protect access to the logger's log level.
    private var logLevelMutex = pthread_mutex_t()

    // MARK: - Logging

    /// The global logger instance used for all JNIKit operations.
    ///
    /// This logger writes to Android's logging system (e.g., `Log.i`, `Log.e`).
    public var logger = Logger(label: "")

    /// Accessor to the global logger for static contexts.
    public static var logger: Logger { shared.logger }

    // MARK: - Lifecycle

    /// Private initializer to enforce singleton usage.
    private init() {
        jvmMutex.activate(recursive: true)
        logLevelMutex.activate(recursive: true)
    }

    deinit {
        jvmMutex.destroy()
        logLevelMutex.destroy()
    }

    // MARK: - Initialization

    /// Initialize the JNI context with the `JavaVM` pointer.
    ///
    /// This method must be called once (typically from `JNI_OnLoad`) to allow JNI access
    /// from Swift code on any thread.
    ///
    /// - Parameter vm: The `JavaVM` pointer provided by the JNI environment.
    ///
    /// - Note: This method is thread-safe and prevents reinitialization.
    public func initialize(with vm: JVM) {
        jvmMutex.lock()
        defer { jvmMutex.unlock() }
        guard !isInitialized else { return }
        self.vm = vm
    }

    /// Initialize the JNI context with the `JavaVM` pointer.
    ///
    /// This method must be called once (typically from `JNI_OnLoad`) to allow JNI access
    /// from Swift code on any thread.
    ///
    /// - Parameter vm: The `JavaVM` pointer provided by the JNI environment.
    ///
    /// - Note: This method is thread-safe and prevents reinitialization.
    public static func initialize(with vm: JVM) {
        shared.initialize(with: vm)
    }

    // MARK: - Logging Control

    /// Sets the current log level for the `logger` instance.
    ///
    /// This allows dynamic control of verbosity for JNIKit logs.
    ///
    /// - Parameter level: The minimum `Logger.Level` required for messages to be emitted.
    public func setLogLevel(_ level: Logger.Level) {
        logLevelMutex.lock()
        defer { logLevelMutex.unlock() }
        logger.logLevel = level
    }

    /// Sets the current log level for the `logger` instance.
    ///
    /// This allows dynamic control of verbosity for JNIKit logs.
    ///
    /// - Parameter level: The minimum `Logger.Level` required for messages to be emitted.
    public static func setLogLevel(_ level: Logger.Level) {
        shared.setLogLevel(level)
    }

    // MARK: - Thread Attachment

    /// Attaches the current thread to the JVM and returns a `JEnv` wrapper for JNI calls.
    ///
    /// This is required before making any JNI calls from Swift on that thread.
    /// JNI mandates that `JNIEnv*` is thread-local and must be acquired per-thread.
    ///
    /// - Returns: A `JEnv` instance containing the `JNIEnv*`, or `nil` if the operation fails.
    ///
    /// - Important: This must be called before using any JNI functions, or undefined behavior may occur.
    /// - Note: The returned `JEnv` should be considered valid only for the current thread.
    public func attachCurrentThread() -> JEnv? {
        vm.attachCurrentThread()
    }

    /// Attaches the current thread to the JVM and returns a `JEnv` wrapper for JNI calls.
    ///
    /// This is required before making any JNI calls from Swift on that thread.
    /// JNI mandates that `JNIEnv*` is thread-local and must be acquired per-thread.
    ///
    /// - Returns: A `JEnv` instance containing the `JNIEnv*`, or `nil` if the operation fails.
    ///
    /// - Important: This must be called before using any JNI functions, or undefined behavior may occur.
    /// - Note: The returned `JEnv` should be considered valid only for the current thread.
    public static func attachCurrentThread() -> JEnv? {
        shared.attachCurrentThread()
    }

    /// Detaches the current thread from the JVM.
    ///
    /// This is generally optional but can be useful when managing your own background threads,
    /// native callbacks, or long-lived Swift coroutines that interact with JNI.
    ///
    /// - Note: Do not call this from the main UI thread or any thread that the JVM does not expect to be detached.
    public func detachCurrentThread() {
        vm.detachCurrentThread()
    }

    /// Detaches the current thread from the JVM.
    ///
    /// This is generally optional but can be useful when managing your own background threads,
    /// native callbacks, or long-lived Swift coroutines that interact with JNI.
    ///
    /// - Note: Do not call this from the main UI thread or any thread that the JVM does not expect to be detached.
    public static func detachCurrentThread() {
        shared.detachCurrentThread()
    }
}