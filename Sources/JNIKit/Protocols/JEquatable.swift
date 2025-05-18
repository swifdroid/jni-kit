//
//  JEquatable.swift
//  JNIKit
//
//  Created by Mihael Isaev on 18.05.2025.
//

import Android

/// A protocol for Java objects that can be compared using `.equals(Object)`
///
/// Conforming types must provide the underlying `jobject` reference and resolved `JClass`.
/// The `equals(_:)` method calls the Java `equals(Object)` method via JNI, allowing comparison
/// of two Java objects using their Java-side equality logic.
///
/// Typical usage:
/// ```swift
/// if await javaObj1.equals(javaObj2) {
///     print("Objects are equal based on Java semantics")
/// }
/// ```
public protocol JEquatable: Sendable {
    /// The underlying Java object reference.
    var ref: jobject { get }

    /// The resolved class reference of the Java object.
    var clazz: JClass { get }

    /// Compares this object to another Java object using Java's `equals(Object)` method.
    ///
    /// - Parameter other: Another Java object to compare with.
    /// - Returns: `true` if equal by Java semantics; otherwise, `false`.
    func equals(_ other: JObject) async -> Bool
}

extension JEquatable {
    /// Default implementation of `equals(_:)` for any conforming Java object.
    ///
    /// This uses the JNI call to invoke `equals(Object)` on the current object.
    /// The method looks up the `equals` method ID from the object's class,
    /// and then calls it with the provided argument.
    ///
    /// Note: This uses the standard Java semantics and **does not** compare pointers directly.
    public func equals(_ other: JObject) async -> Bool {
        guard
            let env = await JEnv.current(),
            let methodId = await clazz.methodId(name: "equals", signature: .init([.object("java/lang/Object")], returning: .boolean))
        else { return false }
        return env.callBooleanMethod(object: .init(ref, clazz), methodId: methodId, args: [other.jValue])
    }
}
