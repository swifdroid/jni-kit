//
//  JavaDescribable.swift
//  JNIKit
//
//  Created by Mihael Isaev on 20.04.2025.
//

import Android

/// A protocol for Java objects that can produce a Swift-readable string via Java's `toString()` method.
///
/// Commonly used with wrapped `Throwable`, `Object`, or any subclass that overrides `toString()`.
public protocol JavaDescribable: Sendable {
    /// The underlying `jobject` reference.
    var ref: jobject { get }

    /// The resolved class reference of the object.
    var clazz: JClass { get }

    /// Returns the result of calling Java's `toString()` on this object.
    ///
    /// - Returns: A Swift `String` produced by Java's `toString()` or `nil` on failure.
    func toString() async -> String?
}

extension JavaDescribable {
    public func toString() async -> String? {
        guard
            let env = await JEnv.current(),
            let methodId = await clazz.methodId(name: "toString", signature: .returning(.object, "java/lang/String")),
            let jstr = env.callObjectMethod(object: .init(ref, clazz), methodId: methodId, args: []),
            let jstring = await JString(from: jstr.ref)
        else { return nil }
        return await jstring.toSwiftString()
    }
}