//
//  JThrowable.swift
//  JNIKit
//
//  Created by Mihael Isaev on 20.04.2025.
//

import Android

/// A Swift wrapper around a Java `Throwable` (`java.lang.Throwable`) object.
///
/// This wrapper retains a global reference to the underlying `jobject` to prevent it from
/// being garbage collected while referenced from Swift. It allows safe usage of
/// exceptions caught or constructed via JNI.
///
/// ### Use cases:
/// - Wrapping a thrown Java exception from `ExceptionOccurred()`
/// - Passing Java exceptions back to Swift for logging or message extraction
/// - Re-throwing Java exceptions from Swift via `Throw()` or `ThrowNew()`
public struct JThrowable: @unchecked Sendable, JObjectable {
    /// The globally retained reference to the `Throwable` object.
    ///
    /// This is a `jobject` pointing to a `java.lang.Throwable` or subclass.
    public let ref: jobject

    /// The class wrapper representing `java.lang.Throwable`.
    ///
    /// This may be useful for introspection or re-use in `JNICache`.
    public let clazz: JClass

    // MARK: - Initializers

    /// Wrap an existing local or global `jobject` reference to a Java `Throwable`.
    ///
    /// This will automatically convert it to a global reference to retain it safely.
    ///
    /// - Parameters:
    ///   - throwable: The local `jobject` to wrap
    ///   - clazz: The resolved `JClass` for `java.lang.Throwable`
    public init?(_ throwable: jthrowable, _ clazz: JClass) {
        guard
            let env = JEnv.current(),
            let global = env.newGlobalRef(JObject(throwable, clazz))
        else { return nil }
        self.ref = global.ref
        self.clazz = clazz
    }

    // MARK: - Factory

    /// Wrap the current exception from the JVM if one has occurred.
    ///
    /// This is useful after calling any JNI function to check and retrieve the exception object.
    ///
    /// - Returns: A `JThrowable` if an exception is pending, otherwise `nil`.
    public static func current() -> JThrowable? {
        guard
            let env = JEnv.current(),
            let throwable = env.exceptionOccurred(),
            let clazz = JClass.load("java/lang/Throwable")
        else { return nil }
        return JThrowable(throwable.ref, clazz)
    }

    /// Re-throw this Java exception back into the JVM.
    ///
    /// This is equivalent to calling `Throw(this.ref)` from JNI.
    public func rethrow() {
        guard let env = JEnv.current() else { return }
        _ = env.throwObject(ref)
    }
}
