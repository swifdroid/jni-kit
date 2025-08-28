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
    /// The underlying JNI object reference.
    var ref: JObjectBox { get }
    
    /// The resolved class reference of the Java object.
    var clazz: JClass { get }

    /// The fully qualified class name of the object (e.g., `"java/lang/String"`).
    var className: JClassName { get }

    /// The wrapped Java object.
    var object: JObject { get }
}

extension JObjectable {
    /// The underlying JNI object reference.
    public var ref: JObjectBox { object.ref }
    
    /// The resolved class reference of the Java object.
    public var clazz: JClass { object.clazz }

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

extension JObjectable {
    // MARK: - Instance Methods
    
    /// Call an instance method on this object.
    public func callObjectMethod(_ env: JEnv? = nil, name: String, args: [(any JValuable, JSignatureItem)], returning: JSignatureItem) -> JObject? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.1 }), returning: returning))
        else { return nil }
        return env.callObjectMethod(object: object, methodId: methodId, args: args.map({ $0.0 }))
        #else
        return nil
        #endif
    }

    /// Call an instance method on this object.
    public func callObjectMethod(_ env: JEnv? = nil, name: String, args: [JSignatureItemable], returning: JSignatureItem = .void) -> JObject? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.signatureItemWithValue.signatureItem }), returning: returning))
        else { return nil }
        return env.callObjectMethod(object: object, methodId: methodId, args: args.map({ $0.signatureItemWithValue.value }))
        #else
        return nil
        #endif
    }

    /// Call an instance method on this object.
    public func callObjectMethod(_ env: JEnv? = nil, name: String, args: JSignatureItemable..., returning: JSignatureItem = .void) -> JObject? {
        callObjectMethod(env, name: name, args: args, returning: returning)
    }

    /// Call an instance method returning `jboolean`
    public func callBoolMethod(_ env: JEnv? = nil, name: String, args: [(any JValuable, JSignatureItem)]) -> Bool? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.1 }), returning: .boolean))
        else { return nil }
        return env.callBooleanMethod(object: object, methodId: methodId, args: args.map({ $0.0 }))
        #else
        return nil
        #endif
    }

    /// Call an instance method on this object.
    public func callBoolMethod(_ env: JEnv? = nil, name: String, args: [JSignatureItemable]) -> Bool? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.signatureItemWithValue.signatureItem }), returning: .boolean))
        else { return nil }
        return env.callBooleanMethod(object: object, methodId: methodId, args: args.map({ $0.signatureItemWithValue.value }))
        #else
        return nil
        #endif
    }

    /// Call an instance method on this object.
    public func callBoolMethod(_ env: JEnv? = nil, name: String, args: JSignatureItemable...) -> Bool? {
        callBoolMethod(env, name: name, args: args)
    }

    /// Call an instance method returning `jbyte`
    public func callByteMethod(_ env: JEnv? = nil, name: String, args: [(any JValuable, JSignatureItem)]) -> Int8? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.1 }), returning: .byte))
        else { return nil }
        return env.callByteMethod(object: object, methodId: methodId, args: args.map({ $0.0 }))
        #else
        return nil
        #endif
    }

    /// Call an instance method on this object.
    public func callByteMethod(_ env: JEnv? = nil, name: String, args: [JSignatureItemable]) -> Int8? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.signatureItemWithValue.signatureItem }), returning: .byte))
        else { return nil }
        return env.callByteMethod(object: object, methodId: methodId, args: args.map({ $0.signatureItemWithValue.value }))
        #else
        return nil
        #endif
    }

    /// Call an instance method on this object.
    public func callByteMethod(_ env: JEnv? = nil, name: String, args: JSignatureItemable...) -> Int8? {
        callByteMethod(env, name: name, args: args)
    }

    /// Call an instance method returning `jchar`
    public func callCharMethod(_ env: JEnv? = nil, name: String, args: [(any JValuable, JSignatureItem)]) -> UInt16? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.1 }), returning: .char))
        else { return nil }
        return env.callCharMethod(object: object, methodId: methodId, args: args.map({ $0.0 }))
        #else
        return nil
        #endif
    }

    /// Call an instance method on this object.
    public func callCharMethod(_ env: JEnv? = nil, name: String, args: [JSignatureItemable]) -> UInt16? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.signatureItemWithValue.signatureItem }), returning: .char))
        else { return nil }
        return env.callCharMethod(object: object, methodId: methodId, args: args.map({ $0.signatureItemWithValue.value }))
        #else
        return nil
        #endif
    }

    /// Call an instance method on this object.
    public func callCharMethod(_ env: JEnv? = nil, name: String, args: JSignatureItemable...) -> UInt16? {
        callCharMethod(env, name: name, args: args)
    }

    /// Call an instance method returning `jdouble`
    public func callDoubleMethod(_ env: JEnv? = nil, name: String, args: [(any JValuable, JSignatureItem)]) -> Double? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.1 }), returning: .double))
        else { return nil }
        return env.callDoubleMethod(object: object, methodId: methodId, args: args.map({ $0.0 }))
        #else
        return nil
        #endif
    }

    /// Call an instance method on this object.
    public func callDoubleMethod(_ env: JEnv? = nil, name: String, args: [JSignatureItemable]) -> Double? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.signatureItemWithValue.signatureItem }), returning: .double))
        else { return nil }
        return env.callDoubleMethod(object: object, methodId: methodId, args: args.map({ $0.signatureItemWithValue.value }))
        #else
        return nil
        #endif
    }

    /// Call an instance method on this object.
    public func callDoubleMethod(_ env: JEnv? = nil, name: String, args: JSignatureItemable...) -> Double? {
        callDoubleMethod(env, name: name, args: args)
    }

    /// Call an instance method returning `jfloat`
    public func callFloatMethod(_ env: JEnv? = nil, name: String, args: [(any JValuable, JSignatureItem)]) -> Float? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.1 }), returning: .float))
        else { return nil }
        return env.callFloatMethod(object: object, methodId: methodId, args: args.map({ $0.0 }))
        #else
        return nil
        #endif
    }

    /// Call an instance method on this object.
    public func callFloatMethod(_ env: JEnv? = nil, name: String, args: [JSignatureItemable]) -> Float? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.signatureItemWithValue.signatureItem }), returning: .float))
        else { return nil }
        return env.callFloatMethod(object: object, methodId: methodId, args: args.map({ $0.signatureItemWithValue.value }))
        #else
        return nil
        #endif
    }

    /// Call an instance method on this object.
    public func callFloatMethod(_ env: JEnv? = nil, name: String, args: JSignatureItemable...) -> Float? {
        callFloatMethod(env, name: name, args: args)
    }
    
    /// Call an instance method returning `jint`
    public func callIntMethod(_ env: JEnv? = nil, name: String, args: [(any JValuable, JSignatureItem)]) -> Int32? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.1 }), returning: .int))
        else { return nil }
        return env.callIntMethod(object: object, methodId: methodId, args: args.map({ $0.0 }))
        #else
        return nil
        #endif
    }

    /// Call an instance method on this object.
    public func callIntMethod(_ env: JEnv? = nil, name: String, args: [JSignatureItemable]) -> Int32? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.signatureItemWithValue.signatureItem }), returning: .int))
        else { return nil }
        return env.callIntMethod(object: object, methodId: methodId, args: args.map({ $0.signatureItemWithValue.value }))
        #else
        return nil
        #endif
    }

    /// Call an instance method on this object.
    public func callIntMethod(_ env: JEnv? = nil, name: String, args: JSignatureItemable...) -> Int32? {
        callIntMethod(env, name: name, args: args)
    }

    /// Call an instance method returning `long`
    public func callLongMethod(_ env: JEnv? = nil, name: String, args: [(any JValuable, JSignatureItem)]) -> Int64? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.1 }), returning: .long))
        else { return nil }
        return env.callLongMethod(object: object, methodId: methodId, args: args.map({ $0.0 }))
        #else
        return nil
        #endif
    }

    /// Call an instance method on this object.
    public func callLongMethod(_ env: JEnv? = nil, name: String, args: [JSignatureItemable]) -> Int64? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.signatureItemWithValue.signatureItem }), returning: .long))
        else { return nil }
        return env.callLongMethod(object: object, methodId: methodId, args: args.map({ $0.signatureItemWithValue.value }))
        #else
        return nil
        #endif
    }

    /// Call an instance method on this object.
    public func callLongMethod(_ env: JEnv? = nil, name: String, args: JSignatureItemable...) -> Int64? {
        callLongMethod(env, name: name, args: args)
    }

    /// Call an instance method returning `void`
    public func callVoidMethod(_ env: JEnv? = nil, name: String, args: [(any JValuable, JSignatureItem)]) {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.1 }), returning: .void))
        else { return }
        env.callVoidMethod(object: object, methodId: methodId, args: args.map({ $0.0 }))
        #else
        return
        #endif
    }

    /// Call an instance method on this object.
    public func callVoidMethod(_ env: JEnv? = nil, name: String, args: [JSignatureItemable]) {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.signatureItemWithValue.signatureItem }), returning: .void))
        else { return }
        return env.callVoidMethod(object: object, methodId: methodId, args: args.map({ $0.signatureItemWithValue.value }))
        #else
        return
        #endif
    }

    /// Call an instance method on this object.
    public func callVoidMethod(_ env: JEnv? = nil, name: String, args: JSignatureItemable...) {
        callVoidMethod(env, name: name, args: args)
    }

    // MARK: - Non-Virtual Instance Methods

    /// Call a non-virtual instance method on this object.
    public func callNonvirtualObjectMethod(_ env: JEnv? = nil, name: String, args: [(any JValuable, JSignatureItem)], returning: JSignatureItem) -> JObject? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.1 }), returning: returning))
        else { return nil }
        return env.callNonvirtualObjectMethod(object: object, clazz: clazz, methodId: methodId, args: args.map({ $0.0 }))
        #else
        return nil
        #endif
    }

    /// Call an instance method on this object.
    public func callNonvirtualObjectMethod(_ env: JEnv? = nil, name: String, args: [JSignatureItemable], returning: JSignatureItem = .void) -> JObject? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.signatureItemWithValue.signatureItem }), returning: returning))
        else { return nil }
        return env.callNonvirtualObjectMethod(object: object, clazz: clazz, methodId: methodId, args: args.map({ $0.signatureItemWithValue.value }))
        #else
        return nil
        #endif
    }

    /// Call an instance method on this object.
    public func callNonvirtualObjectMethod(_ env: JEnv? = nil, name: String, args: JSignatureItemable..., returning: JSignatureItem = .void) -> JObject? {
        callNonvirtualObjectMethod(env, name: name, args: args, returning: returning)
    }

    /// Call a non-virtual instance method returning `jboolean`
    public func callNonvirtualBoolMethod(_ env: JEnv? = nil, name: String, args: [(any JValuable, JSignatureItem)]) -> Bool? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.1 }), returning: .boolean))
        else { return nil }
        return env.callNonvirtualBooleanMethod(object: object, clazz: clazz, methodId: methodId, args: args.map({ $0.0 }))
        #else
        return nil
        #endif
    }

    /// Call an instance method on this object.
    public func callNonvirtualBoolMethod(_ env: JEnv? = nil, name: String, args: [JSignatureItemable]) -> Bool? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.signatureItemWithValue.signatureItem }), returning: .boolean))
        else { return nil }
        return env.callNonvirtualBooleanMethod(object: object, clazz: clazz, methodId: methodId, args: args.map({ $0.signatureItemWithValue.value }))
        #else
        return nil
        #endif
    }

    /// Call an instance method on this object.
    public func callNonvirtualBoolMethod(_ env: JEnv? = nil, name: String, args: JSignatureItemable...) -> Bool? {
        callNonvirtualBoolMethod(env, name: name, args: args)
    }

    /// Call a non-virtual instance method returning `jbyte`
    public func callNonvirtualByteMethod(_ env: JEnv? = nil, name: String, args: [(any JValuable, JSignatureItem)]) -> Int8? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.1 }), returning: .byte))
        else { return nil }
        return env.callNonvirtualByteMethod(object: object, clazz: clazz, methodId: methodId, args: args.map({ $0.0 }))
        #else
        return nil
        #endif
    }

    /// Call an instance method on this object.
    public func callNonvirtualByteMethod(_ env: JEnv? = nil, name: String, args: [JSignatureItemable]) -> Int8? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.signatureItemWithValue.signatureItem }), returning: .byte))
        else { return nil }
        return env.callNonvirtualByteMethod(object: object, clazz: clazz, methodId: methodId, args: args.map({ $0.signatureItemWithValue.value }))
        #else
        return nil
        #endif
    }

    /// Call an instance method on this object.
    public func callNonvirtualByteMethod(_ env: JEnv? = nil, name: String, args: JSignatureItemable...) -> Int8? {
        callNonvirtualByteMethod(env, name: name, args: args)
    }

    /// Call a non-virtual instance method returning `jchar`
    public func callNonvirtualCharMethod(_ env: JEnv? = nil, name: String, args: [(any JValuable, JSignatureItem)]) -> UInt16? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.1 }), returning: .char))
        else { return nil }
        return env.callNonvirtualCharMethod(object: object, clazz: clazz, methodId: methodId, args: args.map({ $0.0 }))
        #else
        return nil
        #endif
    }

    /// Call an instance method on this object.
    public func callNonvirtualCharMethod(_ env: JEnv? = nil, name: String, args: [JSignatureItemable]) -> UInt16? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.signatureItemWithValue.signatureItem }), returning: .char))
        else { return nil }
        return env.callNonvirtualCharMethod(object: object, clazz: clazz, methodId: methodId, args: args.map({ $0.signatureItemWithValue.value }))
        #else
        return nil
        #endif
    }

    /// Call an instance method on this object.
    public func callNonvirtualCharMethod(_ env: JEnv? = nil, name: String, args: JSignatureItemable...) -> UInt16? {
        callNonvirtualCharMethod(env, name: name, args: args)
    }

    /// Call a non-virtual instance method returning `jdouble`
    public func callNonvirtualDoubleMethod(_ env: JEnv? = nil, name: String, args: [(any JValuable, JSignatureItem)]) -> Double? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.1 }), returning: .double))
        else { return nil }
        return env.callNonvirtualDoubleMethod(object: object, clazz: clazz, methodId: methodId, args: args.map({ $0.0 }))
        #else
        return nil
        #endif
    }

    /// Call an instance method on this object.
    public func callNonvirtualDoubleMethod(_ env: JEnv? = nil, name: String, args: [JSignatureItemable]) -> Double? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.signatureItemWithValue.signatureItem }), returning: .double))
        else { return nil }
        return env.callNonvirtualDoubleMethod(object: object, clazz: clazz, methodId: methodId, args: args.map({ $0.signatureItemWithValue.value }))
        #else
        return nil
        #endif
    }

    /// Call an instance method on this object.
    public func callNonvirtualDoubleMethod(_ env: JEnv? = nil, name: String, args: JSignatureItemable...) -> Double? {
        callNonvirtualDoubleMethod(env, name: name, args: args)
    }

    /// Call a non-virtual instance method returning `jfloat`
    public func callNonvirtualFloatMethod(_ env: JEnv? = nil, name: String, args: [(any JValuable, JSignatureItem)]) -> Float? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.1 }), returning: .float))
        else { return nil }
        return env.callNonvirtualFloatMethod(object: object, clazz: clazz, methodId: methodId, args: args.map({ $0.0 }))
        #else
        return nil
        #endif
    }

    /// Call an instance method on this object.
    public func callNonvirtualFloatMethod(_ env: JEnv? = nil, name: String, args: [JSignatureItemable]) -> Float? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.signatureItemWithValue.signatureItem }), returning: .float))
        else { return nil }
        return env.callNonvirtualFloatMethod(object: object, clazz: clazz, methodId: methodId, args: args.map({ $0.signatureItemWithValue.value }))
        #else
        return nil
        #endif
    }

    /// Call an instance method on this object.
    public func callNonvirtualFloatMethod(_ env: JEnv? = nil, name: String, args: JSignatureItemable...) -> Float? {
        callNonvirtualFloatMethod(env, name: name, args: args)
    }
    
    /// Call a non-virtual instance method returning `jint`
    public func callNonvirtualIntMethod(_ env: JEnv? = nil, name: String, args: [(any JValuable, JSignatureItem)]) -> Int32? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.1 }), returning: .int))
        else { return nil }
        return env.callNonvirtualIntMethod(object: object, clazz: clazz, methodId: methodId, args: args.map({ $0.0 }))
        #else
        return nil
        #endif
    }

    /// Call an instance method on this object.
    public func callNonvirtualIntMethod(_ env: JEnv? = nil, name: String, args: [JSignatureItemable]) -> Int32? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.signatureItemWithValue.signatureItem }), returning: .int))
        else { return nil }
        return env.callNonvirtualIntMethod(object: object, clazz: clazz, methodId: methodId, args: args.map({ $0.signatureItemWithValue.value }))
        #else
        return nil
        #endif
    }

    /// Call an instance method on this object.
    public func callNonvirtualIntMethod(_ env: JEnv? = nil, name: String, args: JSignatureItemable...) -> Int32? {
        callNonvirtualIntMethod(env, name: name, args: args)
    }

    /// Call a non-virtual instance method returning `long`
    public func callNonvirtualLongMethod(_ env: JEnv? = nil, name: String, args: [(any JValuable, JSignatureItem)]) -> Int64? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.1 }), returning: .long))
        else { return nil }
        return env.callNonvirtualLongMethod(object: object, clazz: clazz, methodId: methodId, args: args.map({ $0.0 }))
        #else
        return nil
        #endif
    }

    /// Call an instance method on this object.
    public func callNonvirtualLongMethod(_ env: JEnv? = nil, name: String, args: [JSignatureItemable]) -> Int64? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.signatureItemWithValue.signatureItem }), returning: .long))
        else { return nil }
        return env.callNonvirtualLongMethod(object: object, clazz: clazz, methodId: methodId, args: args.map({ $0.signatureItemWithValue.value }))
        #else
        return nil
        #endif
    }

    /// Call an instance method on this object.
    public func callNonvirtualLongMethod(_ env: JEnv? = nil, name: String, args: JSignatureItemable...) -> Int64? {
        callNonvirtualLongMethod(env, name: name, args: args)
    }

    /// Call a non-virtual instance method returning `void`
    public func callNonvirtualVoidMethod(_ env: JEnv? = nil, name: String, args: [(any JValuable, JSignatureItem)]) {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.1 }), returning: .void))
        else { return }
        env.callNonvirtualVoidMethod(object: object, clazz: clazz, methodId: methodId, args: args.map({ $0.0 }))
        #else
        return
        #endif
    }

    /// Call an instance method on this object.
    public func callNonvirtualVoidMethod(_ env: JEnv? = nil, name: String, args: [JSignatureItemable]) {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.signatureItemWithValue.signatureItem }), returning: .void))
        else { return }
        return env.callNonvirtualVoidMethod(object: object, clazz: clazz, methodId: methodId, args: args.map({ $0.signatureItemWithValue.value }))
        #else
        return
        #endif
    }

    /// Call an instance method on this object.
    public func callNonvirtualVoidMethod(_ env: JEnv? = nil, name: String, args: JSignatureItemable...) {
        callNonvirtualVoidMethod(env, name: name, args: args)
    }
}