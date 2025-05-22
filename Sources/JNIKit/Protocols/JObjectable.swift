//
//  JObjectable.swift
//  JNIKit
//
//  Created by Mihael Isaev on 23.10.2021.
//

#if os(Android)
import Android
#endif

/// A composite protocol that defines a common interface for interacting with any Java object (`jobject`) in Swift.
///
/// Once a type conforms to `JObjectable`, it automatically gains access to all
/// standard Java object methods through protocol extensions.
public protocol JObjectable: JEquatable, JGetClassable, JHashable, JNotifiable, JStringable, JWaitable {
    #if os(Android)
    /// The underlying JNI object reference.
    var ref: jobject { get }
    #endif

    /// The resolved class reference of the Java object.
    var clazz: JClass { get }

    /// The fully qualified class name of the object (e.g., `"java/lang/String"`).
    var className: JClassName { get }

    /// The wrapped Java object.
    var object: JObject { get }
}

extension JObjectable {
    /// Returns the class name of the object by accessing the `clazz.name` property.
    ///
    /// This provides a convenient default implementation based on the associated `clazz`.
    public var className: JClassName {
        #if os(Android)
        return clazz.name
        #else
        return ""
        #endif
    }
}

#if os(Android)
extension JObjectable {
    // MARK: - Instance Methods

    /// Call an instance method on this object.
    public func callObjectMethod(name: String, signature: JMethodSignature, args: [jvalue]) -> JObject? {
        guard
            let env = JEnv.current(),
            let methodId = clazz.methodId(name: name, signature: signature)
        else { return nil }
        return env.callObjectMethod(object: object, methodId: methodId, args: args)
    }

    /// Call an instance method returning `jboolean`
    public func callBoolMethod(name: String, signature: JMethodSignature, args: [jvalue]) -> Bool? {
        guard
            let env = JEnv.current(),
            let methodId = clazz.methodId(name: name, signature: signature)
        else { return nil }
        return env.callBooleanMethod(object: object, methodId: methodId, args: args)
    }

    /// Call an instance method returning `jbyte`
    public func callByteMethod(name: String, signature: JMethodSignature, args: [jvalue]) -> Int8? {
        guard
            let env = JEnv.current(),
            let methodId = clazz.methodId(name: name, signature: signature)
        else { return nil }
        return env.callByteMethod(object: object, methodId: methodId, args: args)
    }

    /// Call an instance method returning `jchar`
    public func callCharMethod(name: String, signature: JMethodSignature, args: [jvalue]) -> UInt16? {
        guard
            let env = JEnv.current(),
            let methodId = clazz.methodId(name: name, signature: signature)
        else { return nil }
        return env.callCharMethod(object: object, methodId: methodId, args: args)
    }

    /// Call an instance method returning `jdouble`
    public func callDoubleMethod(name: String, signature: JMethodSignature, args: [jvalue]) -> Double? {
        guard
            let env = JEnv.current(),
            let methodId = clazz.methodId(name: name, signature: signature)
        else { return nil }
        return env.callDoubleMethod(object: object, methodId: methodId, args: args)
    }

    /// Call an instance method returning `jfloat`
    public func callFloatMethod(name: String, signature: JMethodSignature, args: [jvalue]) -> Float? {
        guard
            let env = JEnv.current(),
            let methodId = clazz.methodId(name: name, signature: signature)
        else { return nil }
        return env.callFloatMethod(object: object, methodId: methodId, args: args)
    }
    
    /// Call an instance method returning `jint`
    public func callIntMethod(name: String, signature: JMethodSignature, args: [jvalue]) -> Int32? {
        guard
            let env = JEnv.current(),
            let methodId = clazz.methodId(name: name, signature: signature)
        else { return nil }
        return env.callIntMethod(object: object, methodId: methodId, args: args)
    }

    /// Call an instance method returning `long`
    public func callLongMethod(name: String, signature: JMethodSignature, args: [jvalue]) -> Int64? {
        guard
            let env = JEnv.current(),
            let methodId = clazz.methodId(name: name, signature: signature)
        else { return nil }
        return env.callLongMethod(object: object, methodId: methodId, args: args)
    }

    /// Call an instance method returning `void`
    public func callVoidMethod(name: String, signature: JMethodSignature, args: [jvalue]) {
        guard
            let env = JEnv.current(),
            let methodId = clazz.methodId(name: name, signature: signature)
        else { return }
        env.callVoidMethod(object: object, methodId: methodId, args: args)
    }

    // MARK: - Non-Virtual Instance Methods

    /// Call a non-virtual instance method on this object.
    public func callNonvirtualObjectMethod(name: String, signature: JMethodSignature, args: [jvalue]) -> JObject? {
        guard
            let env = JEnv.current(),
            let methodId = clazz.methodId(name: name, signature: signature)
        else { return nil }
        return env.callNonvirtualObjectMethod(object: object, clazz: clazz, methodId: methodId, args: args)
    }

    /// Call a non-virtual instance method returning `jboolean`
    public func callNonvirtualBoolMethod(name: String, signature: JMethodSignature, args: [jvalue]) -> Bool? {
        guard
            let env = JEnv.current(),
            let methodId = clazz.methodId(name: name, signature: signature)
        else { return nil }
        return env.callNonvirtualBooleanMethod(object: object, clazz: clazz, methodId: methodId, args: args)
    }

    /// Call a non-virtual instance method returning `jbyte`
    public func callNonvirtualByteMethod(name: String, signature: JMethodSignature, args: [jvalue]) -> Int8? {
        guard
            let env = JEnv.current(),
            let methodId = clazz.methodId(name: name, signature: signature)
        else { return nil }
        return env.callNonvirtualByteMethod(object: object, clazz: clazz, methodId: methodId, args: args)
    }

    /// Call a non-virtual instance method returning `jchar`
    public func callNonvirtualCharMethod(name: String, signature: JMethodSignature, args: [jvalue]) -> UInt16? {
        guard
            let env = JEnv.current(),
            let methodId = clazz.methodId(name: name, signature: signature)
        else { return nil }
        return env.callNonvirtualCharMethod(object: object, clazz: clazz, methodId: methodId, args: args)
    }

    /// Call a non-virtual instance method returning `jdouble`
    public func callNonvirtualDoubleMethod(name: String, signature: JMethodSignature, args: [jvalue]) -> Double? {
        guard
            let env = JEnv.current(),
            let methodId = clazz.methodId(name: name, signature: signature)
        else { return nil }
        return env.callNonvirtualDoubleMethod(object: object, clazz: clazz, methodId: methodId, args: args)
    }

    /// Call a non-virtual instance method returning `jfloat`
    public func callNonvirtualFloatMethod(name: String, signature: JMethodSignature, args: [jvalue]) -> Float? {
        guard
            let env = JEnv.current(),
            let methodId = clazz.methodId(name: name, signature: signature)
        else { return nil }
        return env.callNonvirtualFloatMethod(object: object, clazz: clazz, methodId: methodId, args: args)
    }
    
    /// Call a non-virtual instance method returning `jint`
    public func callNonvirtualIntMethod(name: String, signature: JMethodSignature, args: [jvalue]) -> Int32? {
        guard
            let env = JEnv.current(),
            let methodId = clazz.methodId(name: name, signature: signature)
        else { return nil }
        return env.callNonvirtualIntMethod(object: object, clazz: clazz, methodId: methodId, args: args)
    }

    /// Call a non-virtual instance method returning `long`
    public func callNonvirtualLongMethod(name: String, signature: JMethodSignature, args: [jvalue]) -> Int64? {
        guard
            let env = JEnv.current(),
            let methodId = clazz.methodId(name: name, signature: signature)
        else { return nil }
        return env.callNonvirtualLongMethod(object: object, clazz: clazz, methodId: methodId, args: args)
    }

    /// Call a non-virtual instance method returning `void`
    public func callNonvirtualVoidMethod(name: String, signature: JMethodSignature, args: [jvalue]) {
        guard
            let env = JEnv.current(),
            let methodId = clazz.methodId(name: name, signature: signature)
        else { return }
        env.callNonvirtualVoidMethod(object: object, clazz: clazz, methodId: methodId, args: args)
    }
}
#endif