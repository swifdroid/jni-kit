//
//  JVM.swift
//  JNIKit
//
//  Created by Mihael Isaev on 20.04.2025.
//

import Android

/// A Swift wrapper around a `JavaVM*` (the core entry point of the Java Virtual Machine).
///
/// This struct provides safe access to the JVM from Swift, enabling operations such as
/// attaching or detaching threads and retrieving the appropriate `JNIEnv*`.
///
/// Use this when you need to bridge Swift and Java in a thread-safe and lifecycle-aware way.
public struct JVM: @unchecked Sendable {
    /// A pointer to the Java Virtual Machine (`JavaVM*`), as used in JNI.
    public let ref: UnsafeMutablePointer<JavaVM?>

    // MARK: - Initializers

    /// Create a `JVM` instance by extracting the `JavaVM*` from a given `JNIEnv*`.
    ///
    /// - Parameter jni: The JNI environment pointer (`JNIEnv*`) typically passed to native methods.
    ///
    /// This constructor uses `(*env)->GetJavaVM(...)` to resolve the owning `JavaVM` for the current thread.
    public init(_ jni: UnsafeMutablePointer<JNIEnv?>) {
        var javaVM: UnsafeMutablePointer<JavaVM?>!
        _ = jni.pointee!.pointee.GetJavaVM(jni, &javaVM)
        self.ref = javaVM
    }

    /// Create a `JVM` instance directly from a `JavaVM*` pointer.
    ///
    /// - Parameter vm: A raw pointer to a valid `JavaVM` structure.
    public init(_ vm: UnsafeMutablePointer<JavaVM?>) {
        self.ref = vm
    }

    // MARK: - Thread Operations

    /// Attach the current thread to the JVM and return the associated `JNIEnv*`.
    ///
    /// - Returns: A `JEnv` instance if attachment succeeded, or `nil` if it failed.
    ///
    /// This method is the preferred way to obtain a `JNIEnv*`, because:
    /// - It works even if the current thread is already attached.
    /// - It avoids using `GetEnv` which is error-prone and less flexible.
    ///
    /// Example:
    /// ```swift
    /// if let env = jvm.attachCurrentThread() {
    ///     // Use `env` to call Java methods
    /// }
    /// ```
    public func attachCurrentThread() -> JEnv? {
        var env: UnsafeMutablePointer<JNIEnv?>?
        _ = ref.pointee?.pointee.AttachCurrentThread?(ref, &env, nil)
        return JEnv(env)
    }

    /// Detach the current thread from the JVM.
    ///
    /// This is typically used in long-running native threads that no longer need to call Java code.
    ///
    /// > Note: It is safe to call this even if the thread is already detached.
    public func detachCurrentThread() {
        _ = ref.pointee?.pointee.DetachCurrentThread?(ref)
    }
}

extension UnsafeMutablePointer where Pointee == Optional<JNIEnv> {
    /// Convenience method to extract the associated `JavaVM` from a `JNIEnv*`.
    ///
    /// This is a shorthand for:
    /// ```swift
    /// let jvm = JVM(envPointer)
    /// ```
    /// allowing usage like:
    /// ```swift
    /// let jvm = jniPointer.jvm()
    /// ```
    ///
    /// - Returns: A `JVM` wrapper around the owning `JavaVM*`.
    public func jvm() -> JVM { .init(self) }
}