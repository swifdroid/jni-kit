//
//  JWaitable.swift
//  JNIKit
//
//  Created by Mihael Isaev on 18.05.2025.
//

#if os(Android)
import Android
#endif

/// A protocol for Java objects that support synchronization via the `wait()` methods from `java.lang.Object`.
///
/// All Java objects inherit these methods, which are used in multithreaded environments
/// to temporarily pause execution and coordinate thread communication using `synchronized` blocks.
///
/// This protocol allows Swift code to interact with Java's monitor methods safely and idiomatically.
public protocol JWaitable: Sendable {
    /// The underlying JNI object reference (typically a global or local `jobject`).
    var ref: JObjectBox { get }
    
    /// The resolved Java class reference for this object.
    var clazz: JClass { get }
}

extension JWaitable {
    /// Call Java’s `wait()` method to pause the current thread until it is notified or interrupted.
    ///
    /// Equivalent to `this.wait()` in Java, this must be called from within a `synchronized` context in Java,
    /// or a `java.lang.IllegalMonitorStateException` will be thrown.
    ///
    /// - Note: This call may block indefinitely unless `notify()` or `notifyAll()` is called on the same object.
    public func wait() {
        #if os(Android)
        guard
            let env = JEnv.current(),
            let methodId = clazz.methodId(
                name: "wait",
                signature: .returning(.void)
            )
        else { return }
        env.callVoidMethod(object: .init(ref, clazz), methodId: methodId, args: [])
        #endif
    }

    #if os(Android)
    /// Call Java’s `wait(long millis)` method to pause the current thread for up to a specified time.
    ///
    /// This form waits until either:
    /// - The specified timeout (in milliseconds) elapses.
    /// - Another thread calls `notify()` or `notifyAll()` on this object.
    ///
    /// - Parameter timeoutMillis: The maximum time to wait in milliseconds.
    public func wait(timeoutMillis: jlong) {
        guard
            let env = JEnv.current(),
            let methodId = clazz.methodId(
                name: "wait",
                signature: .init(.long, returning: .void)
            )
        else { return }
        env.callVoidMethod(object: .init(ref, clazz), methodId: methodId, args: [timeoutMillis])
    }

    /// Call Java’s `wait(long millis, int nanos)` method to wait with nanosecond precision.
    ///
    /// This method allows fine-grained control over the wait duration.
    /// It behaves the same as `wait(long)` but includes additional nanoseconds (0–999999).
    ///
    /// - Parameters:
    ///   - timeoutMillis: Number of milliseconds to wait.
    ///   - nanos: Additional nanoseconds (0–999999).
    public func wait(timeoutMillis: jlong, nanos: jint) {
        guard
            let env = JEnv.current(),
            let methodId = clazz.methodId(
                name: "wait",
                signature: .init(.long, .int, returning: .void)
            )
        else { return }
        env.callVoidMethod(object: .init(ref, clazz), methodId: methodId, args: [timeoutMillis, nanos])
    }
    #endif
}
