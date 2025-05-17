//
//  JString.swift
//  JNIKit
//
//  Created by Mihael Isaev on 20.04.2025.
//

import Android

/// A Swift wrapper around a Java `java.lang.String` object.
public struct JString: @unchecked Sendable, JavaDescribable {
    /// The underlying global `jstring` reference.
    public let ref: jstring

    /// The `JClass` representing `java.lang.String`.
    public static let className: JClassName = "java/lang/String"

    /// Internal cached class reference.
    public let clazz: JClass

    // MARK: - Initializers

    /// Construct from a Swift `String`, creating a new Java string.
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

    /// Wrap an existing `jstring` and globalize it.
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

    /// Convert Java string to Swift `String`.
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

    // MARK: - Instance Methods

    /// Call `length()` on the Java string.
    public func length() async -> Int {
        guard
            let env = await JEnv.current(),
            let methodId = await clazz.methodId(name: "length", signature: .returning(.int))
        else { return 0 }
        return Int(env.callIntMethod(object: .init(ref, clazz), methodId: methodId, args: []))
    }

    /// Call `toUpperCase()` on the Java string.
    public func toUpperCase() async -> JString? {
        guard
            let env = await JEnv.current(),
            let methodId = await clazz.methodId(name: "toUpperCase", signature: .returning(.init(.object, "java/lang/String"))),
            let result = env.callObjectMethod(object: .init(ref, clazz), methodId: methodId, args: [])
        else { return nil }
        return await JString(from: result.ref.assumingMemoryBound(to: jstring.self))
    }

    // TODO: more methods
}