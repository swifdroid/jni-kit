//
//  JHashable.swift
//  JNIKit
//
//  Created by Mihael Isaev on 18.05.2025.
//

import Android

/// A protocol for Java objects that expose the `hashCode()` method for use in hashing and equality.
///
/// This mirrors Java’s `Object.hashCode()` behavior and is applicable to any Java object,
/// including collections, strings, and custom types that override `hashCode()` for hash-based lookups.
///
/// Conforming Swift types can call `.hashCode()` to get the 32-bit hash value assigned by the Java object.
///
/// Example usage:
/// ```swift
/// let hash = await myJavaObject.hashCode()
/// print("Java hashCode is: \(hash)")
/// ```
///
/// > Note: In Java, `hashCode()` is often overridden alongside `equals()` to ensure consistent behavior
/// in hash-based collections like `HashMap`, `HashSet`, etc. You should also conform to `JEquatable`
/// if implementing both.
public protocol JHashable: Sendable {
    /// The underlying JNI reference to the Java object.
    var ref: jobject { get }

    /// The resolved `JClass` instance of the Java object.
    var clazz: JClass { get }

    /// Returns the result of calling Java’s `hashCode()` method on this object.
    ///
    /// - Returns: The 32-bit integer hash code from the Java side, or `0` if lookup fails.
    func hashCode() async -> Int32
}

extension JHashable {
    /// Default implementation of `hashCode()` using JNI call.
    ///
    /// Uses `clazz.methodId(...)` to retrieve the method ID for `hashCode()`, then
    /// calls it using `env.callIntMethod(...)`.
    ///
    /// - Returns: Java's `hashCode()` result as `Int32`, or `0` if lookup or call fails.
    public func hashCode() async -> Int32 {
        guard
            let env = await JEnv.current(),
            let methodId = await clazz.methodId(
                name: "hashCode",
                signature: .returning(.int)
            )
        else { return 0 }
        return env.callIntMethod(object: .init(ref, clazz), methodId: methodId, args: [])
    }
}
