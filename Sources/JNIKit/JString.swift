//
//  JString.swift
//  JNIKit
//
//  Created by Mihael Isaev on 20.04.2025.
//

import Android

/// A Swift wrapper around a Java `java.lang.String` object.
///
/// This type provides safe and ergonomic access to Java strings from Swift.
/// It manages JNI references, converts between Swift and Java strings, and supports common string operations.
public struct JString: @unchecked Sendable, JavaDescribable {
    // MARK: - Properties

    /// The globally retained JNI reference to the Java string.
    public let ref: jstring

    /// The JNI class name for `java.lang.String`.
    public static let className: JClassName = "java/lang/String"

    /// The loaded `JClass` representing `java.lang.String`.
    public let clazz: JClass

    // MARK: - Initializers

    /// Create a new Java string from a Swift `String`.
    ///
    /// This performs a JNI call to construct a new UTF-8 encoded `java.lang.String`,
    /// retains a global reference to it, and stores the associated class metadata.
    ///
    /// - Parameter swiftString: The Swift string to convert into a Java string.
    /// - Returns: `nil` if JNI operations fail or JVM is unavailable.
    public init?(from swiftString: String) async {
        guard
            let env = await JEnv.current(),
            let clazz = await JClass.load(Self.className),
            let jstr = env.newStringUTF(swiftString),
            let global = env.newGlobalRef(.init(jstr, clazz))
        else { return nil }
        self.ref = global.ref
        self.clazz = clazz
    }

    /// Wrap an existing `jstring` from JNI and promote it to a global reference.
    ///
    /// This is useful when receiving a string from Java code and you want to safely retain it.
    ///
    /// - Parameter existing: The JNI `jstring` reference to wrap.
    /// - Returns: `nil` if JVM is unavailable or the reference cannot be globalized.
    public init?(from existing: jstring) async {
        guard
            let env = await JEnv.current(),
            let clazz = await JClass.load(Self.className),
            let global = env.newGlobalRef(.init(existing, clazz))
        else { return nil }
        self.ref = global.ref
        self.clazz = clazz
    }

    // MARK: - Conversion

    /// Convert this Java string to a Swift `String`.
    ///
    /// This performs a JNI `GetStringUTFChars` operation and safely converts the result to Swift.
    /// The JNI memory is released automatically after conversion.
    ///
    /// - Returns: A native Swift string or `nil` if conversion fails.
    public func toSwiftString() async -> String? {
        guard
            let env = await JEnv.current(),
            let cstr = env.getStringUTFChars(ref)
        else { return nil }
        defer {
            env.releaseStringUTFChars(ref, chars: cstr)
        }
        return String(cString: cstr)
    }
}

// MARK: - Instance Methods

extension JString {
    /// Calls Java's `String.isEmpty()`
    public func isEmpty() async -> Bool {
        guard let env = await JEnv.current(),
              let methodId = await clazz.methodId(name: "isEmpty", signature: .returning(.boolean)) else {
            return false
        }
        return env.callBooleanMethod(object: .init(ref, clazz), methodId: methodId, args: [])
    }

    /// Calls Java's `String.length()`
    public func length() async -> Int {
        guard let env = await JEnv.current(),
              let methodId = await clazz.methodId(name: "length", signature: .returning(.int)) else {
            return 0
        }
        return Int(env.callIntMethod(object: .init(ref, clazz), methodId: methodId, args: []))
    }

    /// Calls Java's `String.toLowerCase()`
    public func toLowerCase() async -> JString? {
        await callReturningString("toLowerCase", signature: .returning(.object("java/lang/String")))
    }

    /// Calls Java's `String.toUpperCase()`
    public func toUpperCase() async -> JString? {
        await callReturningString("toUpperCase", signature: .returning(.object("java/lang/String")))
    }

    /// Calls Java's `String.trim()`
    public func trim() async -> JString? {
        await callReturningString("trim", signature: .returning(.object("java/lang/String")))
    }

    /// Calls Java's `String.concat(String)`
    public func concat(_ other: JString) async -> JString? {
        await callReturningString("concat", signature: .init(.object("java/lang/String"), returning: .object("java/lang/String")), args: [other])
    }

    /// Calls Java's `String.startsWith(String)`
    public func startsWith(_ prefix: JString) async -> Bool {
        await callBoolean("startsWith", signature: .init(.object("java/lang/String"), returning: .boolean), args: [prefix])
    }

    /// Calls Java's `String.endsWith(String)`
    public func endsWith(_ suffix: JString) async -> Bool {
        await callBoolean("endsWith", signature: .init(.object("java/lang/String"), returning: .boolean), args: [suffix])
    }

    /// Calls Java's `String.equals(Object)`
    public func equals(_ other: JString) async -> Bool {
        await callBoolean("equals", signature: .init(.object("java/lang/Object"), returning: .boolean), args: [other])
    }

    /// Calls Java's `String.contains(CharSequence)`
    public func contains(_ sequence: JString) async -> Bool {
        await callBoolean("contains", signature: .init(.object("java/lang/CharSequence"), returning: .boolean), args: [sequence])
    }

    /// Calls Java's `String.replace(CharSequence, CharSequence)`
    public func replace(old: JString, with new: JString) async -> JString? {
        await callReturningString("replace", signature: .init(.object("java/lang/CharSequence"), .object("java/lang/CharSequence"), returning: .object("java/lang/String")), args: [old, new])
    }

    /// Calls Java's `String.equalsIgnoreCase(String)`
    public func equalsIgnoreCase(_ other: JString) async -> Bool {
        await callBoolean("equalsIgnoreCase", signature: .init(.object("java/lang/String"), returning: .boolean), args: [other])
    }

    // MARK: - Helpers

    private func callReturningString(_ name: String, signature: JMethodSignature, args: [JString] = []) async -> JString? {
        guard
            let env = await JEnv.current(),
            let methodId = await clazz.methodId(name: name, signature: signature)
        else { return nil }
        let jvalues = args.map { $0.jValue }
        guard let object = env.callObjectMethod(object: .init(ref, clazz), methodId: methodId, args: jvalues) else { return nil }
        return await JString(from: object.ref.assumingMemoryBound(to: jstring.self))
    }

    private func callBoolean(_ name: String, signature: JMethodSignature, args: [JString]) async -> Bool {
        guard
            let env = await JEnv.current(),
            let methodId = await clazz.methodId(name: name, signature: signature)
        else { return false }
        let jvalues = args.map { $0.jValue }
        return env.callBooleanMethod(object: .init(ref, clazz), methodId: methodId, args: jvalues)
    }
}
