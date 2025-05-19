//
//  JObject.swift
//  JNIKit
//
//  Created by Mihael Isaev on 13.01.2022.
//

import Android
import FoundationEssentials

/// A Swift wrapper around a global `jobject`, retained safely across threads and JNI calls.
///
/// Use `JObject` to represent any Java object passed from or constructed in Swift.
/// It retains a global reference automatically to prevent premature GC.
public struct JObject: @unchecked Sendable, JObjectable {
    /// The globally retained reference to the Java object.
    public let ref: jobject

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
    public static func newInstance(className: JClassName, constructorSignature: JMethodSignature, args: [jvalue]) -> JObject? {
        guard
            let env = JEnv.current(),
            let clazz = JClass.load(className),
            let methodId = clazz.methodId(name: "<init>", signature: constructorSignature),
            let local = env.newObject(clazz: clazz, constructor: methodId, args: args),
            let global = env.newGlobalRef(local)
        else { return nil }
        return JObject(global.ref, clazz)
    }

    // MARK: - Call Instance Methods

    /// Call an instance method on this object.
    public func callObjectMethod(name: String, signature: JMethodSignature, args: [jvalue]) -> JObject? {
        guard
            let env = JEnv.current(),
            let methodId = clazz.methodId(name: name, signature: signature)
        else { return nil }
        return env.callObjectMethod(object: self, methodId: methodId, args: args)
    }

    /// Call an instance method returning `jint`
    public func callIntMethod(name: String, signature: JMethodSignature, args: [jvalue]) -> Int32? {
        guard
            let env = JEnv.current(),
            let methodId = clazz.methodId(name: name, signature: signature)
        else { return nil }
        return env.callIntMethod(object: self, methodId: methodId, args: args)
    }

    /// Call an instance method returning `void`
    public func callVoidMethod(name: String, signature: JMethodSignature, args: [jvalue]) {
        guard
            let env = JEnv.current(),
            let methodId = clazz.methodId(name: name, signature: signature)
        else { return }
        env.callVoidMethod(object: self, methodId: methodId, args: args)
    }
}

/// A lightweight wrapper for a raw `jobject`, allowing type-safe conversions and introspection.
///
/// Use `JObjectBox` when you have an opaque `jobject` pointer (e.g., from callbacks or native code)
/// and want to convert it into a proper `JObject` using runtime reflection.
public struct JObjectBox: @unchecked Sendable {
    /// The raw JNI object reference (local or global).
    public let object: jobject

    /// Initialize a box from a `jobject` reference.
    /// - Parameter object: A valid JNI object pointer.
    public init(_ object: jobject) {
        self.object = object
    }
}

extension jobject {
    /// Wrap this `jobject` in a `JObjectBox` for conversion or inspection.
    /// - Returns: A `JObjectBox` containing this reference.
    public func box() -> JObjectBox {
        JObjectBox(self)
    }
}

extension JObjectBox {
    /// Convert the boxed `jobject` into a fully typed `JObject` by inspecting its runtime class.
    ///
    /// This method calls `GetObjectClass` and then uses reflection to invoke `getName()`,
    /// obtaining the full class name of the object.
    ///
    /// - Returns: A `JObject` with resolved `JClass`, or `nil` if reflection fails.
    public func object() async -> JObject? {
        // Attach current thread to get JNIEnv*
        guard
            let env = await JNIKit.shared.attachCurrentThread(),
            let classClass = env.env.pointee?.pointee.GetObjectClass?(env.env, self.object),
            let getNameId = env.env.pointee?.pointee.GetMethodID?(
                env.env,
                classClass,
                "getName",
                "()Ljava/lang/String;"
            )
        else { return nil }
        var value: jvalue! = nil
        // Call getName() on the java.lang.Class object to get the internal name
        guard
            let nameObj = env.env.pointee?.pointee.CallObjectMethodA?(
                env.env,
                classClass,
                getNameId,
                &value
            ),
            let javaString = await JString(from: nameObj),
            let name = await javaString.toSwiftString()
        else { return nil }
        // Convert dot-style name to slash format if needed (e.g., java.lang.String → java/lang/String)
        let className = JClassName(stringLiteral: name.components(separatedBy: ".").joined(separator: "/"))
        return JObject(self.object, .init(classClass, className))
    }
}
