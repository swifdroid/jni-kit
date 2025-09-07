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
public protocol JObjectable: JEquatable, JHashable, JNotifiable, JStringable, JWaitable {
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

    /// Get the class loader that loaded this object's class.
    public func getClassLoader(_ env: JEnv? = nil) -> JClassLoader? {
        #if os(Android)
        guard
            let returningClazz = JClass.load("java/lang/Class"),
            let returningLoaderClazz = JClass.load(JClassLoader.className),
            let classObject = object.callObjectMethod(name: "getClass", returningClass: returningClazz),
            let loaderObject = classObject.callObjectMethod(name: "getClassLoader", returningClass: returningLoaderClazz)
        else { return nil }
        return JClassLoader(loaderObject)
        #else
        return nil
        #endif
    }
    
    /// Call an instance method on this object.
    ///
    /// - Parameters:
    ///  - env: The JNI environment to use. If `nil`, the current environment will be used.
    /// ```swift
    ///     env: JEnv.current()!
    /// ```
    ///  - name: The name of the method to call.
    /// ```swift
    ///     name: "getSomeObject"
    /// ```
    ///  - args: An array of tuples containing the argument value and its corresponding JNI signature item.
    /// ```swift
    ///     args: [("string".wrap()!.object, .object("java/lang/String")), (0, .int)]
    /// ```
    ///  - returningClass: The expected class of the return value.
    /// ```swift
    ///     returningClass: JClass.load("java/lang/String")!
    /// ```
    ///  - returningSignatureClass: An optional JNI class name for the return type, if it differs from the `returningClass` name.
    /// ```swift
    ///     returningSignatureClass: "com/some/OtherObject"
    /// ```
    ///  - Returns: The `JObject` result of the method call with applied returning class.
    public func callObjectMethod(_ env: JEnv? = nil, name: String, args: [(any JValuable, JSignatureItem)], returningClass: JClass, returningSignatureClass: JClassName? = nil) -> JObject? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.1 }), returning: .object(returningSignatureClass ?? returningClass.name)))
        else { return nil }
        return env.callObjectMethod(object: object, methodId: methodId, args: args.map({ $0.0 }), returningClass: returningClass)
        #else
        return nil
        #endif
    }

    /// Call an instance method on this object.
    ///
    /// - Parameters:
    ///  - env: The JNI environment to use. If `nil`, the current environment will be used.
    /// ```swift
    ///     env: JEnv.current()!
    /// ```
    ///  - name: The name of the method to call.
    /// ```swift
    ///     name: "getSomeObject"
    /// ```
    ///  - args: An array of objects conforming to `JSignatureItemable` or `.signed()`, representing the method arguments.
    /// ```swift
    ///     args: ["hi".wrap()!.signedAsString(), someObject.signed(as: "com/some/Object"), 0]
    /// ```
    ///  - returningClass: The expected class of the return value.
    /// ```swift
    ///     returningClass: JClass.load("java/lang/String")!
    /// ```
    ///  - returningSignatureClass: An optional JNI class name for the return type, if it differs from the `returningClass` name.
    /// ```swift
    ///     returningSignatureClass: "com/some/OtherObject"
    /// ```
    ///  - Returns: The `JObject` result of the method call with applied returning class.
    public func callObjectMethod(_ env: JEnv? = nil, name: String, args: [JSignatureItemable], returningClass: JClass, returningSignatureClass: JClassName? = nil) -> JObject? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.signatureItemWithValue.signatureItem }), returning: .object(returningSignatureClass ?? returningClass.name)))
        else { return nil }
        return env.callObjectMethod(object: object, methodId: methodId, args: args.map({ $0.signatureItemWithValue.value }), returningClass: returningClass)
        #else
        return nil
        #endif
    }

    /// Call an instance method on this object.
    ///
    /// - Parameters:
    ///  - env: The JNI environment to use. If `nil`, the current environment will be used.
    /// ```swift
    ///     env: JEnv.current()!
    /// ```
    ///  - name: The name of the method to call.
    /// ```swift
    ///     name: "getSomeObject"
    /// ```
    ///  - args: An array of objects conforming to `JSignatureItemable` or `.signed()`, representing the method arguments.
    /// ```swift
    ///     args: "hi".wrap()!.signedAsString(), someObject.signed(as: "com/some/Object"), 0
    /// ```
    ///  - returningClass: The expected class of the return value.
    /// ```swift
    ///     returningClass: JClass.load("java/lang/String")!
    /// ```
    ///  - returningSignatureClass: An optional JNI class name for the return type, if it differs from the `returningClass` name.
    /// ```swift
    ///     returningSignatureClass: "com/some/OtherObject"
    /// ```
    ///  - Returns: The `JObject` result of the method call with applied returning class.
    public func callObjectMethod(_ env: JEnv? = nil, name: String, args: JSignatureItemable..., returningClass: JClass, returningSignatureClass: JClassName? = nil) -> JObject? {
        callObjectMethod(env, name: name, args: args, returningClass: returningClass, returningSignatureClass: returningSignatureClass)
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

    /// Call an instance method returning `jbyte`
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

    /// Call an instance method returning `jbyte`
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

    /// Call an instance method returning `jchar`
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

    /// Call an instance method returning `jchar`
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

    /// Call an instance method returning `jdouble`
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

    /// Call an instance method returning `jdouble`
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

    /// Call an instance method returning `jfloat`
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

    /// Call an instance method returning `jfloat`
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

    /// Call an instance method returning `jint`
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

    /// Call an instance method returning `jint`
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

    /// Call an instance method returning `long`
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

    /// Call an instance method returning `long`
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
        #endif
    }

    /// Call an instance method returning `void`
    public func callVoidMethod(_ env: JEnv? = nil, name: String, args: [JSignatureItemable]) {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.signatureItemWithValue.signatureItem }), returning: .void))
        else { return }
        env.callVoidMethod(object: object, methodId: methodId, args: args.map({ $0.signatureItemWithValue.value }))
        #endif
    }

    /// Call an instance method returning `void`
    public func callVoidMethod(_ env: JEnv? = nil, name: String, args: JSignatureItemable...) {
        callVoidMethod(env, name: name, args: args)
    }

    // MARK: - Non-Virtual Instance Methods

    /// Call a non-virtual instance method on this object.
    ///
    /// - Parameters:
    ///  - env: The JNI environment to use. If `nil`, the current environment will be used.
    /// ```swift
    ///     env: JEnv.current()!
    /// ```
    ///  - name: The name of the method to call.
    /// ```swift
    ///     name: "getSomeObject"
    /// ```
    ///  - args: An array of tuples containing the argument value and its corresponding JNI signature item.
    /// ```swift
    ///     args: [("string".wrap()!.object, .object("java/lang/String")), (0, .int)]
    /// ```
    ///  - returningClass: The expected class of the return value.
    /// ```swift
    ///     returningClass: JClass.load("java/lang/String")!
    /// ```
    ///  - returningSignatureClass: An optional JNI class name for the return type, if it differs from the `returningClass` name.
    /// ```swift
    ///     returningSignatureClass: "com/some/OtherObject"
    /// ```
    ///  - Returns: The `JObject` result of the method call with applied returning class.
    public func callNonvirtualObjectMethod(_ env: JEnv? = nil, name: String, args: [(any JValuable, JSignatureItem)], returningClass: JClass, returningSignatureClass: JClassName? = nil) -> JObject? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.1 }), returning: .object(returningSignatureClass ?? returningClass.name)))
        else { return nil }
        return env.callNonvirtualObjectMethod(object: object, clazz: clazz, methodId: methodId, args: args.map({ $0.0 }), returningClass: returningClass)
        #else
        return nil
        #endif
    }

    /// Call a non-virtual instance method on this object.
    ///
    /// - Parameters:
    ///  - env: The JNI environment to use. If `nil`, the current environment will be used.
    /// ```swift
    ///     env: JEnv.current()!
    /// ```
    ///  - name: The name of the method to call.
    /// ```swift
    ///     name: "getSomeObject"
    /// ```
    ///  - args: An array of objects conforming to `JSignatureItemable` or `.signed()`, representing the method arguments.
    /// ```swift
    ///     args: ["hi".wrap()!.signedAsString(), someObject.signed(as: "com/some/Object"), 0]
    /// ```
    ///  - returningClass: The expected class of the return value.
    /// ```swift
    ///     returningClass: JClass.load("java/lang/String")!
    /// ```
    ///  - returningSignatureClass: An optional JNI class name for the return type, if it differs from the `returningClass` name.
    /// ```swift
    ///     returningSignatureClass: "com/some/OtherObject"
    /// ```
    ///  - Returns: The `JObject` result of the method call with applied returning class.
    public func callNonvirtualObjectMethod(_ env: JEnv? = nil, name: String, args: [JSignatureItemable], returningClass: JClass, returningSignatureClass: JClassName? = nil) -> JObject? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let methodId = clazz.methodId(env: env, name: name, signature: .init(args.map({ $0.signatureItemWithValue.signatureItem }), returning: .object(returningSignatureClass ?? returningClass.name)))
        else { return nil }
        return env.callNonvirtualObjectMethod(object: object, clazz: clazz, methodId: methodId, args: args.map({ $0.signatureItemWithValue.value }), returningClass: returningClass)
        #else
        return nil
        #endif
    }

    /// Call a non-virtual instance method on this object.
    ///
    /// - Parameters:
    ///  - env: The JNI environment to use. If `nil`, the current environment will be used.
    /// ```swift
    ///     env: JEnv.current()!
    /// ```
    ///  - name: The name of the method to call.
    /// ```swift
    ///     name: "getSomeObject"
    /// ```
    ///  - args: An array of objects conforming to `JSignatureItemable` or `.signed()`, representing the method arguments.
    /// ```swift
    ///     args: "hi".wrap()!.signedAsString(), someObject.signed(as: "com/some/Object"), 0
    /// ```
    ///  - returningClass: The expected class of the return value.
    /// ```swift
    ///     returningClass: JClass.load("java/lang/String")!
    /// ```
    ///  - returningSignatureClass: An optional JNI class name for the return type, if it differs from the `returningClass` name.
    /// ```swift
    ///     returningSignatureClass: "com/some/OtherObject"
    /// ```
    ///  - Returns: The `JObject` result of the method call with applied returning class.
    public func callNonvirtualObjectMethod(_ env: JEnv? = nil, name: String, args: JSignatureItemable..., returningClass: JClass, returningSignatureClass: JClassName? = nil) -> JObject? {
        callNonvirtualObjectMethod(env, name: name, args: args, returningClass: returningClass, returningSignatureClass: returningSignatureClass)
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

    // MARK: - Fields

    /// Get an `object` field from a Java instance.
    public func objectField(_ env: JEnv? = nil, name: String, returningClass: JClass) -> JObject? {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let fieldId = clazz.fieldId(name: name, signature: .object(returningClass.name))
        else { return nil }
        return env.getObjectField(object, fieldId, returningClass: returningClass)
        #else
        return nil
        #endif
    }

    /// Get a `boolean` field from a Java instance.
    public func booleanField(_ env: JEnv? = nil, name: String) -> Bool! {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let fieldId = clazz.fieldId(name: name, signature: .boolean)
        else { return nil }
        return env.getBooleanField(object, fieldId)
        #else
        return false
        #endif
    }

    /// Get a `byte` field from a Java instance.
    public func byteField(_ env: JEnv? = nil, name: String) -> Int8! {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let fieldId = clazz.fieldId(name: name, signature: .byte)
        else { return nil }
        return env.getByteField(object, fieldId)
        #else
        return 0
        #endif
    }

    /// Get a `char` field from a Java instance.
    public func charField(_ env: JEnv? = nil, name: String) -> UInt16! {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let fieldId = clazz.fieldId(name: name, signature: .char)
        else { return nil }
        return env.getCharField(object, fieldId)
        #else
        return 0
        #endif
    }

    /// Get a `short` field from a Java instance.
    public func shortField(_ env: JEnv? = nil, name: String) -> Int16! {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let fieldId = clazz.fieldId(name: name, signature: .short)
        else { return nil }
        return env.getShortField(object, fieldId)
        #else
        return 0
        #endif
    }

    /// Get a `int` field from a Java instance.
    public func intField(_ env: JEnv? = nil, name: String) -> Int32! {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let fieldId = clazz.fieldId(name: name, signature: .int)
        else { return nil }
        return env.getIntField(object, fieldId)
        #else
        return 0
        #endif
    }

    /// Get a `long` field from a Java instance.
    public func longField(_ env: JEnv? = nil, name: String) -> Int64! {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let fieldId = clazz.fieldId(name: name, signature: .long)
        else { return nil }
        return env.getLongField(object, fieldId)
        #else
        return 0
        #endif
    }

    /// Get a `float` field from a Java instance.
    public func floatField(_ env: JEnv? = nil, name: String) -> Float! {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let fieldId = clazz.fieldId(name: name, signature: .float)
        else { return nil }
        return env.getFloatField(object, fieldId)
        #else
        return 0
        #endif
    }

    /// Get a `double` field from a Java instance.
    public func doubleField(_ env: JEnv? = nil, name: String) -> Double! {
        #if os(Android)
        guard
            let env = env ?? JEnv.current(),
            let fieldId = clazz.fieldId(name: name, signature: .double)
        else { return nil }
        return env.getDoubleField(object, fieldId)
        #else
        return 0
        #endif
    }
}