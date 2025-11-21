//
//  JThrowable.swift
//  JNIKit
//
//  Created by Mihael Isaev on 20.04.2025.
//

#if os(Android)
import Android
#endif
#if JNILOGS
#if canImport(Logging)
import Logging
#endif
#endif

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
/// 
/// [Learn more](https://developer.android.com/reference/java/lang/Throwable)
public struct JThrowable: Sendable, JObjectable {
    /// The globally retained reference to the `Throwable` object.
    ///
    /// This is a `jobject` pointing to a `java.lang.Throwable` or subclass.
    public var ref: JObjectBox { object.ref}
    
    /// The class wrapper representing `java.lang.Throwable`.
    ///
    /// This may be useful for introspection or re-use in `JNICache`.
    public var clazz: JClass { object.clazz }

    /// Object wrapper
    public let object: JObject

    // MARK: - Initializers
    #if os(Android)
    /// Wrap an existing local or global `jobject` reference to a Java `Throwable`.
    ///
    /// This will automatically convert it to a global reference to retain it safely.
    ///
    /// - Parameters:
    ///   - throwable: The local `jobject` to wrap
    ///   - clazz: The resolved `JClass` for `java.lang.Throwable`
    public init?(_ throwable: JObjectBox, _ clazz: JClass) {
        #if JNILOGS
        Logger.info("JThrowable.init globalRef: \(throwable.ref)")
        #endif
        self.object = JObject(throwable, clazz)
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
        _ = env.throwObject(ref.ref)
    }
    #endif

    // MARK: - Methods

    /// Appends the specified exception to the exceptions
    /// that were suppressed in order to deliver this exception.
    // TODO: implement addSuppressed(exception: JThrowable)

    /// Fills in the execution stack trace.
    // TODO: implement fillInStackTrace() -> JThrowable?

    /// Returns the cause of this throwable or null if the cause is nonexistent or unknown.
    // TODO: implement getCause() -> JThrowable?

    /// Creates a localized description of this throwable.
    // TODO: implement getLocalizedMessage() -> String

    /// Returns the detail message string of this throwable.
    // TODO: implement getMessage() -> String

    /// Provides programmatic access to the stack trace information printed by printStackTrace().
    // TODO: implement getStackTrace() -> [StackTraceElement]

    /// Returns an array containing all of the exceptions that were suppressed, typically by the try-with-resources statement, in order to deliver this exception.
    // TODO: implement getSuppressed() -> [JThrowable]
    
    /// Initializes the cause of this throwable to the specified value.
    // TODO: implement initCause(cause: JThrowable) -> JThrowable

    /// Prints this throwable and its backtrace to the standard error stream.
    // TODO: implement printStackTrace()

    /// Prints this throwable and its backtrace to the specified print writer.
    // TODO: implement printStackTrace(s: PrintWriter)

    /// Prints this throwable and its backtrace to the specified print stream.
    // TODO: implement printStackTrace(s: PrintStream)

    /// Sets the stack trace elements that will be returned by getStackTrace() and printed by printStackTrace() and related methods.
    // TODO: implement setStackTrace(stackTrace: [StackTraceElement])
}
