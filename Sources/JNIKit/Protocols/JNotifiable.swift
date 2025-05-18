//
//  JNotifiable.swift
//  JNIKit
//
//  Created by Mihael Isaev on 18.05.2025.
//

import Android

/// A protocol for Java objects that support thread notification via `notify()` and `notifyAll()` methods.
///
/// These methods are defined in `java.lang.Object` and are available on all Java objects.
/// They are typically used within a `synchronized` block to wake up one or more threads
/// that are waiting on the object’s monitor (i.e., via `wait()`).
///
/// > ⚠️ **Important:** In Java, calling `notify()` or `notifyAll()` **without holding the object's monitor**
/// results in a `java.lang.IllegalMonitorStateException`. Ensure your JNI code respects this contract.
///
/// Example usage:
/// ```swift
/// try await myJavaObject.notify()
/// try await myJavaObject.notifyAll()
/// ```
///
/// These calls correspond to:
/// ```java
/// synchronized(obj) {
///     obj.notify(); // or obj.notifyAll();
/// }
/// ```
public protocol JNotifiable: Sendable {
    /// The raw JNI object reference.
    var ref: jobject { get }

    /// The resolved class of the object.
    var clazz: JClass { get }
}

extension JNotifiable {
    /// Calls Java’s `notify()` method on this object.
    ///
    /// Wakes up a single thread that is waiting on this object’s monitor (via `wait()`).
    /// If no threads are waiting, nothing happens.
    ///
    /// - Note: Must be called while holding the monitor on this object.
    /// - SeeAlso: [Java API: Object.notify()](https://docs.oracle.com/javase/8/docs/api/java/lang/Object.html#notify--)
    public func notify() async {
        guard
            let env = await JEnv.current(),
            let methodId = await clazz.methodId(
                name: "notify",
                signature: .returning(.void)
            )
        else { return }
        env.callVoidMethod(object: .init(ref, clazz), methodId: methodId, args: [])
    }

    /// Calls Java’s `notifyAll()` method on this object.
    ///
    /// Wakes up **all** threads that are currently waiting on this object’s monitor.
    /// Each thread will compete to reacquire the monitor before continuing.
    ///
    /// - Note: Must be called while holding the monitor on this object.
    /// - SeeAlso: [Java API: Object.notifyAll()](https://docs.oracle.com/javase/8/docs/api/java/lang/Object.html#notifyAll--)
    public func notifyAll() async {
        guard
            let env = await JEnv.current(),
            let methodId = await clazz.methodId(
                name: "notifyAll",
                signature: .returning(.void)
            )
        else { return }
        env.callVoidMethod(object: .init(ref, clazz), methodId: methodId, args: [])
    }
}
