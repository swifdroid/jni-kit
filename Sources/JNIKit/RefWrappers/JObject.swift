//
//  JObject.swift
//  JNIKit
//
//  Created by Mihael Isaev on 13.01.2022.
//

import Android

/// A Swift wrapper around a global `jobject`, retained safely across threads and JNI calls.
///
/// Use `JObject` to represent any Java object passed from or constructed in Swift.
/// It retains a global reference automatically to prevent premature GC.
public struct JObject: @unchecked Sendable, JavaDescribable {
    /// The globally retained reference to the Java object.
    public let ref: jobject

    /// The class name of the Java object (e.g. `"java/lang/String"`).
    public var className: JClassName { clazz.name }

    /// The resolved `JClass` of this object.
    public let clazz: JClass

    // MARK: - Init

    /// Wrap an existing `jobject` by creating a global reference.
    /// - Parameters:
    ///   - ref: The local or global `jobject`
    ///   - className: The Java class name in JNI format (e.g. `"java/lang/String"`)
    ///   - clazz: The resolved `JClass` wrapper
    public init(_ ref: jobject, _ clazz: JClass) {
        self.ref = ref
        self.clazz = JClass(clazz.ref, clazz.name)
    }

    /// Convenient overload for optional `ref` and `clazz`
    public init?(_ ref: jobject?, _ clazz: JClass?) {
        guard let ref, let clazz else { return nil }
        self.ref = ref
        self.clazz = JClass(clazz.ref, clazz.name)
    }

    /// Create from class name and a constructor method.
    public static func newInstance(className: JClassName, constructorSignature: JMethodSignature, args: [jvalue]) async -> JObject? {
        guard
            let env = await JEnv.current(),
            let clazz = await JClass.load(className),
            let methodId = await clazz.methodId(name: "<init>", signature: constructorSignature),
            let local = env.newObject(clazz: clazz, constructor: methodId, args: args),
            let global = env.newGlobalRef(local)
        else {
            return nil
        }
        return JObject(global.ref, clazz)
    }

    // MARK: - Call Instance Methods

    /// Call an instance method on this object.
    public func callObjectMethod(name: String, signature: JMethodSignature, args: [jvalue]) async -> JObject? {
        guard
            let env = await JEnv.current(),
            let methodId = await clazz.methodId(name: name, signature: signature)
        else { return nil }
        return env.callObjectMethod(object: self, methodId: methodId, args: args)
    }

    /// Call an instance method returning `jint`
    public func callIntMethod(name: String, signature: JMethodSignature, args: [jvalue]) async -> Int32? {
        guard
            let env = await JEnv.current(),
            let methodId = await clazz.methodId(name: name, signature: signature)
        else { return nil }
        return env.callIntMethod(object: self, methodId: methodId, args: args)
    }

    /// Call an instance method returning `void`
    public func callVoidMethod(name: String, signature: JMethodSignature, args: [jvalue]) async {
        guard
            let env = await JEnv.current(),
            let methodId = await clazz.methodId(name: name, signature: signature)
        else { return }
        env.callVoidMethod(object: self, methodId: methodId, args: args)
    }
}

public struct JObjectBox: @unchecked Sendable {
    public let object: jobject

    public init(_ object: jobject) {
        self.object = object
    }
}

extension jobject {
    public func box() -> JObjectBox {
        JObjectBox(self)
    }
}

extension JObjectBox {
    /// Wrapping `jobject` into `JObject`, uses reflection to get its class
    public func object() async -> JObject? {
        guard
            let env = await JNIKit.shared.attachCurrentThread(),
            let classClass = env.env.pointee?.pointee.GetObjectClass?(env.env, self.object),
            let getNameId = env.env.pointee?.pointee.GetMethodID?(env.env, classClass, "getName", "()Ljava/lang/String;")
        else { return nil }
        var value: jvalue!
        guard
            let nameObj = env.env.pointee?.pointee.CallObjectMethodA?(env.env, classClass, getNameId, &value),
            let javaString = await JStringRefWrapper(from: nameObj),
            let name = await javaString.toSwiftString()
        else { return nil }
        return .init(self.object, .init(classClass, .init(stringLiteral: name)))
    }
}